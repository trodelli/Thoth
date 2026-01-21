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
    case search = "Search"
    case input = "Input"
    case extractions = "Extractions"
    case logs = "Activity Log"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .search: return "magnifyingglass"
        case .input: return "square.and.arrow.down"
        case .extractions: return "doc.text"
        case .logs: return "list.bullet.rectangle"
        }
    }
}

/// Actions that can be triggered from Sidebar for Search tab
struct SearchAction: Equatable {
    let id: UUID
    let type: SearchActionType
    
    init(_ type: SearchActionType) {
        self.id = UUID()
        self.type = type
    }
    
    static func == (lhs: SearchAction, rhs: SearchAction) -> Bool {
        lhs.id == rhs.id
    }
}

enum SearchActionType {
    case clearAndNew
    case restoreSession(UUID)
}

@MainActor
class AppState: ObservableObject {
    @Published var selectedSection: NavigationSection = .input
    @Published var selectedExtraction: ThothExtraction?
    @Published var extractions: [ThothExtraction] = []
    @Published var showSettings = false
    @Published var isExtracting = false
    
    // MARK: - Onboarding
    
    /// Controls display of the Welcome Wizard
    @Published var showWelcomeWizard: Bool = false
    
    // Progress tracking
    @Published var currentProgress: ExtractionProgress?
    @Published var sessionCost: SessionCost = SessionCost()
    @Published var recentURLs: [URL] = []

    // Global progress tracking
    @Published var validURLCount: Int = 0
    @Published var currentURL: URL?
    @Published var currentExtractionIndex: Int = 0
    
    // MARK: - Search Feature (Session-Only)
    
    /// Recent searches - stored only for current session (not persisted)
    @Published var recentSearches: [SearchSession] = []
    
    /// URLs pending to be added to Input from Search
    @Published var pendingSearchURLs: [URL] = []
    
    /// Pending search action (triggered from Sidebar)
    @Published var pendingSearchAction: SearchAction?
    
    /// Track if a search has been performed this session
    @Published var hasPerformedSearch: Bool = false
    
    /// Maximum number of recent searches to display in sidebar
    private let maxRecentSearches: Int = 5
    
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
    
    // Onboarding persistence
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
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
    
    // MARK: - Search Management (Session-Only)
    
    /// Add a search session to recent searches
    func addRecentSearch(_ session: SearchSession) {
        // If this exact session already exists (by ID), don't reorder - it's being restored
        if recentSearches.contains(where: { $0.id == session.id }) {
            return
        }
        
        // Remove if same query already exists (different session, same search term)
        recentSearches.removeAll { $0.query.lowercased() == session.query.lowercased() }
        
        // Add to front
        recentSearches.insert(session, at: 0)
        
        // Keep only max recent
        if recentSearches.count > maxRecentSearches {
            recentSearches.removeLast()
        }
        
        // Mark that a search has been performed
        hasPerformedSearch = true
    }
    
    /// Clear all recent searches
    func clearRecentSearches() {
        recentSearches.removeAll()
        hasPerformedSearch = false
    }
    
    /// Get a recent search by ID
    func getRecentSearch(id: UUID) -> SearchSession? {
        recentSearches.first { $0.id == id }
    }
    
    /// Consume pending search URLs (called by InputView)
    func consumePendingSearchURLs() -> [URL] {
        let urls = pendingSearchURLs
        pendingSearchURLs = []
        return urls
    }
}
