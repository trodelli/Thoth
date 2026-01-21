//
//  WelcomeSlideView.swift
//  Thoth
//
//  Created by theway.ink on January 21, 2026.
//  Copyright © 2026 theway.ink. All rights reserved.
//

import SwiftUI

/// Reusable view component for rendering a single Welcome Wizard slide
struct WelcomeSlideView: View {
    let slide: WelcomeSlideData
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            iconView
            
            // Title & Subtitle
            titleSection
            
            // Description
            descriptionSection
            
            // Bullet Points (if present)
            if let bullets = slide.bulletPoints, !bullets.isEmpty {
                bulletPointsSection(bullets)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Icon
    
    private var iconView: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(slide.iconColor.opacity(0.15))
                .frame(width: 100, height: 100)
            
            // Icon
            Image(systemName: slide.icon)
                .font(.system(size: 44))
                .foregroundColor(slide.iconColor)
        }
        .accessibilityHidden(true)
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text(slide.title)
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(slide.subtitle)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        Text(slide.description)
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Bullet Points Section
    
    private func bulletPointsSection(_ bullets: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(bullets, id: \.self) { bullet in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.callout)
                        .foregroundColor(slide.iconColor)
                        .frame(width: 20)
                    
                    Text(bullet)
                        .font(.callout)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}

// MARK: - Preview

#Preview("Slide 1 - Welcome") {
    WelcomeSlideView(slide: .slide1Welcome)
        .frame(width: 520, height: 400)
}

#Preview("Slide 2 - Discover (with bullets)") {
    WelcomeSlideView(slide: .slide2Discover)
        .frame(width: 520, height: 400)
}

#Preview("Slide 6 - Get Started") {
    WelcomeSlideView(slide: .slide6GetStarted)
        .frame(width: 520, height: 400)
}
