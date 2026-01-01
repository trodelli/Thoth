//
//  SearchBar.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    let placeholder: String
    let matchCount: Int?
    let onPrevious: (() -> Void)?
    let onNext: (() -> Void)?
    
    init(
        searchText: Binding<String>,
        placeholder: String = "Search...",
        matchCount: Int? = nil,
        onPrevious: (() -> Void)? = nil,
        onNext: (() -> Void)? = nil
    ) {
        self._searchText = searchText
        self.placeholder = placeholder
        self.matchCount = matchCount
        self.onPrevious = onPrevious
        self.onNext = onNext
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(placeholder, text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            // Match count and navigation
            if let count = matchCount, !searchText.isEmpty {
                HStack(spacing: 4) {
                    Text("\(count) matches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if count > 0 {
                        Divider()
                            .frame(height: 16)
                        
                        Button(action: { onPrevious?() }) {
                            Image(systemName: "chevron.up")
                        }
                        .buttonStyle(.plain)
                        .disabled(count == 0)
                        
                        Button(action: { onNext?() }) {
                            Image(systemName: "chevron.down")
                        }
                        .buttonStyle(.plain)
                        .disabled(count == 0)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SearchBar(searchText: .constant(""))
        
        SearchBar(
            searchText: .constant("Confucius"),
            matchCount: 12,
            onPrevious: {},
            onNext: {}
        )
    }
    .padding()
}
