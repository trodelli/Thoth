//
//  SearchCostTracker.swift
//  Thoth
//
//  Created by theway.ink on January 21, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

/// Tracks API usage and costs for a search session
struct SearchCostTracker: Codable {
    /// Individual cost entries for each API call
    var entries: [CostEntry] = []
    
    /// When the search session started
    var searchStartTime: Date = Date()
    
    /// Represents a single API call's cost
    struct CostEntry: Identifiable, Codable {
        let id: UUID
        let label: String
        let inputTokens: Int
        let outputTokens: Int
        let timestamp: Date
        
        init(id: UUID = UUID(), label: String, inputTokens: Int, outputTokens: Int, timestamp: Date = Date()) {
            self.id = id
            self.label = label
            self.inputTokens = inputTokens
            self.outputTokens = outputTokens
            self.timestamp = timestamp
        }
        
        var cost: Double {
            SearchCostTracker.calculateCost(inputTokens: inputTokens, outputTokens: outputTokens)
        }
        
        var formattedCost: String {
            SearchCostTracker.formatCost(cost)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Total number of API requests made
    var requestCount: Int {
        entries.count
    }
    
    /// Total input tokens across all requests
    var totalInputTokens: Int {
        entries.reduce(0) { $0 + $1.inputTokens }
    }
    
    /// Total output tokens across all requests
    var totalOutputTokens: Int {
        entries.reduce(0) { $0 + $1.outputTokens }
    }
    
    /// Total tokens (input + output)
    var totalTokens: Int {
        totalInputTokens + totalOutputTokens
    }
    
    /// Total cost in USD
    var totalCost: Double {
        entries.reduce(0) { $0 + $1.cost }
    }
    
    /// Formatted total cost string
    var formattedTotalCost: String {
        formatCost(totalCost)
    }
    
    /// Formatted input tokens with commas
    var formattedInputTokens: String {
        NumberFormatter.localizedString(from: NSNumber(value: totalInputTokens), number: .decimal)
    }
    
    /// Formatted output tokens with commas
    var formattedOutputTokens: String {
        NumberFormatter.localizedString(from: NSNumber(value: totalOutputTokens), number: .decimal)
    }
    
    /// Duration since search started
    var duration: TimeInterval {
        Date().timeIntervalSince(searchStartTime)
    }
    
    /// Formatted duration string
    var formattedDuration: String {
        let totalSeconds = Int(duration)
        if totalSeconds < 60 {
            return "\(totalSeconds)s"
        } else {
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return "\(minutes)m \(seconds)s"
        }
    }
    
    // MARK: - Methods
    
    /// Add a new cost entry
    mutating func addEntry(label: String, inputTokens: Int, outputTokens: Int) {
        let entry = CostEntry(
            label: label,
            inputTokens: inputTokens,
            outputTokens: outputTokens
        )
        entries.append(entry)
    }
    
    /// Add entry for initial search
    mutating func addInitialSearch(inputTokens: Int, outputTokens: Int) {
        addEntry(label: "Initial search", inputTokens: inputTokens, outputTokens: outputTokens)
    }
    
    /// Add entry for loading more results
    mutating func addLoadMore(batchNumber: Int, inputTokens: Int, outputTokens: Int) {
        addEntry(label: "Load more (×\(batchNumber))", inputTokens: inputTokens, outputTokens: outputTokens)
    }
    
    /// Reset all tracking
    mutating func reset() {
        entries.removeAll()
        searchStartTime = Date()
    }
    
    // MARK: - Cost Calculation
    
    /// Calculate cost based on Claude Sonnet pricing
    /// Input: $3.00 per million tokens
    /// Output: $15.00 per million tokens
    static func calculateCost(inputTokens: Int, outputTokens: Int) -> Double {
        let inputCost = Double(inputTokens) / 1_000_000 * 3.00
        let outputCost = Double(outputTokens) / 1_000_000 * 15.00
        return inputCost + outputCost
    }
    
    /// Format a cost value
    func formatCost(_ cost: Double) -> String {
        if cost < 0.001 {
            return "<$0.001"
        }
        return String(format: "$%.4f", cost)
    }
    
    /// Static version for formatting
    static func formatCost(_ cost: Double) -> String {
        if cost < 0.001 {
            return "<$0.001"
        }
        return String(format: "$%.4f", cost)
    }
}
