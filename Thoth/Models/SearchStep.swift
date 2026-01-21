//
//  SearchStep.swift
//  Thoth
//
//  Created by theway.ink on January 21, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

/// Represents the current step in the search process
enum SearchStep: String, CaseIterable {
    case preparingQuery = "Preparing query"
    case contactingClaude = "Contacting Claude AI"
    case parsingResponse = "Parsing response"
    case validatingArticles = "Validating articles"
    case complete = "Complete"
    
    var icon: String {
        switch self {
        case .preparingQuery: return "text.magnifyingglass"
        case .contactingClaude: return "brain"
        case .parsingResponse: return "doc.text"
        case .validatingArticles: return "checkmark.shield"
        case .complete: return "checkmark.circle"
        }
    }
}
