//
//  CostCalculator.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

class CostCalculator {
    static let shared = CostCalculator()
    
    private init() {}
    
    /// Estimate cost before extraction based on word count
    func estimateCost(wordCount: Int, aiEnabled: Bool) -> CostEstimate {
        guard aiEnabled else {
            return CostEstimate(inputTokens: 0, outputTokens: 0, model: AppConstants.Claude.model)
        }
        
        // Rough estimates based on typical extraction
        // Input: article content + prompts
        let estimatedInputTokens = Int(Double(wordCount) * 1.3) + 2000 // Article + prompts
        
        // Output: summary + facts + dates + locations + topics
        let estimatedOutputTokens = Int(Double(wordCount) * 0.15) // ~15% of original as output
        
        return CostEstimate(
            inputTokens: estimatedInputTokens,
            outputTokens: estimatedOutputTokens,
            model: AppConstants.Claude.model
        )
    }
    
    /// Calculate actual cost from API usage
    func calculateCost(inputTokens: Int, outputTokens: Int) -> CostEstimate {
        return CostEstimate(
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            model: AppConstants.Claude.model
        )
    }
}
