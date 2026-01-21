//
//  MainView.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var searchViewModel = SearchViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Global progress banner at the very top
            if appState.isExtracting, let progress = appState.currentProgress {
                GlobalProgressBannerContent(progress: progress)
                    .environmentObject(appState)
                    .id("progress-banner")
            }
            
            NavigationSplitView {
                // Sidebar
                Sidebar()
                    .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
            } content: {
                // Main content area
                Group {
                    switch appState.selectedSection {
                    case .search:
                        SearchView(viewModel: searchViewModel)
                    case .input:
                        InputView()
                    case .extractions:
                        ExtractionListView()
                    case .logs:
                        LogView()
                    }
                }
                .navigationSplitViewColumnWidth(min: 400, ideal: 500, max: 700)
            } detail: {
                // Detail panel - context-aware based on selected section
                detailView
            }
            .environmentObject(appState)
        }
        .sheet(isPresented: $appState.showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
    }
    
    @ViewBuilder
    private var detailView: some View {
        switch appState.selectedSection {
        case .search:
            // Show search detail panel
            SearchDetailPanel(viewModel: searchViewModel)
                .environmentObject(appState)
            
        case .input, .extractions, .logs:
            // Show extraction detail or empty state
            if let extraction = appState.selectedExtraction {
                ExtractionDetailView(extraction: extraction)
            } else {
                EmptyStateView(
                    icon: "doc.text.magnifyingglass",
                    title: "No Article Selected",
                    message: "Select an extraction from the list to view details"
                )
            }
        }
    }
}

// Banner content as a separate view with opaque background
struct GlobalProgressBannerContent: View {
    let progress: ExtractionProgress
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Working: \(appState.currentExtractionIndex + 1) of \(appState.validURLCount)")
                .font(.body)
                .fontWeight(.medium)
            
            Text("•")
                .foregroundColor(.secondary)
            
            if let currentURL = appState.currentURL {
                Text(currentURL.lastPathComponent.replacingOccurrences(of: "_", with: " "))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Text("•")
                .foregroundColor(.secondary)
            
            if progress.estimatedTimeRemaining > 0 {
                Text("~\(Int(progress.estimatedTimeRemaining))s remaining")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { appState.cancelExtraction() }) {
                Text("Cancel")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.primary.opacity(0.1)),
            alignment: .bottom
        )
    }
}

#Preview {
    MainView()
        .environmentObject(AppState())
}
