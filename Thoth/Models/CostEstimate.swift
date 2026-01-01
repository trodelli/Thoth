//
//  CostEstimate.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

struct CostEstimate {
    let inputTokens: Int
    let outputTokens: Int
    let model: String
    
    var totalCost: Double {
        // Claude Sonnet 4 pricing (as of Dec 2024)
        let inputCostPer1M = 3.00   // $3 per million input tokens
        let outputCostPer1M = 15.00 // $15 per million output tokens
        
        let inputCost = (Double(inputTokens) / 1_000_000.0) * inputCostPer1M
        let outputCost = (Double(outputTokens) / 1_000_000.0) * outputCostPer1M
        
        return inputCost + outputCost
    }
    
    var formattedCost: String {
        if totalCost < 0.01 {
            return "<$0.01"
        } else {
            return String(format: "$%.2f", totalCost)
        }
    }
}

struct SessionCost {
    private(set) var extractions: [CostEstimate] = []
    
    var totalCost: Double {
        extractions.reduce(0.0) { $0 + $1.totalCost }
    }
    
    var formattedTotalCost: String {
        if totalCost < 0.01 {
            return "<$0.01"
        } else {
            return String(format: "$%.2f", totalCost)
        }
    }
    
    var totalInputTokens: Int {
        extractions.reduce(0) { $0 + $1.inputTokens }
    }
    
    var totalOutputTokens: Int {
        extractions.reduce(0) { $0 + $1.outputTokens }
    }
    
    mutating func add(_ estimate: CostEstimate) {
        extractions.append(estimate)
    }
    
    mutating func reset() {
        extractions.removeAll()
    }
}
