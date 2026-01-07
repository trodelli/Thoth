//
//  AboutView.swift
//  Thoth
//
//  Created by theway.ink on January 7, 2026.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            // App Icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 128, height: 128)
            
            // App Name & Version
            VStack(spacing: 4) {
                Text(AppConstants.appName)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Version \(AppConstants.appVersion) (\(AppConstants.buildNumber))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(width: 360)
            
            // Description
            Text("Thoth transforms Wikipedia articles into structured, intelligent extractions. Powered by Claude AI, it analyzes articles to generate concise summaries, classify content types, and extract key facts, important dates, and geographic locations. Whether you're researching history, science, or culture, Thoth captures the essence of any Wikipedia article and exports it in Markdown or JSON format for your knowledge base, research projects, or personal archives.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(width: 400)
                .fixedSize(horizontal: false, vertical: true)
            
            Divider()
                .frame(width: 360)
            
            // Attribution
            Text("DESIGNED BY THEWAY.INK  |  BUILT WITH AI  |  MADE IN MARSEILLE")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .tracking(0.3)
            
            Spacer()
                .frame(height: 8)
        }
        .padding(32)
        .frame(width: 480, height: 480)
    }
}

#Preview {
    AboutView()
}
