//
//  SearchResult.swift
//  Thoth
//
//  Created by theway.ink on January 21, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

/// Represents a single Wikipedia article found during search
struct SearchResult: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let url: URL
    let description: String
    var isSelected: Bool
    
    init(id: UUID = UUID(), title: String, url: URL, description: String, isSelected: Bool = false) {
        self.id = id
        self.title = title
        self.url = url
        self.description = description
        self.isSelected = isSelected
    }
    
    /// Create from Wikipedia article title
    static func fromTitle(_ title: String, description: String = "") -> SearchResult? {
        let encodedTitle = title.replacingOccurrences(of: " ", with: "_")
        guard let url = URL(string: "https://en.wikipedia.org/wiki/\(encodedTitle)") else {
            return nil
        }
        return SearchResult(title: title, url: url, description: description)
    }
    
    // Hashable conformance (exclude isSelected for identity)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents a completed search with its results
struct SearchSession: Identifiable, Codable, Equatable {
    let id: UUID
    let query: String
    let timestamp: Date
    var results: [SearchResult]
    var estimatedTotalCount: Int
    var loadedCount: Int
    var isFullyLoaded: Bool
    
    /// Cost tracking for this search session
    var costTracker: SearchCostTracker
    
    init(
        id: UUID = UUID(),
        query: String,
        timestamp: Date = Date(),
        results: [SearchResult] = [],
        estimatedTotalCount: Int = 0,
        loadedCount: Int = 0,
        isFullyLoaded: Bool = false,
        costTracker: SearchCostTracker = SearchCostTracker()
    ) {
        self.id = id
        self.query = query
        self.timestamp = timestamp
        self.results = results
        self.estimatedTotalCount = estimatedTotalCount
        self.loadedCount = loadedCount
        self.isFullyLoaded = isFullyLoaded
        self.costTracker = costTracker
    }
    
    /// Truncated query for sidebar display
    var truncatedQuery: String {
        let maxLength = 20
        if query.count <= maxLength {
            return query
        }
        return String(query.prefix(maxLength)) + "..."
    }
    
    /// Count of selected results
    var selectedCount: Int {
        results.filter { $0.isSelected }.count
    }
    
    /// Selected results only
    var selectedResults: [SearchResult] {
        results.filter { $0.isSelected }
    }
    
    /// Number of validated articles (articles that passed Wikipedia verification)
    var validatedCount: Int {
        results.count
    }
    
    /// Formatted duration string (delegates to costTracker)
    var formattedDuration: String {
        costTracker.formattedDuration
    }
    
    // Equatable - compare by ID and state for change detection
    static func == (lhs: SearchSession, rhs: SearchSession) -> Bool {
        lhs.id == rhs.id &&
        lhs.results.count == rhs.results.count &&
        lhs.selectedCount == rhs.selectedCount &&
        lhs.costTracker.requestCount == rhs.costTracker.requestCount
    }
}

/// Export format options for search results
enum SearchExportFormat: String, CaseIterable, Identifiable {
    case txt = "Plain Text (.txt)"
    case markdown = "Markdown (.md)"
    case json = "JSON (.json)"
    
    var id: String { rawValue }
    
    var fileExtension: String {
        switch self {
        case .txt: return "txt"
        case .markdown: return "md"
        case .json: return "json"
        }
    }
}
