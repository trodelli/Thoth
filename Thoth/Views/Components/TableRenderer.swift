//
//  TableRenderer.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI

struct TableRenderer: View {
    let table: Table
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(table.title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if let description = table.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Table
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    // Headers
                    if !table.headers.isEmpty {
                        HStack(spacing: 0) {
                            ForEach(Array(table.headers.enumerated()), id: \.offset) { index, header in
                                Text(header)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(8)
                                    .frame(minWidth: 120, alignment: .leading)
                                    .background(Color(nsColor: .controlBackgroundColor))
                                
                                if index < table.headers.count - 1 {
                                    Divider()
                                }
                            }
                        }
                        
                        Divider()
                    }
                    
                    // Rows
                    ForEach(Array(table.rows.enumerated()), id: \.offset) { rowIndex, row in
                        HStack(spacing: 0) {
                            ForEach(Array(row.enumerated()), id: \.offset) { cellIndex, cell in
                                Text(cell)
                                    .font(.caption)
                                    .padding(8)
                                    .frame(minWidth: 120, alignment: .leading)
                                    .textSelection(.enabled)
                                
                                if cellIndex < row.count - 1 {
                                    Divider()
                                }
                            }
                        }
                        
                        if rowIndex < table.rows.count - 1 {
                            Divider()
                        }
                    }
                }
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
            
            // Footer
            HStack {
                Text("\(table.rowCount) rows")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if table.truncated {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("Truncated (showing first \(table.rows.count))")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}

#Preview {
    let table = Table(
        id: "test",
        title: "Test Table",
        headers: ["Name", "Value", "Description"],
        rows: [
            ["Item 1", "100", "First item"],
            ["Item 2", "200", "Second item"],
            ["Item 3", "300", "Third item"]
        ],
        rowCount: 3,
        truncated: false
    )
    
    return TableRenderer(table: table)
        .padding()
}
