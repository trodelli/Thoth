//
//  ExportService.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

protocol ExportServiceProtocol {
    func exportMarkdown(_ extraction: ThothExtraction, to url: URL) throws
    func exportJSON(_ extraction: ThothExtraction, to url: URL) throws
    func exportBatch(_ extractions: [ThothExtraction], to directory: URL, format: ExportFormat) throws -> [URL]
}

enum ExportFormat: String, CaseIterable {
    case markdown = "Markdown"
    case json = "JSON"
    case both = "Both"
    
    var fileExtension: String {
        switch self {
        case .markdown: return "md"
        case .json: return "json"
        case .both: return "both"
        }
    }
    
    var defaultFilename: String {
        switch self {
        case .markdown: return "Thoth_Session_Export.md"
        case .json: return "Thoth_Session_Export.json"
        case .both: return "Thoth_Session_Export"
        }
    }
}

class ExportService: ExportServiceProtocol {
    private let markdownGenerator = MarkdownGenerator()
    private let logger = Logger.shared
    
    func exportMarkdown(_ extraction: ThothExtraction, to url: URL) throws {
        let markdown = markdownGenerator.generate(from: extraction)
        try markdown.write(to: url, atomically: true, encoding: .utf8)
        logger.success("Exported: \(url.lastPathComponent)")
    }
    
    func exportJSON(_ extraction: ThothExtraction, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(extraction)
        try data.write(to: url)
        logger.success("Exported: \(url.lastPathComponent)")
    }
    
    func exportBatch(_ extractions: [ThothExtraction], to directory: URL, format: ExportFormat) throws -> [URL] {
        // Ensure directory exists
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        var exportedURLs: [URL] = []
        
        for extraction in extractions {
            let baseName = sanitizeFilename(extraction.article.title)
            
            switch format {
            case .markdown:
                let url = directory.appendingPathComponent("\(baseName).md")
                try exportMarkdown(extraction, to: url)
                exportedURLs.append(url)
                
            case .json:
                let url = directory.appendingPathComponent("\(baseName).json")
                try exportJSON(extraction, to: url)
                exportedURLs.append(url)
                
            case .both:
                let mdURL = directory.appendingPathComponent("\(baseName).md")
                let jsonURL = directory.appendingPathComponent("\(baseName).json")
                try exportMarkdown(extraction, to: mdURL)
                try exportJSON(extraction, to: jsonURL)
                exportedURLs.append(contentsOf: [mdURL, jsonURL])
            }
        }
        
        logger.success("Batch export complete: \(exportedURLs.count) files")
        return exportedURLs
    }
    


    // MARK: - Session Export (Single File)

    /// Export all extractions to a single combined file
    func sessionExport(
        extractions: [ThothExtraction],
        to fileURL: URL,
        format: ExportFormat
    ) throws {
        switch format {
        case .markdown:
            try sessionExportMarkdown(extractions: extractions, to: fileURL)
        case .json:
            try sessionExportJSON(extractions: extractions, to: fileURL)
        case .both:
            // For session export, create both files with appropriate extensions
            let mdURL = fileURL.deletingPathExtension().appendingPathExtension("md")
            let jsonURL = fileURL.deletingPathExtension().appendingPathExtension("json")
            try sessionExportMarkdown(extractions: extractions, to: mdURL)
            try sessionExportJSON(extractions: extractions, to: jsonURL)
        }
        
        logger.success("Session export complete: \(fileURL.lastPathComponent)")
    }

    private func sessionExportMarkdown(extractions: [ThothExtraction], to fileURL: URL) throws {
        var combinedMarkdown = """
        # Thoth Session Export
        
        **Exported:** \(dateFormatter.string(from: Date()))
        **Total Extractions:** \(extractions.count)
        **Format:** Markdown
        
        
        """
        
        for (index, extraction) in extractions.enumerated() {
            // Add separator between articles (triple line for visual clarity)
            if index > 0 {
                combinedMarkdown += "\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
            }
            
            // Add article title (no "Article N:" prefix)
            combinedMarkdown += "# \(extraction.article.title)\n\n"
            
            // Generate full markdown for this extraction
            let articleMarkdown = markdownGenerator.generate(from: extraction)
            
            // Remove the first line (title) since we already added it
            let lines = articleMarkdown.components(separatedBy: .newlines)
            let contentLines = lines.dropFirst() // Remove "# Title" line
            
            combinedMarkdown += contentLines.joined(separator: "\n")
        }
        
        // Add footer
        combinedMarkdown += """
        
        
        ---
        
        *Session export generated by Thoth v\(AppConstants.appVersion)*
        *Total articles in this export: \(extractions.count)*
        """
        
        try combinedMarkdown.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func sessionExportJSON(extractions: [ThothExtraction], to fileURL: URL) throws {
        let sessionData: [String: Any] = [
            "sessionExport": true,
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "totalExtractions": extractions.count,
            "appVersion": AppConstants.appVersion,
            "extractions": extractions.map { extraction -> [String: Any] in
                // Convert to dictionary for JSON serialization
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try! encoder.encode(extraction)
                return try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            }
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: sessionData, options: [.prettyPrinted, .sortedKeys])
        try jsonData.write(to: fileURL)
    }

    // MARK: - Helpers

    private func sanitizeFilename(_ filename: String) -> String {
        // Remove or replace invalid filename characters
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return filename.components(separatedBy: invalidCharacters).joined(separator: "_")
    }

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        return formatter
    }()
    
}
