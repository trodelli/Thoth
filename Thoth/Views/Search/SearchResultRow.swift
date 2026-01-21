//
//  SearchResultRow.swift
//  Thoth
//
//  Created by theway.ink on January 21, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI

struct SearchResultRow: View {
    let result: SearchResult
    let isDuplicate: Bool
    let isPreviewActive: Bool
    let onToggle: () -> Void
    let onOpenInBrowser: () -> Void
    let onPreview: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox (also clickable, but whole row works too)
            Image(systemName: result.isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(result.isSelected ? .blue : .secondary)
                .padding(.top, 2)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    // Title
                    Text(result.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Duplicate badge
                    if isDuplicate {
                        Text("In Queue")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }
                
                // Description
                if !result.description.isEmpty {
                    Text(result.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                // Preview button
                Button(action: {
                    onPreview()
                }) {
                    Image(systemName: isPreviewActive ? "eye.fill" : "eye")
                        .font(.body)
                        .foregroundColor(isPreviewActive ? .blue : (isHovering ? .primary : .secondary))
                }
                .buttonStyle(.plain)
                .help("Preview article")
                
                // Open in browser button
                Button(action: onOpenInBrowser) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.body)
                        .foregroundColor(isHovering ? .blue : .secondary)
                }
                .buttonStyle(.plain)
                .help("Open in Wikipedia")
            }
            .opacity(isHovering || isPreviewActive ? 1 : 0.5)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
        .contentShape(Rectangle()) // Makes entire row clickable
        .onTapGesture {
            // Click anywhere on row to toggle selection
            onToggle()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
    
    private var backgroundColor: Color {
        if isPreviewActive {
            return Color.blue.opacity(0.1)
        } else if isHovering {
            return Color.secondary.opacity(0.08)
        }
        return Color.clear
    }
}

// MARK: - Preview

struct SearchResultRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            SearchResultRow(
                result: SearchResult(
                    title: "Ancient Rome",
                    url: URL(string: "https://en.wikipedia.org/wiki/Ancient_Rome")!,
                    description: "Ancient Rome was a civilization that began as a city-state in central Italy.",
                    isSelected: true
                ),
                isDuplicate: false,
                isPreviewActive: true,
                onToggle: {},
                onOpenInBrowser: {},
                onPreview: {}
            )
            
            Divider()
            
            SearchResultRow(
                result: SearchResult(
                    title: "Roman Republic",
                    url: URL(string: "https://en.wikipedia.org/wiki/Roman_Republic")!,
                    description: "The Roman Republic was the era of classical Roman civilization.",
                    isSelected: false
                ),
                isDuplicate: true,
                isPreviewActive: false,
                onToggle: {},
                onOpenInBrowser: {},
                onPreview: {}
            )
        }
        .padding()
        .frame(width: 500)
    }
}
