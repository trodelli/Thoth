//
//  WikipediaParser.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation
import SwiftSoup

class WikipediaParser {
    private let logger = Logger.shared
    
    func parse(_ article: WikipediaArticle) throws -> ParsedWikipediaContent {
        let document = try SwiftSoup.parse(article.html)
        
        // Sanitize HTML first
        try sanitizeHTML(document)
        
        // Extract components
        let infobox = try parseInfobox(document)
        let tables = try parseTables(document)
        let sections = try parseSections(document)
        let seeAlso = try parseSeeAlso(document)
        let firstParagraph = try extractFirstParagraph(document)
        let alternateNames = extractAlternateNames(infobox: infobox, firstParagraph: firstParagraph)
        
        logger.info("Parsed: \(tables.count) tables, \(sections.count) sections")
        
        return ParsedWikipediaContent(
            title: article.title,
            displayTitle: article.displayTitle,
            pageID: article.pageID,
            categories: article.categories,
            infobox: infobox,
            tables: tables,
            sections: sections,
            seeAlso: seeAlso,
            alternateNames: alternateNames,
            firstParagraph: firstParagraph,
            wordCount: article.wordCount
        )
    }
    
    // MARK: - Sanitization
    
    private func sanitizeHTML(_ document: Document) throws {
        let selectorsToRemove = [
            "script", "style", "noscript",
            ".mw-editsection", ".reference", "sup.reference",
            ".noprint", ".mw-empty-elt", "#coordinates",
            ".sistersitebox", ".navbox", ".vertical-navbox",
            ".authority-control", ".mbox-small", ".ambox",
            ".tmbox", ".ombox", ".hatnote"
        ]
        
        for selector in selectorsToRemove {
            try document.select(selector).remove()
        }
    }
    
    // MARK: - Infobox
    
    private func parseInfobox(_ document: Document) throws -> Infobox? {
        guard let infoboxElement = try document.select("table.infobox").first() else {
            return nil
        }
        
        let classes = try infoboxElement.classNames()
        let type = classes.filter { $0 != "infobox" && $0 != "vcard" }.first
        
        var fields: [InfoboxField] = []
        let rows = try infoboxElement.select("tr")
        
        for row in rows {
            guard let th = try row.select("th").first(),
                  let td = try row.select("td").first() else {
                continue
            }
            
            let key = try th.text().trimmingCharacters(in: .whitespacesAndNewlines)
            let value = try td.text().trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !key.isEmpty && !value.isEmpty {
                fields.append(InfoboxField(key: key, value: value))
            }
        }
        
        guard !fields.isEmpty else { return nil }
        
        return Infobox(type: type.map { "Infobox \($0)" }, fields: fields)
    }
    
    // MARK: - Tables (IMPROVED)
    
    private func parseTables(_ document: Document) throws -> [Table] {
        // Try multiple selectors to catch all table types
        var allTables: [Element] = []
        
        // Primary: wikitable class (most common)
        allTables.append(contentsOf: try document.select("table.wikitable").array())
        
        // Secondary: Any table that's not an infobox
        let otherTables = try document.select("table").array().filter { table in
            let classes = (try? table.classNames()) ?? []
            return !classes.contains("infobox") &&
                   !classes.contains("navbox") &&
                   !classes.contains("vertical-navbox") &&
                   !classes.contains("sidebar") &&
                   !allTables.contains(table)
        }
        allTables.append(contentsOf: otherTables)
        
        logger.info("Found \(allTables.count) potential tables")
        
        var tables: [Table] = []
        
        for (index, tableElement) in allTables.enumerated() {
            let tableId = "table_\(index + 1)"
            
            // Get caption or title
            let caption = try? tableElement.select("caption").first()?.text()
            let title = caption ?? "Table \(index + 1)"
            
            // Extract headers - try multiple methods
            var headers: [String] = []
            
            // Method 1: Look for thead > tr > th
            if let thead = try tableElement.select("thead").first() {
                headers = try thead.select("th").map {
                    try $0.text().trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            // Method 2: First row with th elements
            if headers.isEmpty, let firstRow = try tableElement.select("tr").first() {
                headers = try firstRow.select("th").map {
                    try $0.text().trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            // Extract rows
            let allRows = try tableElement.select("tr").array()
            
            // Skip header row if we found headers
            let startIndex = headers.isEmpty ? 0 : 1
            let dataRows = Array(allRows.dropFirst(startIndex))
            
            var rows: [[String]] = []
            for row in dataRows {
                let cells = try row.select("td, th").map {
                    try $0.text().trimmingCharacters(in: .whitespacesAndNewlines)
                }
                // Only add rows that have content
                if !cells.isEmpty && !cells.allSatisfy({ $0.isEmpty }) {
                    rows.append(cells)
                }
            }
            
            // Only add table if it has actual data
            guard !rows.isEmpty else { continue }
            
            // Truncate if necessary
            let truncated = rows.count > AppConstants.Defaults.maxTableRows
            let finalRows = truncated ? Array(rows.prefix(AppConstants.Defaults.maxTableRows)) : rows
            
            tables.append(Table(
                id: tableId,
                title: title,
                headers: headers,
                rows: finalRows,
                rowCount: rows.count,
                truncated: truncated
            ))
            
            logger.info("  Table \(index + 1): '\(title)' - \(headers.count) headers, \(rows.count) rows")
        }
        
        return tables
    }
    
    // MARK: - Sections (SIMPLIFIED & ROBUST)

    private func parseSections(_ document: Document) throws -> [Section] {
        var sections: [Section] = []
        
        // Get all paragraphs from the content
        guard let contentDiv = try document.select("div.mw-parser-output").first() else {
            logger.warning("No content div found")
            return []
        }
        
        // Collect all paragraphs with their text
        let allParagraphs = try contentDiv.select("p").array()
        let allParagraphTexts = allParagraphs.compactMap { p -> String? in
            let text = try? p.text().trimmingCharacters(in: .whitespacesAndNewlines)
            return (text?.isEmpty == false && (text?.count ?? 0) > 30) ? text : nil
        }
        
        logger.info("Found \(allParagraphTexts.count) substantive paragraphs")
        
        // Find all headings
        let headings = try document.select("h2, h3").array()
        let skipSections = Set(["See also", "References", "External links", "Notes",
                                "Further reading", "Bibliography", "Sources", "Footnotes",
                                "Contents", "Navigation menu"])
        
        logger.info("Found \(headings.count) headings")
        
        // Create sections by grouping paragraphs
        // Strategy: collect paragraphs into chunks, use headings as boundaries
        
        if headings.isEmpty {
            // No headings - create one section with all content
            if !allParagraphTexts.isEmpty {
                let content = allParagraphTexts.joined(separator: "\n\n")
                sections.append(Section(
                    id: "section_0",
                    title: "Content",
                    level: 2,
                    content: content,
                    wordCount: content.split(separator: " ").count
                ))
                logger.info("  Created single section with all content (\(allParagraphTexts.count) paragraphs)")
            }
        } else {
            // Divide paragraphs among sections
            // Simple approach: equal distribution
            let paragraphsPerSection = max(1, allParagraphTexts.count / headings.count)
            var paragraphIndex = 0
            
            for (_, heading) in headings.enumerated() {
                let title = try heading.text().trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip unwanted sections
                if skipSections.contains(title) {
                    logger.info("  Skipping section: '\(title)'")
                    continue
                }
                
                let level = Int(String(heading.tagName().last!)) ?? 2
                
                // Take next batch of paragraphs
                let endIndex = min(paragraphIndex + paragraphsPerSection, allParagraphTexts.count)
                let sectionParagraphs = Array(allParagraphTexts[paragraphIndex..<endIndex])
                paragraphIndex = endIndex
                
                if !sectionParagraphs.isEmpty {
                    let content = sectionParagraphs.joined(separator: "\n\n")
                    sections.append(Section(
                        id: "section_\(sections.count)",
                        title: title,
                        level: level,
                        content: content,
                        wordCount: content.split(separator: " ").count
                    ))
                    logger.info("  Section added: '\(title)' (\(sectionParagraphs.count) paragraphs, \(content.split(separator: " ").count) words)")
                }
            }
            
            // Add any remaining paragraphs to last section
            if paragraphIndex < allParagraphTexts.count, !sections.isEmpty {
                let remaining = Array(allParagraphTexts[paragraphIndex...])
                if !remaining.isEmpty {
                    let lastSection = sections[sections.count - 1]
                    let additionalContent = remaining.joined(separator: "\n\n")
                    sections[sections.count - 1] = Section(
                        id: lastSection.id,
                        title: lastSection.title,
                        level: lastSection.level,
                        content: lastSection.content + "\n\n" + additionalContent,
                        wordCount: (lastSection.content + "\n\n" + additionalContent).split(separator: " ").count
                    )
                }
            }
        }
        
        logger.info("Total sections extracted: \(sections.count)")
        return sections
    }
    
    // MARK: - See Also (FINAL FIX)

    private func parseSeeAlso(_ document: Document) throws -> [SeeAlsoLink] {
        var links: [SeeAlsoLink] = []
        
        // Find "See also" heading
        let headings = try document.select("h2, h3").array()
        var seeAlsoHeading: Element? = nil
        
        for heading in headings {
            let text = try heading.text().trimmingCharacters(in: .whitespacesAndNewlines)
            if text.lowercased() == "see also" {
                seeAlsoHeading = heading
                break
            }
        }
        
        guard let heading = seeAlsoHeading else {
            logger.info("No 'See also' section found")
            return []
        }
        
        // Find the next ul element after this heading
        var sibling = try heading.nextElementSibling()
        while let element = sibling {
            let tagName = element.tagName()
            
            // Stop at next heading
            if ["h2", "h3"].contains(tagName) {
                break
            }
            
            // Process ul lists
            if tagName == "ul" {
                let anchors = try element.select("li a[href^='/wiki/']")
                for anchor in anchors {
                    let title = try anchor.text()
                    let href = try anchor.attr("href")
                    
                    // Skip meta pages (those with colons)
                    if !href.contains(":") {
                        let url = URL(string: "https://en.wikipedia.org\(href)")
                        links.append(SeeAlsoLink(title: title, url: url))
                    }
                }
                break // Only process first ul
            }
            
            sibling = try element.nextElementSibling()
        }
        
        logger.info("Found \(links.count) 'See also' links")
        return links
    }
   
    // MARK: - First Paragraph
    
    private func extractFirstParagraph(_ document: Document) throws -> String {
        guard let contentDiv = try document.select("div.mw-parser-output").first() else {
            return ""
        }
        
        for element in contentDiv.children() {
            if element.tagName() == "p" {
                let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty && text.count > 50 { // Skip short intro paragraphs
                    return text
                }
            }
        }
        
        return ""
    }
    
    // MARK: - Alternate Names
    
    private func extractAlternateNames(infobox: Infobox?, firstParagraph: String) -> [String] {
        var names: [String] = []
        
        // From infobox
        if let infobox = infobox {
            let nameFields = ["Native name", "Other names", "Also known as",
                              "Chinese", "Japanese", "Korean", "Sanskrit", "Born", "Birth name"]
            for field in infobox.fields {
                if nameFields.contains(where: { field.key.contains($0) }) {
                    let values = field.value.components(separatedBy: CharacterSet(charactersIn: ",;"))
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty && $0.count < 100 } // Avoid long descriptions
                    names.append(contentsOf: values)
                }
            }
        }
        
        return Array(Set(names)) // Remove duplicates
    }
}
