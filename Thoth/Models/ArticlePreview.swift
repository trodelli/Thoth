//
//  ArticlePreview.swift
//  Thoth
//
//  Created by theway.ink on January 21, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

/// Enhanced preview data for a Wikipedia article
struct ArticlePreview: Identifiable {
    let id: UUID
    let title: String
    let url: URL
    let description: String
    
    /// Wikipedia article extract (first few sentences)
    var extract: String?
    
    /// Article categories from Wikipedia
    var categories: [String]
    
    /// Whether the preview data has been loaded
    var isLoaded: Bool
    
    /// Whether the preview is currently loading
    var isLoading: Bool
    
    /// Error message if loading failed
    var errorMessage: String?
    
    /// Initialize from a SearchResult
    init(from result: SearchResult) {
        self.id = result.id
        self.title = result.title
        self.url = result.url
        self.description = result.description
        self.extract = nil
        self.categories = []
        self.isLoaded = false
        self.isLoading = false
        self.errorMessage = nil
    }
    
    /// Update with loaded data
    mutating func update(extract: String?, categories: [String]) {
        self.extract = extract
        self.categories = categories
        self.isLoaded = true
        self.isLoading = false
        self.errorMessage = nil
    }
    
    /// Mark as loading
    mutating func startLoading() {
        self.isLoading = true
        self.errorMessage = nil
    }
    
    /// Mark as failed
    mutating func setError(_ message: String) {
        self.isLoading = false
        self.errorMessage = message
    }
    
    /// Display text - uses extract if available, falls back to description
    var displayText: String {
        if let extract = extract, !extract.isEmpty {
            return extract
        }
        return description
    }
    
    /// Formatted categories for display (limit to first 5)
    var displayCategories: [String] {
        Array(categories.prefix(5))
    }
}
