//
//  Sidebar.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI

struct Sidebar: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        List(selection: $appState.selectedSection) {
            // Navigation sections - all use identical pattern
            ForEach(NavigationSection.allCases) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            
            Divider()
            
            Button(action: { appState.showSettings = true }) {
                Label("Settings", systemImage: "gear")
            }
            .buttonStyle(.plain)
            
            // Recent Searches Section (session-only)
            if !appState.recentSearches.isEmpty {
                Divider()
                
                // Section header
                HStack {
                    Text("Recent Searches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Spacer()
                    
                    Button(action: { appState.clearRecentSearches() }) {
                        Text("Clear")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 4)
                
                // Section content - clickable to restore session
                ForEach(appState.recentSearches) { session in
                    RecentSearchRow(session: session)
                        .environmentObject(appState)
                }
            }
        }
        .safeAreaInset(edge: .top) {
            // Add subtle top spacing for visual balance
            Spacer()
                .frame(height: 8)
        }
        .navigationTitle("Thoth")
        .onChange(of: appState.selectedSection) { oldSection, newSection in
            // Trigger clear action when navigating TO Search from another tab
            if newSection == .search && oldSection != .search {
                appState.pendingSearchAction = SearchAction(.clearAndNew)
            }
        }
    }
}

// MARK: - Recent Search Row

struct RecentSearchRow: View {
    let session: SearchSession
    @EnvironmentObject var appState: AppState
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: {
            // Trigger restore session action
            appState.pendingSearchAction = SearchAction(.restoreSession(session.id))
            appState.selectedSection = .search
        }) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(session.truncatedQuery)
                    .font(.callout)
                    .foregroundColor(.blue)  // Blue font for recent searches
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(session.results.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    Sidebar()
        .environmentObject(AppState())
}
