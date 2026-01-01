//
//  SettingsView.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .help("Close Settings")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
            
            // Tab View
            TabView {
                GeneralSettingsView()
                    .environmentObject(appState)
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }
                
                APIKeyView()
                    .tabItem {
                        Label("API Keys", systemImage: "key")
                    }
                
                AboutView()
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
            }
            .padding(.top, 8)
        }
        .frame(width: 600, height: 500)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox("Extraction") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Summary ratio")
                            Spacer()
                            Text("\(Int(appState.summaryRatio * 100))%")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: $appState.summaryRatio,
                            in: AppConstants.Defaults.minSummaryRatio...AppConstants.Defaults.maxSummaryRatio
                        )
                        
                        Text("Target percentage of original article length")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                }
                
                GroupBox("Rate Limiting") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Request delay")
                            Spacer()
                            Text("\(String(format: "%.1f", appState.requestDelay))s")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: $appState.requestDelay,
                            in: 0.5...5.0
                        )
                        
                        Text("Delay between requests to respect Wikipedia's servers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                }
                
                GroupBox("Export") {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Default format", selection: $appState.exportFormat) {
                            ForEach([ExportFormat.markdown, ExportFormat.json, ExportFormat.both], id: \.rawValue) { format in
                                Text(format.rawValue).tag(format.rawValue)
                            }
                        }
                    }
                    .padding(8)
                }
            }
            .padding()
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Thoth")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version \(AppConstants.appVersion)")
                .foregroundColor(.secondary)
            
            Text("Wikipedia Knowledge Extraction")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.horizontal, 40)
            
            VStack(spacing: 8) {
                Text("Created by \(AppConstants.creatorName)")
                    .font(.caption)
                
                Link(AppConstants.creatorURL.absoluteString, destination: AppConstants.creatorURL)
                    .font(.caption)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
