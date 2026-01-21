//
//  SearchView.swift
//  Thoth
//
//  Created by theway.ink on January 21, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SearchView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: SearchViewModel
    
    @State private var showExportMenu: Bool = false
    @State private var exportSelectedOnly: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Header
            searchHeader
            
            Divider()
            
            // Content Area
            if viewModel.isSearching {
                searchingState
            } else if viewModel.hasResults {
                resultsView
            } else {
                emptyState
            }
        }
        .navigationTitle("Search")
        .alert("Search Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .onChange(of: viewModel.currentSession) { oldSession, newSession in
            // Add to recent searches when a search completes
            if let session = newSession {
                appState.addRecentSearch(session)
            }
        }
        .onChange(of: appState.pendingSearchAction) { oldAction, newAction in
            // Handle search actions from Sidebar
            guard let action = newAction else { return }
            
            switch action.type {
            case .clearAndNew:
                viewModel.clearSearch()
                
            case .restoreSession(let sessionId):
                if let session = appState.getRecentSearch(id: sessionId) {
                    viewModel.restoreSession(session)
                }
            }
            
            // Clear the action after handling
            appState.pendingSearchAction = nil
        }
        .onAppear {
            // Handle pending action when view appears
            if let action = appState.pendingSearchAction {
                switch action.type {
                case .clearAndNew:
                    viewModel.clearSearch()
                case .restoreSession(let sessionId):
                    if let session = appState.getRecentSearch(id: sessionId) {
                        viewModel.restoreSession(session)
                    }
                }
                appState.pendingSearchAction = nil
            }
        }
    }
    
    // MARK: - Search Header
    
    private var searchHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title row with AI badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Intelligent Article Discovery")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Enter keywords or describe what you're looking for")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // AI-powered badge (Segment B)
                HStack(spacing: 4) {
                    Image(systemName: "brain")
                        .font(.caption)
                    Text("AI-Powered")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.purple.opacity(0.15))
                .foregroundColor(.purple)
                .cornerRadius(12)
            }
            
            // Search Input
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., \"ancient Rome\" or \"articles about Roman ceramics from Tripoli\"", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            Task { await viewModel.performSearch() }
                        }
                    
                    if !viewModel.searchQuery.isEmpty {
                        Button(action: { viewModel.searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
                Button(action: {
                    Task { await viewModel.performSearch() }
                }) {
                    Text("Search")
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSearching)
            }
            
            // API Key Warning
            if !KeychainManager.shared.hasAPIKey(for: .anthropic) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("API key required for intelligent search")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Add Key") {
                        appState.showSettings = true
                    }
                    .font(.caption)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(20)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("Discover Wikipedia Articles")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text("Use AI to find relevant articles by keyword or description")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Example queries
            VStack(alignment: .leading, spacing: 8) {
                Text("Try searching for:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                ForEach(exampleQueries, id: \.self) { query in
                    Button(action: {
                        viewModel.searchQuery = query
                        Task { await viewModel.performSearch() }
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.caption)
                            Text(query)
                                .font(.callout)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var exampleQueries: [String] {
        [
            "Ancient Rome",
            "Renaissance artists from Florence",
            "Articles about quantum computing"
        ]
    }
    
    // MARK: - Searching State (Enhanced with Progress)
    
    private var searchingState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Main progress indicator
            ProgressView()
                .scaleEffect(1.5)
            
            VStack(spacing: 8) {
                Text("Searching...")
                    .font(.headline)
                
                Text("Finding relevant Wikipedia articles for \"\(viewModel.searchQuery)\"")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Step-by-step progress
            VStack(alignment: .leading, spacing: 12) {
                ForEach(searchSteps, id: \.self) { step in
                    HStack(spacing: 12) {
                        // Step icon with status
                        ZStack {
                            Circle()
                                .fill(stepBackgroundColor(for: step))
                                .frame(width: 32, height: 32)
                            
                            if isStepComplete(step) {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.white)
                            } else if isCurrentStep(step) {
                                ProgressView()
                                    .scaleEffect(0.6)
                            } else {
                                Image(systemName: step.icon)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Step label
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.rawValue)
                                .font(.subheadline)
                                .fontWeight(isCurrentStep(step) ? .medium : .regular)
                                .foregroundColor(isCurrentStep(step) ? .primary : .secondary)
                            
                            if isCurrentStep(step) && !viewModel.currentStepMessage.isEmpty {
                                Text(viewModel.currentStepMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(20)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
            .frame(maxWidth: 400)
            
            Spacer()
        }
        .padding()
    }
    
    private var searchSteps: [SearchStep] {
        [.preparingQuery, .contactingClaude, .parsingResponse, .validatingArticles]
    }
    
    private func isCurrentStep(_ step: SearchStep) -> Bool {
        viewModel.currentStep == step
    }
    
    private func isStepComplete(_ step: SearchStep) -> Bool {
        let steps = searchSteps
        guard let currentIndex = steps.firstIndex(of: viewModel.currentStep),
              let stepIndex = steps.firstIndex(of: step) else {
            return false
        }
        return stepIndex < currentIndex
    }
    
    private func stepBackgroundColor(for step: SearchStep) -> Color {
        if isStepComplete(step) {
            return .green
        } else if isCurrentStep(step) {
            return .blue
        } else {
            return .secondary.opacity(0.3)
        }
    }
    
    // MARK: - Results View
    
    private var resultsView: some View {
        VStack(spacing: 0) {
            // Results Header
            resultsHeader
            
            Divider()
            
            // Results List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.currentSession?.results ?? []) { result in
                        VStack(spacing: 0) {
                            SearchResultRow(
                                result: result,
                                isDuplicate: isDuplicate(result),
                                isPreviewActive: viewModel.previewArticle?.id == result.id,
                                onToggle: { viewModel.toggleSelection(for: result) },
                                onOpenInBrowser: { openInBrowser(result.url) },
                                onPreview: { viewModel.showPreview(for: result) }
                            )
                            
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                    
                    // Load More Button
                    if viewModel.canLoadMore {
                        loadMoreButton
                    } else if viewModel.currentSession?.isFullyLoaded == true {
                        fullyLoadedMessage
                    }
                }
                .padding(.horizontal, 8)
            }
            
            Divider()
            
            // Action Bar
            actionBar
        }
    }
    
    // MARK: - Results Header
    
    private var resultsHeader: some View {
        HStack {
            // Result count
            VStack(alignment: .leading, spacing: 2) {
                Text("Found ~\(viewModel.estimatedTotal) articles")
                    .font(.headline)
                
                Text(viewModel.progressText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Selection controls + Export
            HStack(spacing: 12) {
                Button(action: viewModel.selectAll) {
                    Text("Select All (\(viewModel.loadedCount))")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
                
                Button(action: viewModel.deselectAll) {
                    Text("Deselect All")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                
                // Export Button (moved from bottom action bar)
                Menu {
                    Text("Export All Results")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(SearchExportFormat.allCases) { format in
                        Button(action: { exportResults(format: format, selectedOnly: false) }) {
                            Text(format.rawValue)
                        }
                    }
                    
                    if viewModel.selectedCount > 0 {
                        Divider()
                        
                        Text("Export Selected Only")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(SearchExportFormat.allCases) { format in
                            Button(action: { exportResults(format: format, selectedOnly: true) }) {
                                Text(format.rawValue)
                            }
                        }
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.caption)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Load More Button
    
    private var loadMoreButton: some View {
        VStack(spacing: 8) {
            if viewModel.isLoadingMore {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading more articles...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Show current step during loading
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.currentStep.icon)
                            .font(.caption)
                        Text(viewModel.currentStepMessage)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else {
                Button(action: {
                    Task { await viewModel.loadMore() }
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                        Text("Continue Search (Load 50 more)")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .padding(.vertical, 20)
            }
        }
    }
    
    private var fullyLoadedMessage: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("All \(viewModel.loadedCount) articles loaded")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Action Bar
    
    private var actionBar: some View {
        HStack {
            // Selection count
            if viewModel.selectedCount > 0 {
                Label("\(viewModel.selectedCount) selected", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Add to Input Button
            Button(action: addToInput) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add \(viewModel.selectedCount > 0 ? "\(viewModel.selectedCount) Selected" : "All") to Input")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.currentSession?.results.isEmpty ?? true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Helper Methods
    
    private func isDuplicate(_ result: SearchResult) -> Bool {
        // Check against existing URLs in input (from recent URLs or would need InputViewModel access)
        // For now, check against recent URLs as a proxy
        appState.recentURLs.contains(result.url)
    }
    
    private func openInBrowser(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
    
    private func addToInput() {
        let urlsToAdd = viewModel.selectedCount > 0 ? viewModel.selectedURLs : viewModel.currentSession?.results.map { $0.url } ?? []
        
        // Add URLs to appState for InputView to pick up
        appState.pendingSearchURLs = urlsToAdd
        
        // Switch to Input tab
        appState.selectedSection = .input
        
        logger.success("Added \(urlsToAdd.count) articles to extraction queue")
    }
    
    private var logger: Logger { Logger.shared }
    
    private func exportResults(format: SearchExportFormat, selectedOnly: Bool) {
        let content = viewModel.exportResults(format: format, selectedOnly: selectedOnly)
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: format.fileExtension)!]
        
        let querySlug = viewModel.currentSession?.query
            .replacingOccurrences(of: " ", with: "_")
            .prefix(30) ?? "search"
        panel.nameFieldStringValue = "wikipedia_\(querySlug).\(format.fileExtension)"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                self.logger.success("Exported search results to \(url.lastPathComponent)")
            } catch {
                self.logger.error("Export failed", details: error.localizedDescription)
            }
        }
    }
}

// MARK: - Preview

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(viewModel: SearchViewModel())
            .environmentObject(AppState())
            .frame(width: 600, height: 700)
    }
}
