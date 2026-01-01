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
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)
                
                Text("Anthropic API Key")
                    .font(.headline)
                
                Text("Required for AI-enhanced summaries")
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
                
                Text("Get your API key from console.anthropic.com")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
        }
    }
    
    private func saveKey() {
        do {
            try KeychainManager.shared.save(apiKey: apiKey, for: .anthropic)
            isKeyStored = true
            statusMessage = "API key saved successfully"
            showStatus = true
            apiKey = "" // Clear input for security
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
        } catch {
            statusMessage = "Failed to remove API key"
            showStatus = true
        }
    }
}

#Preview {
    APIKeyView()
}
