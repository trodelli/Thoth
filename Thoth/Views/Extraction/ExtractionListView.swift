//
//  ExtractionListView.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExtractionListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingExportMenu = false
    @State private var showingSessionExportOptions = false
    @State private var selectedSessionFormat: ExportFormat = .markdown
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Extractions")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("(\(appState.extractions.count))")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Sort Toggle
                if !appState.extractions.isEmpty {
                    Button(action: { appState.sortOldestFirst.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: appState.sortOldestFirst ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            Text(appState.sortOldestFirst ? "Oldest" : "Newest")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help(appState.sortOldestFirst ? "Sorted: Oldest first" : "Sorted: Newest first")
                }
                
                // Export Menu
                if !appState.extractions.isEmpty {
                    Menu {
                        Button(action: { showingSessionExportOptions = true }) {
                            Label("Export All to Single File...", systemImage: "doc.on.doc")
                        }
                        
                        Button(action: exportAllToFolder) {
                            Label("Export All to Folder...", systemImage: "folder")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: appState.clearExtractions) {
                            Label("Clear All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                    .menuStyle(.borderlessButton)
                }
            }
            .padding()
            
            Divider()
            
            // List
            if appState.extractions.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "No Extractions",
                    message: "Extracted articles will appear here"
                )
            } else {
                List(appState.sortedExtractions, id: \.metadata.extractedAt, selection: $appState.selectedExtraction) { extraction in
                    ExtractionRowView(extraction: extraction)
                        .tag(extraction)
                        .contextMenu {
                            Button(action: { exportSingle(extraction) }) {
                                Label("Export...", systemImage: "square.and.arrow.up")
                            }
                            
                            Button(role: .destructive, action: { appState.removeExtraction(extraction) }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .listStyle(.sidebar)
            }
            
            // Session Cost Summary
            if appState.sessionCost.extractions.count > 0 {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("Session Cost")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(appState.sessionCost.formattedTotalCost)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("\(appState.sessionCost.totalInputTokens.formatted()) in • \(appState.sessionCost.totalOutputTokens.formatted()) out")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Reset") {
                            appState.resetSessionCost()
                        }
                        .font(.caption2)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
            }
        }
        .navigationTitle("Extractions")
        .sheet(isPresented: $showingSessionExportOptions) {
            sessionExportSheet
        }
        
        .onReceive(NotificationCenter.default.publisher(for: .exportAllToFolder)) { _ in
            exportAllToFolder()
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportSession)) { _ in
            showingSessionExportOptions = true
        }
    }
    
    // MARK: - Session Export Sheet
    
    private var sessionExportSheet: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Export Session")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingSessionExportOptions = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text("Export all \(appState.extractions.count) extractions to a single file")
                    .font(.body)
                
                Text("All articles will be combined in sequence with separators")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Format Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Format")
                    .font(.headline)
                
                Picker("Format", selection: $selectedSessionFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Spacer()
            
            // Export Button
            Button(action: exportSessionToSingleFile) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export to Single File")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(width: 400, height: 300)
    }
    
    // MARK: - Export Functions
    
    private func exportSingle(_ extraction: ThothExtraction) {
        let format = ExportFormat(rawValue: appState.exportFormat) ?? .markdown
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: format.fileExtension)!]
        panel.nameFieldStringValue = "\(extraction.article.title).\(format.fileExtension)"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            do {
                switch format {
                case .markdown:
                    try appState.exportService.exportMarkdown(extraction, to: url)
                case .json:
                    try appState.exportService.exportJSON(extraction, to: url)
                case .both:
                    // Export both formats with different extensions
                    let mdURL = url.deletingPathExtension().appendingPathExtension("md")
                    let jsonURL = url.deletingPathExtension().appendingPathExtension("json")
                    try appState.exportService.exportMarkdown(extraction, to: mdURL)
                    try appState.exportService.exportJSON(extraction, to: jsonURL)
                }
            } catch {
                appState.logger.error("Export failed", details: error.localizedDescription)
            }
        }
    }
    
    private func exportAllToFolder() {
        let format = ExportFormat(rawValue: appState.exportFormat) ?? .markdown
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Export Here"
        panel.message = "Choose a folder to export all extractions"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            do {
                let exportedURLs = try appState.exportService.exportBatch(
                    appState.sortedExtractions,
                    to: url,
                    format: format
                )
                appState.logger.success("Exported \(exportedURLs.count) files to \(url.lastPathComponent)")
            } catch {
                appState.logger.error("Batch export failed", details: error.localizedDescription)
            }
        }
    }
    
    private func exportSessionToSingleFile() {
        showingSessionExportOptions = false
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: selectedSessionFormat.fileExtension)!]
        panel.nameFieldStringValue = selectedSessionFormat.defaultFilename
        panel.prompt = "Export Session"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            do {
                try appState.exportService.sessionExport(
                    extractions: appState.sortedExtractions,
                    to: url,
                    format: selectedSessionFormat
                )
                appState.logger.success("Session exported: \(url.lastPathComponent)")
            } catch {
                appState.logger.error("Session export failed", details: error.localizedDescription)
            }
        }
    }
}

// MARK: - Extraction Row

struct ExtractionRowView: View {
    let extraction: ThothExtraction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Article type icon
                Image(systemName: extraction.article.type.icon)
                    .foregroundColor(.blue)
                
                Text(extraction.article.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
                
                // AI badge
                if extraction.metadata.aiEnhanced {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                        .font(.caption)
                }
            }
            
            HStack {
                Text("\(extraction.article.wordCount) words")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text(extraction.article.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let tokens = extraction.metadata.tokensUsed {
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(CostCalculator.shared.calculateCost(
                        inputTokens: tokens.inputTokens,
                        outputTokens: tokens.outputTokens
                    ).formattedCost)
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ExtractionListView()
        .environmentObject(AppState())
}
