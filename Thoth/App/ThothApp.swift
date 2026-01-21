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
                .sheet(isPresented: $appState.showWelcomeWizard) {
                    WelcomeWizardView()
                        .environmentObject(appState)
                        .interactiveDismissDisabled() // Prevent accidental dismiss
                }
                .onAppear {
                    // Show Welcome Wizard on first launch
                    if !appState.hasCompletedOnboarding {
                        appState.showWelcomeWizard = true
                    }
                }
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1400, height: 900)
        .commands {
            // Replace default About menu item
            CommandGroup(replacing: .appInfo) {
                Button("About \(AppConstants.appName)") {
                    AboutWindowController.shared.show()
                }
            }
            
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
            
            // Help menu
            CommandGroup(replacing: .help) {
                Button("Show Welcome Tour") {
                    appState.showWelcomeWizard = true
                }
            }
        }
    }
}

// MARK: - About Window Controller

final class AboutWindowController {
    static let shared = AboutWindowController()
    private var aboutWindow: NSWindow?
    
    func show() {
        // If window exists and is visible, just bring it to front
        if let window = aboutWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create the SwiftUI view and host it
        let aboutView = AboutView()
        let hostingController = NSHostingController(rootView: aboutView)
        
        // Create window with appropriate style
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.contentViewController = hostingController
        window.title = "About \(AppConstants.appName)"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        aboutWindow = window
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let exportCurrent = Notification.Name("exportCurrent")
    static let exportAllToFolder = Notification.Name("exportAllToFolder")
    static let exportSession = Notification.Name("exportSession")
}
