//
//  MarkdownGenerator.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

class MarkdownGenerator {
    func generate(from extraction: ThothExtraction) -> String {
        var md = ""
        
        // Title
        md += "# \(extraction.article.title)\n\n"
        
        // Metadata
        md += "> **Extracted:** \(formatDate(extraction.metadata.extractedAt))\n"
        md += "> **Source:** \(extraction.metadata.sourceURL)\n"
        md += "> **Type:** \(extraction.article.type.rawValue)\n"
        md += "> **Word Count:** \(extraction.article.wordCount) words"
        if extraction.article.wordCount != extraction.article.originalWordCount {
            md += " (original: \(extraction.article.originalWordCount))"
        }
        md += "\n"
        if extraction.metadata.aiEnhanced {
            md += "> **AI Enhanced:** Yes\n"
        }
        md += "\n---\n\n"
        
        // Summary
        if !extraction.article.summary.isEmpty {
            md += "## Summary\n\n"
            md += extraction.article.summary + "\n\n"
        }
        
        // Infobox (ENHANCED - Full content)
        if let infobox = extraction.structuredContent.infobox {
            md += "## Infobox"
            if let type = infobox.type {
                md += " (\(type))"
            }
            md += "\n\n"
            
            for field in infobox.fields {
                md += "**\(field.key):** \(field.value)\n\n"
            }
            
            md += "\n"
        }
        
        // Alternate Names
        if !extraction.article.alternateNames.isEmpty {
            md += "## Alternate Names\n\n"
            md += extraction.article.alternateNames.map { "- \($0)" }.joined(separator: "\n")
            md += "\n\n"
        }
        
        // Key Facts
        if !extraction.classification.keyFacts.isEmpty {
            md += "## Key Facts\n\n"
            for fact in extraction.classification.keyFacts {
                md += "- **\(fact.key):** \(fact.value)\n"
            }
            md += "\n"
        }
        
        // Time Period
        if let period = extraction.temporalContext.timePeriod {
            md += "## Time Period\n\n"
            md += "**\(period.name)**"
            if let start = period.startYear, let end = period.endYear {
                md += " (\(formatYear(start))–\(formatYear(end)))"
            }
            md += "\n\n"
            if let desc = period.description {
                md += desc + "\n\n"
            }
        }
        
        // Important Dates
        if !extraction.temporalContext.dates.isEmpty {
            md += "## Important Dates\n\n"
            for date in extraction.temporalContext.dates {
                md += "- **\(date.date):** \(date.event)\n"
            }
            md += "\n"
        }
        
        // Sections (ENHANCED - Full content)
        if !extraction.structuredContent.sections.isEmpty {
            md += "## Article Sections\n\n"
            
            for section in extraction.structuredContent.sections {
                // Section heading (use markdown level based on section level)
                let headingPrefix = String(repeating: "#", count: min(section.level + 1, 6))
                md += "\(headingPrefix) \(section.title)\n\n"
                
                // Section content
                if !section.content.isEmpty {
                    md += section.content + "\n\n"
                }
            }
        }
        
        // Tables
        if !extraction.structuredContent.tables.isEmpty {
            md += "## Tables\n\n"
            for table in extraction.structuredContent.tables {
                md += "### \(table.title)\n\n"
                if let desc = table.description {
                    md += "*\(desc)*\n\n"
                }
                md += generateMarkdownTable(table)
                if table.truncated {
                    md += "\n*Table truncated: showing \(table.rows.count) of \(table.rowCount) rows*\n"
                }
                md += "\n"
            }
        }
        
        // Lists
        if !extraction.structuredContent.lists.isEmpty {
            md += "## Lists\n\n"
            for list in extraction.structuredContent.lists {
                if let title = list.title {
                    md += "### \(title)\n\n"
                }
                
                for (index, item) in list.items.enumerated() {
                    if list.ordered {
                        md += "\(index + 1). \(item)\n"
                    } else {
                        md += "- \(item)\n"
                    }
                }
                md += "\n"
            }
        }
        
        // Categories
        if !extraction.classification.categories.isEmpty {
            md += "## Categories\n\n"
            md += extraction.classification.categories.map { "- \($0)" }.joined(separator: "\n")
            md += "\n\n"
        }
        
        // Related Topics
        if !extraction.classification.relatedTopics.isEmpty {
            md += "## Related Topics\n\n"
            md += extraction.classification.relatedTopics.map { "- \($0)" }.joined(separator: "\n")
            md += "\n\n"
        }
        
        // See Also
        if !extraction.references.seeAlso.isEmpty {
            md += "## See Also\n\n"
            for link in extraction.references.seeAlso {
                if let url = link.url {
                    md += "- [\(link.title)](\(url))\n"
                } else {
                    md += "- \(link.title)\n"
                }
            }
            md += "\n"
        }
        
        // Footer
        md += "---\n\n"
        md += "*Generated by Thoth v\(extraction.metadata.thothVersion) • [theway.ink](https://theway.ink)*\n"
        
        return md
    }
    
    private func generateMarkdownTable(_ table: Table) -> String {
        guard !table.rows.isEmpty else { return "" }
        
        var md = ""
        
        // Determine column count
        let columnCount = table.headers.isEmpty
            ? (table.rows.first?.count ?? 0)
            : table.headers.count
        
        guard columnCount > 0 else { return "" }
        
        // Headers
        if !table.headers.isEmpty {
            md += "| " + table.headers.map { escapeMarkdown($0) }.joined(separator: " | ") + " |\n"
        } else {
            md += "| " + (1...columnCount).map { "Column \($0)" }.joined(separator: " | ") + " |\n"
        }
        
        // Separator
        md += "| " + Array(repeating: "---", count: columnCount).joined(separator: " | ") + " |\n"
        
        // Rows
        for row in table.rows {
            let cells = row.prefix(columnCount).map { escapeMarkdown($0) }
            // Pad if needed
            let paddedCells = cells + Array(repeating: "", count: max(0, columnCount - cells.count))
            md += "| " + paddedCells.joined(separator: " | ") + " |\n"
        }
        
        return md
    }
    
    private func escapeMarkdown(_ text: String) -> String {
        text.replacingOccurrences(of: "|", with: "\\|")
            .replacingOccurrences(of: "\n", with: " ")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatYear(_ year: Int) -> String {
        if year < 0 {
            return "\(abs(year)) BCE"
        } else {
            return "\(year) CE"
        }
    }
}
