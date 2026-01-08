//
//  GlobalProgressBanner.swift
//  Thoth
//
//  Created by theway.ink on January 1, 2026.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI

// Note: The banner is now implemented directly in MainView using safeAreaInset
// This file is kept for reference and potential future use

struct GlobalProgressBanner: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        if appState.isExtracting, let progress = appState.currentProgress {
            HStack(spacing: 12) {
                // Progress indicator
                ProgressView()
                    .scaleEffect(0.8)
                
                // Status text
                Text("Working: \(appState.currentExtractionIndex + 1) of \(appState.validURLCount)")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                // Current article
                if let currentURL = appState.currentURL {
                    Text(currentURL.lastPathComponent.replacingOccurrences(of: "_", with: " "))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Text("•")
                    .foregroundColor(.secondary)
                
                // Time estimate
                if progress.estimatedTimeRemaining > 0 {
                    Text("~\(Int(progress.estimatedTimeRemaining))s remaining")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Cancel button
                Button(action: cancelExtraction) {
                    Text("Cancel")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.15))
            .background(.ultraThinMaterial)
        }
    }
    
    private func cancelExtraction() {
        appState.cancelExtraction()
    }
}

#Preview {
    GlobalProgressBanner()
        .environmentObject(AppState())
}
