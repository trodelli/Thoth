//
//  CollapsibleSection.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI

struct CollapsibleSection<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let isExpandedByDefault: Bool
    let content: () -> Content
    
    @State private var isExpanded: Bool
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        isExpandedByDefault: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isExpandedByDefault = isExpandedByDefault
        self.content = content
        self._isExpanded = State(initialValue: isExpandedByDefault)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                            .foregroundColor(.blue)
                            .frame(width: 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
            
            // Content
            if isExpanded {
                content()
                    .padding(.leading, icon != nil ? 28 : 0)
                    .padding(.top, 8)
            }
        }
        .onChange(of: isExpandedByDefault) { _, newValue in
            // Defer state change to avoid "Publishing changes from within view updates" warning
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded = newValue
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        CollapsibleSection(
            title: "Summary",
            subtitle: "1,126 words",
            icon: "doc.text"
        ) {
            Text("This is the summary content...")
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
        }
        
        CollapsibleSection(
            title: "Key Facts",
            subtitle: "10 facts",
            icon: "list.bullet",
            isExpandedByDefault: false
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text("• Fact 1")
                Text("• Fact 2")
                Text("• Fact 3")
            }
        }
    }
    .padding()
}
