//
//  SearchDetailPanel.swift
//  Thoth
//
//  Created by theway.ink on January 21, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI

/// Detail panel shown when Search tab is active
struct SearchDetailPanel: View {
    @ObservedObject var viewModel: SearchViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - matches "Intelligent Article Discovery" styling
            panelHeader
            
            Divider()
            
            // Content area
            Group {
                if viewModel.isSearching {
                    // Segment D: Show placeholder during search (not duplicate progress)
                    searchingPlaceholder
                } else if let session = viewModel.currentSession {
                    sessionDetailView(session: session)
                } else {
                    idleStateView
                }
            }
        }
    }
    
    // MARK: - Header (Segment A: matches middle panel header)
    
    private var panelHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Intelligent Search Summary")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Search metrics, costs, and article preview")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
    }
    
    // MARK: - Idle State (No search yet)
    
    private var idleStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))
            
            VStack(spacing: 8) {
                Text("No Search Results")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Run a search to see metrics and preview articles")
                    .font(.subheadline)
                    .foregroundColor(.secondary.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Tips section
            VStack(alignment: .leading, spacing: 12) {
                Text("What you'll see here")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                VStack(alignment: .leading, spacing: 8) {
                    tipRow(icon: "chart.pie", text: "Search statistics and results count")
                    tipRow(icon: "dollarsign.circle", text: "API usage and cost breakdown")
                    tipRow(icon: "doc.text.magnifyingglass", text: "Article previews when selected")
                }
            }
            .padding(16)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
            .frame(maxWidth: 280)
            
            Spacer()
        }
        .padding(24)
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Searching Placeholder (no spinner, just text)
    
    private var searchingPlaceholder: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.4))
            
            VStack(spacing: 8) {
                Text("Search in Progress")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Results will appear here when complete")
                    .font(.subheadline)
                    .foregroundColor(.secondary.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(24)
    }
    
    // MARK: - Session Detail View
    
    private func sessionDetailView(session: SearchSession) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Session Summary
                sessionSummarySection(session: session)
                
                // API Usage & Cost
                apiUsageSection(session: session)
                
                // Selected Articles
                if session.selectedCount > 0 {
                    selectedArticlesSection(session: session)
                }
                
                // Article Preview
                if let previewArticle = viewModel.previewArticle {
                    articlePreviewSection(article: previewArticle)
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Session Summary Section
    
    private func sessionSummarySection(session: SearchSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with query
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.blue)
                
                Text("\"\(session.query)\"")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Spacer()
            }
            
            // Timing info
            HStack(spacing: 4) {
                Text("Started:")
                    .foregroundColor(.secondary)
                Text(formattedTime(session.timestamp))
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text("Duration:")
                    .foregroundColor(.secondary)
                Text(session.formattedDuration)
            }
            .font(.caption)
            
            // Stats row
            HStack(spacing: 12) {
                statCard(value: "\(session.loadedCount)", label: "Retrieved", color: .blue)
                statCard(value: "\(session.validatedCount)", label: "Validated", color: .green)
                statCard(value: "\(session.selectedCount)", label: "Selected", color: .purple)
            }
        }
        .padding(16)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - API Usage Section
    
    private func apiUsageSection(session: SearchSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dollarsign.circle")
                    .foregroundColor(.orange)
                
                Text("API Usage & Cost")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            // Total tokens used
            HStack {
                Text("Tokens Used")
                    .font(.subheadline)
                Spacer()
                Text("\(session.costTracker.totalTokens)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            // Token breakdown
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("Input: \(session.costTracker.totalInputTokens)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text("Output: \(session.costTracker.totalOutputTokens)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Cost breakdown
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Session Cost")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(session.costTracker.formattedTotalCost)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                // Individual entries
                ForEach(session.costTracker.entries) { entry in
                    HStack {
                        Text(entry.label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(String(format: "$%.4f", entry.cost))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Requests indicator
            if session.costTracker.requestCount > 0 {
                Divider()
                
                HStack {
                    Text("API Requests")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(session.costTracker.requestCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(16)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Selected Articles Section (Scrollable)
    
    private func selectedArticlesSection(session: SearchSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.purple)
                
                Text("Selected Articles")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(session.selectedCount)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.2))
                    .foregroundColor(.purple)
                    .cornerRadius(10)
            }
            
            // Scrollable list of all selected articles
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(session.selectedResults) { article in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            
                            Text(article.title)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
                        }
                    }
                }
            }
            .frame(maxHeight: 120) // Limit height to enable scrolling
            
            // Action button
            Button(action: {
                appState.pendingSearchURLs = viewModel.selectedURLs
                appState.selectedSection = .input
            }) {
                Label("Add \(session.selectedCount) to Input", systemImage: "plus.circle.fill")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(16)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Article Preview Section (Enhanced with Wikipedia data)
    
    private func articlePreviewSection(article: SearchResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and actions
            HStack {
                Text(article.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Spacer()
                
                Button(action: {
                    NSWorkspace.shared.open(article.url)
                }) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .help("Open in Wikipedia")
                
                Button(action: {
                    viewModel.clearPreview()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close preview")
            }
            
            Divider()
            
            // Loading or content
            if viewModel.isLoadingPreview {
                // Loading state
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading preview...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 8)
            } else if let previewData = viewModel.previewData {
                // Enhanced preview with Wikipedia data
                enhancedPreviewContent(data: previewData)
            } else {
                // Fallback: basic info from search result
                basicPreviewContent(article: article)
            }
        }
        .padding(16)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    /// Enhanced preview content with Wikipedia API data
    private func enhancedPreviewContent(data: ArticlePreviewData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Thumbnail + Extract
            HStack(alignment: .top, spacing: 12) {
                // Thumbnail (if available)
                if let thumbnailURL = data.thumbnail {
                    AsyncImage(url: thumbnailURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .cornerRadius(6)
                                .clipped()
                        case .failure(_):
                            thumbnailPlaceholder
                        case .empty:
                            thumbnailPlaceholder
                        @unknown default:
                            thumbnailPlaceholder
                        }
                    }
                }
                
                // Extract text
                Text(data.shortExtract)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(6)
            }
            
            // Categories
            if !data.displayCategories.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Categories")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    FlowLayout(spacing: 4) {
                        ForEach(data.displayCategories, id: \.self) { category in
                            Text(category)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // URL
            HStack(spacing: 4) {
                Image(systemName: "link")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(data.pageURL.absoluteString)
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }
        }
    }
    
    /// Basic preview content (fallback when Wikipedia data unavailable)
    private func basicPreviewContent(article: SearchResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !article.description.isEmpty {
                Text(article.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 4) {
                Image(systemName: "link")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(article.url.absoluteString)
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }
        }
    }
    
    /// Placeholder for missing thumbnail
    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.secondary.opacity(0.1))
            .frame(width: 60, height: 60)
            .overlay(
                Image(systemName: "photo")
                    .foregroundColor(.secondary.opacity(0.5))
            )
    }
}



// MARK: - Preview

struct SearchDetailPanel_Previews: PreviewProvider {
    static var previews: some View {
        SearchDetailPanel(viewModel: SearchViewModel())
            .environmentObject(AppState())
            .frame(width: 350, height: 600)
    }
}
