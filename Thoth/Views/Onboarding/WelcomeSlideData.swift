//
//  WelcomeSlideData.swift
//  Thoth
//
//  Created by theway.ink on January 21, 2026.
//  Copyright © 2026 theway.ink. All rights reserved.
//

import SwiftUI

/// Model representing a single slide in the Welcome Wizard
struct WelcomeSlideData: Identifiable {
    let id: Int
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
    let bulletPoints: [String]?
    
    init(
        id: Int,
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        description: String,
        bulletPoints: [String]? = nil
    ) {
        self.id = id
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.bulletPoints = bulletPoints
    }
}

// MARK: - Slide Content

extension WelcomeSlideData {
    
    /// All slides for the Welcome Wizard
    static let allSlides: [WelcomeSlideData] = [
        slide1Welcome,
        slide2Discover,
        slide3Input,
        slide4AIEnhanced,
        slide5Export,
        slide6GetStarted
    ]
    
    // MARK: Slide 1 - Welcome
    
    static let slide1Welcome = WelcomeSlideData(
        id: 1,
        icon: "book.pages",
        iconColor: .blue,
        title: "Welcome to Thoth",
        subtitle: "Transform Wikipedia into structured knowledge",
        description: "Thoth extracts, enhances, and exports Wikipedia articles into clean, structured formats ready for research, note-taking, or AI training datasets."
    )
    
    // MARK: Slide 2 - Discover
    
    static let slide2Discover = WelcomeSlideData(
        id: 2,
        icon: "magnifyingglass",
        iconColor: .purple,
        title: "Discover Articles",
        subtitle: "AI-powered search",
        description: "Use Claude AI to find relevant Wikipedia articles by keyword or rich description. Search for \"ancient Rome\" or describe exactly what you're looking for.",
        bulletPoints: [
            "Keyword and natural language search",
            "AI-curated article suggestions",
            "Batch discovery of related topics"
        ]
    )
    
    // MARK: Slide 3 - Input
    
    static let slide3Input = WelcomeSlideData(
        id: 3,
        icon: "square.and.arrow.down",
        iconColor: .green,
        title: "Add Articles",
        subtitle: "Flexible input methods",
        description: "Add Wikipedia articles by pasting URLs, importing text files, or using results from the Search tab.",
        bulletPoints: [
            "Paste single or multiple URLs",
            "Import from .txt files",
            "Process up to 200 articles in batch"
        ]
    )
    
    // MARK: Slide 4 - AI Enhanced
    
    static let slide4AIEnhanced = WelcomeSlideData(
        id: 4,
        icon: "sparkles",
        iconColor: .purple,
        title: "AI-Enhanced Extraction",
        subtitle: "Powered by Claude",
        description: "Enable AI enhancement to generate intelligent summaries, extract key facts, and identify temporal and geographic context automatically.",
        bulletPoints: [
            "Smart summaries at your preferred ratio",
            "Key fact and date extraction",
            "Location and historical figure identification"
        ]
    )
    
    // MARK: Slide 5 - Export
    
    static let slide5Export = WelcomeSlideData(
        id: 5,
        icon: "square.and.arrow.up",
        iconColor: .orange,
        title: "Export Your Knowledge",
        subtitle: "Markdown & JSON",
        description: "Export your extractions in formats optimized for different use cases — Markdown for readability, JSON for programmatic access.",
        bulletPoints: [
            "Markdown for notes and documentation",
            "JSON for integration and LLM training",
            "Single file or batch export options"
        ]
    )
    
    // MARK: Slide 6 - Get Started
    
    static let slide6GetStarted = WelcomeSlideData(
        id: 6,
        icon: "checkmark.circle",
        iconColor: .green,
        title: "You're Ready!",
        subtitle: "Start exploring",
        description: "Add your Anthropic API key to unlock AI-powered features, or jump straight in and explore Wikipedia articles."
    )
}
