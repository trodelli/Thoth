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
            ForEach(NavigationSection.allCases) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            
            Divider()
            
            Button(action: { appState.showSettings = true }) {
                Label("Settings", systemImage: "gear")
            }
            .buttonStyle(.plain)
        }
        .safeAreaInset(edge: .top) {
            // Add subtle top spacing for visual balance
            Spacer()
                .frame(height: 8)
        }
        .navigationTitle("Thoth")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { appState.showAbout = true }) {
                    Image(systemName: "info.circle")
                }
            }
        }
    }
}

#Preview {
    Sidebar()
        .environmentObject(AppState())
}
