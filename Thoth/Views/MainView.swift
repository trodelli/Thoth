//
//  MainView.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        VStack(spacing: 0) {
            // Global progress banner at the very top
            GlobalProgressBanner()
                .environmentObject(appState)
            
            NavigationSplitView {
            // Sidebar
            Sidebar()
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
        } content: {
            // Main content area
            Group {
                switch appState.selectedSection {
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
            // Detail panel
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
        .environmentObject(appState)
        .sheet(isPresented: $appState.showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
        }
    }
}

#Preview {
    MainView()
}
