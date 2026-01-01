//
//  ThothApp.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI

@main
struct ThothApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1400, height: 900)
        .commands {
            // File menu commands
            CommandGroup(replacing: .newItem) {
                Button("New Extraction") {
                    appState.selectedSection = .input
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            // Custom commands
            CommandGroup(after: .sidebar) {
                Divider()
                
                Button("Show Input") {
                    appState.selectedSection = .input
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Show Extractions") {
                    appState.selectedSection = .extractions
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Button("Show Activity Log") {
                    appState.selectedSection = .logs
                }
                .keyboardShortcut("3", modifiers: .command)
                
                Divider()
                
                Button("Settings...") {
                    appState.showSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            
            // Export commands
            CommandGroup(after: .importExport) {
                Button("Export Current...") {
                    // Trigger export for selected extraction
                    if appState.selectedExtraction != nil {
                        NotificationCenter.default.post(name: .exportCurrent, object: nil)
                    }
                }
                .keyboardShortcut("e", modifiers: .command)
                .disabled(appState.selectedExtraction == nil)
                
                Button("Export All to Folder...") {
                    NotificationCenter.default.post(name: .exportAllToFolder, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(appState.extractions.isEmpty)
                
                Button("Export Session to File...") {
                    NotificationCenter.default.post(name: .exportSession, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .option])
                .disabled(appState.extractions.isEmpty)
            }
            
            // View commands
            CommandGroup(after: .toolbar) {
                Button("Clear All Extractions") {
                    appState.clearExtractions()
                }
                .keyboardShortcut("k", modifiers: .command)
                .disabled(appState.extractions.isEmpty)
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let exportCurrent = Notification.Name("exportCurrent")
    static let exportAllToFolder = Notification.Name("exportAllToFolder")
    static let exportSession = Notification.Name("exportSession")
}
