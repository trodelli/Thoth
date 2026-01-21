//
//  APIKeyView.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI

struct APIKeyView: View {
    @State private var apiKey: String = ""
    @State private var isKeyStored: Bool = false
    @State private var showingKey: Bool = false
    @State private var statusMessage: String = ""
    @State private var showStatus: Bool = false
    
    // Connection validation state
    @State private var connectionStatus: ConnectionStatus = .unknown
    @State private var isValidating: Bool = false
    
    enum ConnectionStatus {
        case unknown
        case checking
        case connected
        case failed(String)
        
        var icon: String {
            switch self {
            case .unknown: return "questionmark.circle"
            case .checking: return "arrow.clockwise.circle"
            case .connected: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .unknown: return .secondary
            case .checking: return .blue
            case .connected: return .green
            case .failed: return .red
            }
        }
        
        var message: String {
            switch self {
            case .unknown: return "Not verified"
            case .checking: return "Checking connection..."
            case .connected: return "Connected to Claude API"
            case .failed(let error): return error
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)
                
                Text("Anthropic API Key")
                    .font(.headline)
                
                Text("Required for AI-enhanced summaries and intelligent search")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // API Key Input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if showingKey {
                        TextField("sk-ant-...", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    } else {
                        SecureField("sk-ant-...", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    Button(action: { showingKey.toggle() }) {
                        Image(systemName: showingKey ? "eye.slash" : "eye")
                    }
                }
                
                HStack(spacing: 4) {
                    Text("Get your API key from")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Link(destination: URL(string: "https://console.anthropic.com/settings/keys")!) {
                        HStack(spacing: 2) {
                            Text("Anthropic Console")
                                .font(.caption)
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption2)
                        }
                    }
                    .help("Open Anthropic Console in browser")
                }
            }
            
            // Status
            if showStatus {
                HStack {
                    Image(systemName: isKeyStored ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(isKeyStored ? .green : .red)
                    
                    Text(statusMessage)
                        .font(.caption)
                }
            }
            
            // Buttons
            HStack {
                if isKeyStored {
                    Button("Remove Key", role: .destructive, action: removeKey)
                        .buttonStyle(.bordered)
                }
                
                Spacer()
                
                Button("Save Key", action: saveKey)
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.isEmpty)
            }
            
            Divider()
            
            // Connection Status Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Connection Status")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    // Status indicator
                    ZStack {
                        Circle()
                            .fill(connectionStatus.color.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        if case .checking = connectionStatus {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: connectionStatus.icon)
                                .font(.title2)
                                .foregroundColor(connectionStatus.color)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(connectionStatus.message)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if case .connected = connectionStatus {
                            Text("Your API key is working correctly")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if case .failed = connectionStatus {
                            Text("Check your API key and try again")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Test Connection Button
                    Button(action: testConnection) {
                        HStack(spacing: 4) {
                            if isValidating {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Test")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!isKeyStored || isValidating)
                }
                .padding(12)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .onAppear(perform: checkForStoredKey)
    }
    
    private func checkForStoredKey() {
        isKeyStored = KeychainManager.shared.hasAPIKey(for: .anthropic)
        if isKeyStored {
            statusMessage = "API key is stored securely"
            showStatus = true
            // Auto-test connection on appear if key exists
            Task {
                await testConnectionAsync()
            }
        }
    }
    
    private func saveKey() {
        do {
            try KeychainManager.shared.save(apiKey: apiKey, for: .anthropic)
            isKeyStored = true
            statusMessage = "API key saved successfully"
            showStatus = true
            apiKey = "" // Clear input for security
            
            // Test the new key
            Task {
                await testConnectionAsync()
            }
        } catch {
            statusMessage = "Failed to save API key"
            showStatus = true
        }
    }
    
    private func removeKey() {
        do {
            try KeychainManager.shared.delete(for: .anthropic)
            isKeyStored = false
            statusMessage = "API key removed"
            showStatus = true
            apiKey = ""
            connectionStatus = .unknown
        } catch {
            statusMessage = "Failed to remove API key"
            showStatus = true
        }
    }
    
    private func testConnection() {
        Task {
            await testConnectionAsync()
        }
    }
    
    @MainActor
    private func testConnectionAsync() async {
        guard isKeyStored else {
            connectionStatus = .failed("No API key configured")
            return
        }
        
        connectionStatus = .checking
        isValidating = true
        
        let claudeService = ClaudeService()
        let (isValid, error) = await claudeService.validateAPIKey()
        
        if isValid {
            connectionStatus = .connected
        } else {
            connectionStatus = .failed(error ?? "Connection failed")
        }
        
        isValidating = false
    }
}

#Preview {
    APIKeyView()
}
