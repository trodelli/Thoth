//
//  InputView.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI

struct InputView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = InputViewModel()
    
    // Extraction engine
    private var extractionEngine: ExtractionEngine {
        ExtractionEngine(
            wikipediaService: appState.wikipediaService,
            wikipediaParser: appState.wikipediaParser
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wikipedia Article Extraction")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Enter Wikipedia URLs or article titles (one per line)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Examples: https://en.wikipedia.org/wiki/Confucius or just \"Confucius\"")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Recent Articles
                if !appState.recentURLs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.secondary)
                            Text("Recent")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(appState.recentURLs, id: \.self) { url in
                                    Button(action: {
                                        viewModel.addRecentURL(url)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.caption)
                                            Text(url.lastPathComponent.replacingOccurrences(of: "_", with: " "))
                                                .font(.caption)
                                                .lineLimit(1)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
                
                // URL Input
                TextEditor(text: $viewModel.urlInput)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .disabled(viewModel.isExtracting)
                
                // Validation Status
                HStack {
                    Button(action: viewModel.importFile) {
                        Label("Import File...", systemImage: "folder")
                    }
                    .disabled(viewModel.isExtracting)
                    
                    Spacer()
                    
                    validationStatus
                }
                
                Divider()
                
                // Options
                VStack(alignment: .leading, spacing: 16) {
                    Text("Extraction Options")
                        .font(.headline)
                    
                    // Summary Ratio
                    VStack(alignment: .leading, spacing: 4) {
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
                        .disabled(!appState.aiEnabled)
                        
                        Text(appState.aiEnabled
                             ? "AI will compress article to \(Int(appState.summaryRatio * 100))% of original length"
                             : "Enable AI to use intelligent summarization")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // AI Enhancement
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $appState.aiEnabled) {
                            HStack(spacing: 10) {
                                // AI-Enhanced badge (matching Search tab style)
                                HStack(spacing: 4) {
                                    Image(systemName: "brain")
                                        .font(.caption)
                                    Text("AI-Enhanced")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.purple.opacity(appState.aiEnabled ? 0.15 : 0.08))
                                .foregroundColor(appState.aiEnabled ? .purple : .secondary)
                                .cornerRadius(12)
                            }
                        }
                        .disabled(!KeychainManager.shared.hasAPIKey(for: .anthropic))
                        
                        Text("Uses Claude API for intelligent summaries, classification, and key fact extraction")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 2)
                        
                        if !KeychainManager.shared.hasAPIKey(for: .anthropic) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                
                                Text("API key required")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button("Add Key") {
                                    appState.showSettings = true
                                }
                                .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                // Progress
                if appState.isExtracting {
                    VStack(spacing: 12) {
                        // Overall progress
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Extracting \(appState.currentExtractionIndex + 1) of \(appState.validURLCount)")
                                    .font(.headline)
                                
                                Spacer()
                                
                                if appState.aiEnabled {
                                    HStack(spacing: 4) {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(.purple)
                                        Text("AI Active")
                                            .foregroundColor(.purple)
                                    }
                                    .font(.caption)
                                }
                            }
                            
                            ProgressView(
                                value: Double(appState.currentExtractionIndex),
                                total: Double(appState.validURLCount)
                            )
                        }
                        
                        // Detailed step progress
                        if let progress = appState.currentProgress {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(progress.allSteps, id: \.self) { step in
                                    HStack(spacing: 8) {
                                        Image(systemName: step.icon)
                                            .foregroundColor(stepColor(step, progress: progress))
                                            .frame(width: 20)
                                        
                                        Text(step.rawValue)
                                            .font(.caption)
                                            .foregroundColor(stepColor(step, progress: progress))
                                        
                                        Spacer()
                                        
                                        if progress.completedSteps.contains(step) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.caption)
                                        } else if progress.currentStep == step {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                        }
                                    }
                                }
                                
                                // Time estimate
                                if progress.estimatedTimeRemaining > 0 {
                                    HStack {
                                        Image(systemName: "clock")
                                            .font(.caption)
                                        Text("~\(Int(progress.estimatedTimeRemaining))s remaining")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                                }
                            }
                            .padding(12)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Cost estimate
                        if appState.aiEnabled, appState.currentProgress != nil {
                            HStack {
                                Image(systemName: "dollarsign.circle")
                                    .foregroundColor(.secondary)
                                Text("Estimated cost: ~$0.05-0.10 per article")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Extract Button
                HStack {
                    if appState.isExtracting {
                        Button("Cancel") {
                            viewModel.isExtracting = false
                            appState.isExtracting = false
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    
                    Spacer()
                    
                    Button(action: { Task { await extract() } }) {
                        HStack {
                            if appState.aiEnabled {
                                Image(systemName: "sparkles")
                            }
                            Text("Extract (\(viewModel.validURLs.count))")
                            Image(systemName: "play.fill")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.validURLs.isEmpty || appState.isExtracting)
                }
            }
            .padding(24)
        }
        .navigationTitle("Input")
        .onAppear {
            // Check for pending URLs from search
            consumePendingSearchURLs()
        }
        .onChange(of: appState.pendingSearchURLs) { oldURLs, newURLs in
            // Also handle if URLs are added while view is visible
            if !newURLs.isEmpty {
                consumePendingSearchURLs()
            }
        }
    }
    
    // MARK: - Consume Pending Search URLs
    
    private func consumePendingSearchURLs() {
        let pendingURLs = appState.consumePendingSearchURLs()
        if !pendingURLs.isEmpty {
            viewModel.addURLs(pendingURLs)
        }
    }
    
    @ViewBuilder
    private var validationStatus: some View {
        if viewModel.urlInput.isEmpty {
            Text("Enter Wikipedia URLs to begin")
                .foregroundColor(.secondary)
        } else if viewModel.validURLs.isEmpty {
            Label("No valid Wikipedia URLs found", systemImage: "exclamationmark.circle")
                .foregroundColor(.red)
        } else if !viewModel.invalidURLs.isEmpty {
            Label("\(viewModel.validURLs.count) valid, \(viewModel.invalidURLs.count) invalid", systemImage: "exclamationmark.triangle")
                .foregroundColor(.orange)
        } else {
            Label("\(viewModel.validURLs.count) valid URLs · Ready to extract", systemImage: "checkmark.circle")
                .foregroundColor(.green)
        }
    }
    
    private func extract() async {
        viewModel.isExtracting = true
        appState.isExtracting = true  // Enable global progress banner
        viewModel.currentExtractionIndex = 0
        
        // Track total URLs for progress banner
        appState.validURLCount = viewModel.validURLs.count
        
        for (index, url) in viewModel.validURLs.enumerated() {
            // Check both flags - if either is false, stop extraction
            guard viewModel.isExtracting && appState.isExtracting else { 
                appState.logger.info("Extraction cancelled by user")
                break 
            }
            
            viewModel.currentExtractionIndex = index
            
            // Update current URL for progress banner
            appState.currentURL = url
            appState.currentExtractionIndex = index
            
            // Start progress tracking
            appState.startProgress(aiEnabled: appState.aiEnabled)
            
            do {
                // Create extraction engine with progress callback
                let engine = ExtractionEngine(
                    wikipediaService: appState.wikipediaService,
                    wikipediaParser: appState.wikipediaParser
                )
                
                // Set progress callback
                engine.onProgressUpdate = { step in
                    Task { @MainActor in
                        // Complete previous step if it exists
                        if let currentStep = appState.currentProgress?.currentStep {
                            appState.completeProgress(step: currentStep)
                        }
                        // Start new step
                        appState.updateProgress(step: step)
                    }
                }
                
                // Extract
                let extraction = try await engine.extract(
                    url: url,
                    aiEnabled: appState.aiEnabled,
                    summaryRatio: appState.summaryRatio
                )
                
                // Mark final step as complete
                if let finalStep = appState.currentProgress?.currentStep {
                    appState.completeProgress(step: finalStep)
                }
                
                // Add to extractions
                appState.addExtraction(extraction)
                
                // Track cost
                if let tokens = extraction.metadata.tokensUsed {
                    appState.addCost(
                        inputTokens: tokens.inputTokens,
                        outputTokens: tokens.outputTokens
                    )
                }
                
                // Add to recent URLs
                appState.addRecentURL(url)
                
            } catch {
                appState.logger.error("Failed: \(url.lastPathComponent)", details: error.localizedDescription)
            }
            
            // Reset progress
            appState.resetProgress()
            
            // Rate limiting
            if index < viewModel.validURLs.count - 1 {
                try? await Task.sleep(nanoseconds: UInt64(appState.requestDelay * 1_000_000_000))
            }
        }
        
        viewModel.isExtracting = false
        appState.isExtracting = false  // Hide global progress banner
        viewModel.clear()
        
        // Show session cost summary
        if appState.sessionCost.extractions.count > 0 {
            appState.logger.success("Session complete! Total cost: \(appState.sessionCost.formattedTotalCost)")
        }
        
        // Switch to Extractions tab after ALL articles complete
        appState.selectedSection = .extractions
    }
    
    private func stepColor(_ step: ExtractionStep, progress: ExtractionProgress) -> Color {
        if progress.completedSteps.contains(step) {
            return .green
        } else if progress.currentStep == step {
            return .blue
        } else {
            return .secondary
        }
    }
}

#Preview {
    InputView()
        .environmentObject(AppState())
    
}
