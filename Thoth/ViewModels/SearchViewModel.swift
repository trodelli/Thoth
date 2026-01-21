//
//  SearchViewModel.swift
//  Thoth
//
//  Created by theway.ink on January 21, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var searchQuery: String = ""
    @Published var isSearching: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var currentSession: SearchSession?
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // Progress tracking
    @Published var currentStep: SearchStep = .preparingQuery
    @Published var currentStepMessage: String = ""
    
    // Article preview
    @Published var previewArticle: SearchResult?
    @Published var previewData: ArticlePreviewData?
    @Published var isLoadingPreview: Bool = false
    
    // MARK: - Services
    
    private var searchService: WikipediaSearchService?
    private let wikipediaService = WikipediaService()
    private let logger = Logger.shared
    
    // MARK: - Computed Properties
    
    var hasResults: Bool {
        currentSession != nil && !currentSession!.results.isEmpty
    }
    
    var canLoadMore: Bool {
        guard let session = currentSession else { return false }
        return !session.isFullyLoaded && session.loadedCount < session.estimatedTotalCount
    }
    
    var selectedCount: Int {
        currentSession?.selectedCount ?? 0
    }
    
    var loadedCount: Int {
        currentSession?.loadedCount ?? 0
    }
    
    var estimatedTotal: Int {
        currentSession?.estimatedTotalCount ?? 0
    }
    
    var progressText: String {
        guard let session = currentSession else { return "" }
        if session.isFullyLoaded {
            return "All \(session.loadedCount) articles loaded"
        }
        return "Showing \(session.loadedCount) of ~\(session.estimatedTotalCount)"
    }
    
    var selectedResults: [SearchResult] {
        currentSession?.selectedResults ?? []
    }
    
    var selectedURLs: [URL] {
        selectedResults.map { $0.url }
    }
    
    // MARK: - Initialization
    
    init() {
        let service = WikipediaSearchService()
        service.onProgressUpdate = { [weak self] step, message in
            self?.currentStep = step
            self?.currentStepMessage = message
        }
        self.searchService = service
    }
    
    // MARK: - Actions
    
    /// Perform a new search
    func performSearch() async {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        guard let searchService = searchService else {
            print("🔍 [ERROR] SearchService is nil!")
            return
        }
        
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🔍 [SearchViewModel] Starting search for: \"\(query)\"")
        
        isSearching = true
        errorMessage = nil
        currentStep = .preparingQuery
        currentStepMessage = "Initializing search..."
        previewArticle = nil
        
        do {
            print("🔍 [SearchViewModel] Calling searchService.performInitialSearch...")
            let operationResult = try await searchService.performInitialSearch(query: query)
            print("🔍 [SearchViewModel] Got results: \(operationResult.results.count), estimated: \(operationResult.estimatedTotal)")
            print("💰 [SearchViewModel] Tokens: \(operationResult.inputTokens) in, \(operationResult.outputTokens) out")
            
            // Create cost tracker and add initial search cost
            var costTracker = SearchCostTracker()
            costTracker.addEntry(
                label: "Initial search",
                inputTokens: operationResult.inputTokens,
                outputTokens: operationResult.outputTokens
            )
            
            currentSession = SearchSession(
                query: query,
                results: operationResult.results,
                estimatedTotalCount: max(operationResult.estimatedTotal, operationResult.results.count),
                loadedCount: operationResult.results.count,
                isFullyLoaded: operationResult.results.count >= operationResult.estimatedTotal || operationResult.estimatedTotal == 0,
                costTracker: costTracker
            )
            
            if operationResult.results.isEmpty {
                print("🔍 [SearchViewModel] WARNING: No results returned!")
                logger.warning("Search completed but found 0 results for: \"\(query)\"")
                errorMessage = "No Wikipedia articles found for \"\(query)\". Try a different search term."
                showError = true
            } else {
                logger.success("Search complete: found ~\(operationResult.estimatedTotal) articles, loaded \(operationResult.results.count)")
            }
            
        } catch {
            print("🔍 [SearchViewModel] ERROR: \(error)")
            print("🔍 [SearchViewModel] Error type: \(type(of: error))")
            errorMessage = "Search failed: \(error.localizedDescription)"
            showError = true
            logger.error("Search failed", details: error.localizedDescription)
        }
        
        isSearching = false
        print("🔍 [SearchViewModel] Search finished, isSearching = false")
    }
    
    /// Load more results for current search
    func loadMore() async {
        guard let session = currentSession, canLoadMore, let searchService = searchService else { return }
        
        isLoadingMore = true
        currentStep = .preparingQuery
        currentStepMessage = "Preparing to load more..."
        
        do {
            let alreadyLoaded = session.results.map { $0.title }
            let batchNumber = session.loadedCount / 50
            
            let operationResult = try await searchService.continueSearch(
                query: session.query,
                alreadyLoaded: alreadyLoaded,
                batchNumber: batchNumber
            )
            
            // Filter out any duplicates
            let existingTitles = Set(session.results.map { $0.title.lowercased() })
            let newResults = operationResult.results.filter { !existingTitles.contains($0.title.lowercased()) }
            
            // Update session with new results
            currentSession?.results.append(contentsOf: newResults)
            currentSession?.loadedCount = (currentSession?.results.count ?? 0)
            
            // Add cost entry for this load more operation
            let loadMoreCount = (currentSession?.costTracker.entries.count ?? 1)
            currentSession?.costTracker.addEntry(
                label: "Load more (×\(loadMoreCount))",
                inputTokens: operationResult.inputTokens,
                outputTokens: operationResult.outputTokens
            )
            
            // Check if we've loaded everything
            if newResults.isEmpty || (currentSession?.loadedCount ?? 0) >= (currentSession?.estimatedTotalCount ?? 0) {
                currentSession?.isFullyLoaded = true
            }
            
            logger.success("Loaded \(newResults.count) more articles")
            
        } catch {
            errorMessage = "Failed to load more: \(error.localizedDescription)"
            showError = true
            logger.error("Load more failed", details: error.localizedDescription)
        }
        
        isLoadingMore = false
    }
    
    /// Clear current search and start fresh (Segment E)
    func clearSearch() {
        searchQuery = ""
        currentSession = nil
        errorMessage = nil
        currentStep = .preparingQuery
        currentStepMessage = ""
        previewArticle = nil
        previewData = nil
        isLoadingPreview = false
        print("🔍 [SearchViewModel] Search cleared for new search")
    }
    
    /// Restore a previous search session (Segment F)
    func restoreSession(_ session: SearchSession) {
        searchQuery = session.query
        currentSession = session
        errorMessage = nil
        currentStep = .complete
        currentStepMessage = ""
        previewArticle = nil
        previewData = nil
        isLoadingPreview = false
        print("🔍 [SearchViewModel] Restored session: \"\(session.query)\" with \(session.results.count) results")
    }
    
    // MARK: - Selection Management
    
    func toggleSelection(for result: SearchResult) {
        guard let index = currentSession?.results.firstIndex(where: { $0.id == result.id }) else {
            return
        }
        currentSession?.results[index].isSelected.toggle()
    }
    
    func selectAll() {
        guard currentSession != nil else { return }
        for index in currentSession!.results.indices {
            currentSession!.results[index].isSelected = true
        }
    }
    
    func deselectAll() {
        guard currentSession != nil else { return }
        for index in currentSession!.results.indices {
            currentSession!.results[index].isSelected = false
        }
    }
    
    // MARK: - Article Preview
    
    /// Show preview for an article and fetch enhanced data from Wikipedia
    func showPreview(for article: SearchResult) {
        // If same article, toggle off
        if previewArticle?.id == article.id {
            clearPreview()
            return
        }
        
        previewArticle = article
        previewData = nil
        isLoadingPreview = true
        
        // Fetch enhanced preview data from Wikipedia API (free, no AI cost)
        Task {
            do {
                let data = try await wikipediaService.fetchArticlePreview(title: article.title)
                await MainActor.run {
                    // Only update if still showing same article
                    if self.previewArticle?.id == article.id {
                        self.previewData = data
                        self.isLoadingPreview = false
                        print("📖 [Preview] Loaded: \(data.title), \(data.extract.count) chars, \(data.categories.count) categories")
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoadingPreview = false
                    print("📖 [Preview] Failed to load: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func clearPreview() {
        previewArticle = nil
        previewData = nil
        isLoadingPreview = false
    }
    
    // MARK: - Export
    
    func exportResults(format: SearchExportFormat, selectedOnly: Bool = false) -> String {
        guard let session = currentSession else { return "" }
        
        let resultsToExport = selectedOnly ? session.selectedResults : session.results
        
        switch format {
        case .txt:
            return exportAsText(session: session, results: resultsToExport)
        case .markdown:
            return exportAsMarkdown(session: session, results: resultsToExport)
        case .json:
            return exportAsJSON(session: session, results: resultsToExport)
        }
    }
    
    private func exportAsText(session: SearchSession, results: [SearchResult]) -> String {
        var output = """
        # Wikipedia Articles: \(session.query)
        # Generated: \(formattedDate(session.timestamp))
        # Query: "\(session.query)"
        # Results: \(results.count) articles
        
        """
        
        for result in results {
            output += "\(result.url.absoluteString)\n"
        }
        
        return output
    }
    
    private func exportAsMarkdown(session: SearchSession, results: [SearchResult]) -> String {
        var output = """
        # Wikipedia Articles: \(session.query)
        
        **Query:** \(session.query)  
        **Generated:** \(formattedDate(session.timestamp))  
        **Results:** \(results.count) articles
        
        ## Articles
        
        """
        
        for (index, result) in results.enumerated() {
            output += "\(index + 1). [\(result.title)](\(result.url.absoluteString))\n"
            if !result.description.isEmpty {
                output += "   *\(result.description)*\n"
            }
            output += "\n"
        }
        
        return output
    }
    
    private func exportAsJSON(session: SearchSession, results: [SearchResult]) -> String {
        let exportData: [String: Any] = [
            "query": session.query,
            "generated": ISO8601DateFormatter().string(from: session.timestamp),
            "resultCount": results.count,
            "articles": results.map { result in
                [
                    "title": result.title,
                    "url": result.url.absoluteString,
                    "description": result.description
                ]
            }
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return "{}"
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Duplicate Detection
    
    func checkDuplicates(existingURLs: [URL]) -> Set<UUID> {
        guard let session = currentSession else { return [] }
        
        let existingSet = Set(existingURLs.map { $0.absoluteString.lowercased() })
        
        var duplicateIDs: Set<UUID> = []
        for result in session.results {
            if existingSet.contains(result.url.absoluteString.lowercased()) {
                duplicateIDs.insert(result.id)
            }
        }
        
        return duplicateIDs
    }
}
