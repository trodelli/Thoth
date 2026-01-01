//
//  ExtractionProgress.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

enum ExtractionStep: String, CaseIterable {
    case fetchingWikipedia = "Fetching from Wikipedia"
    case parsingHTML = "Parsing HTML content"
    case generatingSummary = "Generating AI summary"
    case classifyingArticle = "Classifying article type"
    case extractingKeyFacts = "Extracting key facts"
    case extractingDates = "Extracting important dates"
    case extractingLocations = "Extracting locations"
    case extractingTopics = "Extracting related topics"
    case complete = "Complete"
    
    var estimatedDuration: TimeInterval {
        switch self {
        case .fetchingWikipedia: return 3.0
        case .parsingHTML: return 2.0
        case .generatingSummary: return 35.0
        case .classifyingArticle: return 4.0
        case .extractingKeyFacts: return 5.0
        case .extractingDates: return 4.0
        case .extractingLocations: return 4.0
        case .extractingTopics: return 3.0
        case .complete: return 0.0
        }
    }
    
    var icon: String {
        switch self {
        case .fetchingWikipedia: return "arrow.down.circle"
        case .parsingHTML: return "doc.text.magnifyingglass"
        case .generatingSummary: return "sparkles"
        case .classifyingArticle: return "tag"
        case .extractingKeyFacts: return "list.bullet.rectangle"
        case .extractingDates: return "calendar"
        case .extractingLocations: return "map"
        case .extractingTopics: return "link"
        case .complete: return "checkmark.circle.fill"
        }
    }
}

struct ExtractionProgress {
    var currentStep: ExtractionStep = .fetchingWikipedia
    var completedSteps: Set<ExtractionStep> = []
    var startTime: Date = Date()
    var aiEnabled: Bool = false
    
    var allSteps: [ExtractionStep] {
        if aiEnabled {
            return ExtractionStep.allCases
        } else {
            return [.fetchingWikipedia, .parsingHTML, .complete]
        }
    }
    
    var progress: Double {
        let total = Double(allSteps.count)
        let completed = Double(completedSteps.count)
        return completed / total
    }
    
    var estimatedTimeRemaining: TimeInterval {
        let remaining = allSteps.filter { !completedSteps.contains($0) && $0 != currentStep }
        let currentStepRemaining = currentStep.estimatedDuration * 0.5 // Assume halfway through current
        return remaining.reduce(currentStepRemaining) { $0 + $1.estimatedDuration }
    }
    
    mutating func complete(_ step: ExtractionStep) {
        completedSteps.insert(step)
    }
    
    mutating func start(_ step: ExtractionStep) {
        currentStep = step
    }
}
