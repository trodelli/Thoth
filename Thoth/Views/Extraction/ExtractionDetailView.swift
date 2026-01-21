//
//  ExtractionDetailView.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ExtractionDetailView: View {
    let extraction: ThothExtraction
    @EnvironmentObject var appState: AppState
    
    @State private var expandAll = true
    @State private var showCopyConfirmation = false
    @State private var copiedSection = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection
                
                Divider()
                
                // Search & Controls
                controlsSection
                
                Divider()
                
                // Content
                contentSections
            }
            .padding(24)
        }
        .navigationTitle(extraction.article.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: exportExtraction) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showCopyConfirmation {
                copyConfirmationToast
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportCurrent)) { _ in
            exportExtraction()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: extraction.article.type.icon)
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(extraction.article.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 8) {
                        Label("\(extraction.article.wordCount) words", systemImage: "doc.text")
                        Text("•")
                        Label(extraction.article.type.rawValue, systemImage: "tag")
                        
                        if extraction.metadata.aiEnhanced {
                            Text("•")
                            Label("AI Enhanced", systemImage: "sparkles")
                                .foregroundColor(.purple)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Source link
            Link(destination: extraction.metadata.sourceURL) {
                HStack {
                    Image(systemName: "link")
                    Text(extraction.metadata.sourceURL.absoluteString)
                        .lineLimit(1)
                }
                .font(.caption)
            }
            
            // Cost info (if AI enhanced)
            if let tokens = extraction.metadata.tokensUsed {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Cost: \(CostCalculator.shared.calculateCost(inputTokens: tokens.inputTokens, outputTokens: tokens.outputTokens).formattedCost)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(tokens.inputTokens.formatted()) in, \(tokens.outputTokens.formatted()) out")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        VStack(spacing: 12) {
            // Expand/Collapse all
            HStack {
                Button(action: { expandAll = true }) {
                    Label("Expand All", systemImage: "rectangle.expand.vertical")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: { expandAll = false }) {
                    Label("Collapse All", systemImage: "rectangle.compress.vertical")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Content Sections
    
    private var contentSections: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Summary
            CollapsibleSection(
                title: "Summary",
                subtitle: "\(extraction.article.summary.split(separator: " ").count) words",
                icon: "doc.text",
                isExpandedByDefault: expandAll
            ) {
                HStack(alignment: .top) {
                    Text(extraction.article.summary)
                        .textSelection(.enabled)
                    
                    Spacer()
                    
                    copyButton(for: "Summary", content: extraction.article.summary)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }
            
            // Alternate Names
            if !extraction.article.alternateNames.isEmpty {
                CollapsibleSection(
                    title: "Alternate Names",
                    subtitle: "\(extraction.article.alternateNames.count) names",
                    icon: "textformat",
                    isExpandedByDefault: expandAll
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(extraction.article.alternateNames, id: \.self) { name in
                            Text("• \(name)")
                                .textSelection(.enabled)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            
            // Key Facts
            if !extraction.classification.keyFacts.isEmpty {
                CollapsibleSection(
                    title: "Key Facts",
                    subtitle: "\(extraction.classification.keyFacts.count) facts",
                    icon: "list.bullet.rectangle",
                    isExpandedByDefault: expandAll
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(extraction.classification.keyFacts, id: \.key) { fact in
                            HStack(alignment: .top) {
                                Text("**\(fact.key):**")
                                    .frame(width: 150, alignment: .leading)
                                Text(fact.value)
                                    .textSelection(.enabled)
                            }
                            .font(.body)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            
            // Important Dates
            if !extraction.temporalContext.dates.isEmpty {
                CollapsibleSection(
                    title: "Important Dates",
                    subtitle: "\(extraction.temporalContext.dates.count) dates",
                    icon: "calendar",
                    isExpandedByDefault: expandAll
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(extraction.temporalContext.dates, id: \.event) { date in
                            HStack(alignment: .top) {
                                Text("**\(date.date):**")
                                    .frame(width: 120, alignment: .leading)
                                Text(date.event)
                                    .textSelection(.enabled)
                            }
                            .font(.body)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            
            // Locations
            if !extraction.geographicContext.locations.isEmpty {
                CollapsibleSection(
                    title: "Locations",
                    subtitle: "\(extraction.geographicContext.locations.count) locations",
                    icon: "map",
                    isExpandedByDefault: expandAll
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(extraction.geographicContext.locations, id: \.name) { location in
                            HStack(alignment: .top) {
                                Text("**\(location.name)**")
                                    .frame(width: 150, alignment: .leading)
                                Text("(\(location.type.rawValue))")
                                    .foregroundColor(.secondary)
                                if let modern = location.modernName {
                                    Text("→ \(modern)")
                                        .textSelection(.enabled)
                                }
                            }
                            .font(.body)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            
            // Infobox
            if let infobox = extraction.structuredContent.infobox {
                CollapsibleSection(
                    title: "Infobox",
                    subtitle: infobox.type ?? "Data",
                    icon: "tablecells",
                    isExpandedByDefault: expandAll
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(infobox.fields, id: \.key) { field in
                            HStack(alignment: .top) {
                                Text("**\(field.key):**")
                                    .frame(width: 150, alignment: .leading)
                                Text(field.value)
                                    .textSelection(.enabled)
                            }
                            .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            
            // Tables
            if !extraction.structuredContent.tables.isEmpty {
                CollapsibleSection(
                    title: "Tables",
                    subtitle: "\(extraction.structuredContent.tables.count) tables",
                    icon: "tablecells.fill",
                    isExpandedByDefault: expandAll
                ) {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(extraction.structuredContent.tables.enumerated()), id: \.offset) { index, table in
                            TableRenderer(table: table)
                        }
                    }
                }
            }
            
            // Article Sections
            if !extraction.structuredContent.sections.isEmpty {
                CollapsibleSection(
                    title: "Article Sections",
                    subtitle: "\(extraction.structuredContent.sections.count) sections",
                    icon: "doc.plaintext",
                    isExpandedByDefault: expandAll
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(extraction.structuredContent.sections, id: \.title) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(section.title)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text("(\(section.wordCount) words)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    copyButton(for: section.title, content: section.content)
                                }
                                
                                Text(section.content)
                                    .textSelection(.enabled)
                                    .font(.body)
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Categories
            if !extraction.classification.categories.isEmpty {
                CollapsibleSection(
                    title: "Categories",
                    subtitle: "\(extraction.classification.categories.count) categories",
                    icon: "tag.fill",
                    isExpandedByDefault: expandAll
                ) {
                    FlowLayout(spacing: 8) {
                        ForEach(extraction.classification.categories, id: \.self) { category in
                            Text(category)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                        }
                    }
                }
            }
            
            // Related Topics
            if !extraction.classification.relatedTopics.isEmpty {
                CollapsibleSection(
                    title: "Related Topics",
                    subtitle: "\(extraction.classification.relatedTopics.count) topics",
                    icon: "link",
                    isExpandedByDefault: expandAll
                ) {
                    FlowLayout(spacing: 8) {
                        ForEach(extraction.classification.relatedTopics, id: \.self) { topic in
                            Text(topic)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Copy Button
    
    private func copyButton(for section: String, content: String) -> some View {
        Button(action: {
            copyToClipboard(content)
            copiedSection = section
            showCopyConfirmation = true
            
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                showCopyConfirmation = false
            }
        }) {
            Image(systemName: "doc.on.doc")
                .foregroundColor(.blue)
        }
        .buttonStyle(.plain)
        .help("Copy \(section)")
    }
    
    private var copyConfirmationToast: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Copied \(copiedSection)")
                .font(.body)
        }
        .padding()
        .background(Color.green.opacity(0.2))
        .cornerRadius(8)
        .padding(.bottom, 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut, value: showCopyConfirmation)
    }
    
    // MARK: - Helpers
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func exportExtraction() {
        // Convert the string export format to the enum
        guard let format = ExportFormat(rawValue: appState.exportFormat) else {
            appState.logger.error("Invalid export format", details: appState.exportFormat)
            return
        }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: format.fileExtension)!]
        panel.nameFieldStringValue = "\(extraction.article.title).\(format.fileExtension)"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            do {
                switch format {
                case .markdown:
                    try self.appState.exportService.exportMarkdown(extraction, to: url)
                case .json:
                    try self.appState.exportService.exportJSON(extraction, to: url)
                case .both:
                    // Export both formats
                    let mdURL = url.deletingPathExtension().appendingPathExtension("md")
                    let jsonURL = url.deletingPathExtension().appendingPathExtension("json")
                    try self.appState.exportService.exportMarkdown(extraction, to: mdURL)
                    try self.appState.exportService.exportJSON(extraction, to: jsonURL)
                }
            } catch {
                self.appState.logger.error("Export failed", details: error.localizedDescription)
            }
        }
    }
    
}

// MARK: - Flow Layout (for tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    NavigationSplitView {
        Text("Sidebar")
    } detail: {
        if let extraction = PreviewData.sampleExtraction {
            ExtractionDetailView(extraction: extraction)
                .environmentObject(AppState())
        }
    }
}

// MARK: - Preview Data

struct PreviewData {
    static var sampleExtraction: ThothExtraction? {
        // Create a sample extraction for preview
        return nil // Implement if needed for preview
    }
}

