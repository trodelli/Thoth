//
//  AppState.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

enum NavigationSection: String, CaseIterable, Identifiable {
    case input = "Input"
    case extractions = "Extractions"
    case logs = "Activity Log"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .input: return "square.and.arrow.down"
        case .extractions: return "doc.text"
        case .logs: return "list.bullet.rectangle"
        }
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var selectedSection: NavigationSection = .input
    @Published var selectedExtraction: ThothExtraction?
    @Published var extractions: [ThothExtraction] = []
    @Published var showSettings = false
    @Published var isExtracting = false
    
    // NEW: Progress tracking
    @Published var currentProgress: ExtractionProgress?
    @Published var sessionCost: SessionCost = SessionCost()
    @Published var recentURLs: [URL] = []

    // NEW: Global progress tracking
    @Published var validURLCount: Int = 0
    @Published var currentURL: URL?
    @Published var currentExtractionIndex: Int = 0
    
    // Services
    let wikipediaService = WikipediaService()
    let wikipediaParser = WikipediaParser()
    let exportService = ExportService()
    let logger = Logger.shared
    
    // Settings
    @AppStorage("summaryRatio") var summaryRatio: Double = AppConstants.Defaults.summaryRatio
    @AppStorage("requestDelay") var requestDelay: Double = AppConstants.Defaults.requestDelay
    @AppStorage("aiEnabled") var aiEnabled: Bool = false
    @AppStorage("exportFormat") var exportFormat: String = ExportFormat.markdown.rawValue
    @AppStorage("sortOldestFirst") var sortOldestFirst: Bool = false
    
    // Computed property for sorted extractions
    var sortedExtractions: [ThothExtraction] {
        if sortOldestFirst {
            return extractions.reversed()
        }
        return extractions
    }
    
    func addExtraction(_ extraction: ThothExtraction) {
        extractions.insert(extraction, at: 0)
        selectedExtraction = extraction
        // Don't auto-switch tabs - let caller decide when to switch
    }
    
    func removeExtraction(_ extraction: ThothExtraction) {
        extractions.removeAll { $0.id == extraction.id }
        if selectedExtraction?.id == extraction.id {
            selectedExtraction = extractions.first
        }
    }
    
    func clearExtractions() {
        extractions.removeAll()
        selectedExtraction = nil
    }
    
    func exportExtraction(_ extraction: ThothExtraction) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "md")!]
        panel.nameFieldStringValue = "\(extraction.article.title).md"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            do {
                try self.exportService.exportMarkdown(extraction, to: url)
                self.logger.success("Exported: \(extraction.article.title)")
            } catch {
                self.logger.error("Export failed", details: error.localizedDescription)
            }
        }
        
    }

    // MARK: - Progress Tracking

    func startProgress(aiEnabled: Bool) {
        currentProgress = ExtractionProgress(aiEnabled: aiEnabled)
    }

    func updateProgress(step: ExtractionStep) {
        currentProgress?.start(step)
    }

    func completeProgress(step: ExtractionStep) {
        currentProgress?.complete(step)
    }

    func resetProgress() {
        currentProgress = nil
    }

    // MARK: - Cost Tracking

    func addCost(inputTokens: Int, outputTokens: Int) {
        let estimate = CostCalculator.shared.calculateCost(
            inputTokens: inputTokens,
            outputTokens: outputTokens
        )
        sessionCost.add(estimate)
    }

    func resetSessionCost() {
        sessionCost.reset()
    }

    // MARK: - Recent URLs

    func addRecentURL(_ url: URL) {
        // Remove if already exists
        recentURLs.removeAll { $0 == url }
        
        // Add to front
        recentURLs.insert(url, at: 0)
        
        // Keep only max recent
        if recentURLs.count > AppConstants.Defaults.maxRecentArticles {
            recentURLs.removeLast()
        }
    }
    
    // MARK: - Extraction Control

    func cancelExtraction() {
        isExtracting = false
        resetProgress()
    }
}
