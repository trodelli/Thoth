//
//  LogView.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI

struct LogView: View {
    @ObservedObject var logger = Logger.shared
    @State private var selectedLevels: Set<LogLevel> = Set(LogLevel.allCases)
    
    var filteredEntries: [LogEntry] {
        logger.entries.filter { selectedLevels.contains($0.level) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(filteredEntries.count) Log Entries")
                    .font(.headline)
                
                Spacer()
                
                // Filter
                Menu {
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Toggle(isOn: Binding(
                            get: { selectedLevels.contains(level) },
                            set: { isOn in
                                if isOn {
                                    selectedLevels.insert(level)
                                } else {
                                    selectedLevels.remove(level)
                                }
                            }
                        )) {
                            Label(level.rawValue, systemImage: iconForLevel(level))
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                
                Button(action: logger.clear) {
                    Image(systemName: "trash")
                }
                .disabled(logger.entries.isEmpty)
            }
            .padding()
            
            Divider()
            
            // Logs
            if filteredEntries.isEmpty {
                EmptyStateView(
                    icon: "list.bullet.rectangle",
                    title: "No Log Entries",
                    message: "Activity will appear here as you use the app"
                )
            } else {
                List(filteredEntries) { entry in
                    LogEntryRow(entry: entry)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Activity Log")
    }
    
    private func iconForLevel(_ level: LogLevel) -> String {
        switch level {
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        }
    }
}

struct LogEntryRow: View {
    let entry: LogEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: iconForLevel)
                .foregroundColor(colorForLevel)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.message)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(formatTime(entry.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let details = entry.details {
                    Text(details)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var iconForLevel: String {
        switch entry.level {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
    
    private var colorForLevel: Color {
        switch entry.level {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

#Preview {
    LogView()
}
