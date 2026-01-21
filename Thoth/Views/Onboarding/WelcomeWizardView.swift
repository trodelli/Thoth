//
//  WelcomeWizardView.swift
//  Thoth
//
//  Created by theway.ink on January 21, 2026.
//  Copyright © 2026 theway.ink. All rights reserved.
//

import SwiftUI

/// Main container for the Welcome Wizard onboarding experience
struct WelcomeWizardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var currentSlideIndex: Int = 0
    
    private let slides = WelcomeSlideData.allSlides
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Thoth branding
            headerSection
            
            Divider()
            
            // Slide content area
            slideContentArea
            
            Divider()
            
            // Footer with navigation
            footerSection
        }
        .frame(width: 720, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            // Thoth branding
            HStack(spacing: 8) {
                Image(systemName: "book.pages.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Thoth")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            // Skip button (not shown on final slide)
            if !isLastSlide {
                Button("Skip") {
                    completeOnboarding()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help("Skip the welcome tour")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    // MARK: - Slide Content Area
    
    private var slideContentArea: some View {
        ZStack {
            // Display current slide with transition
            ForEach(slides) { slide in
                if slide.id == currentSlide.id {
                    if isLastSlide {
                        // Special layout for final slide
                        finalSlideContent
                            .transition(slideTransition)
                    } else {
                        // Standard slide layout
                        WelcomeSlideView(slide: slide)
                            .transition(slideTransition)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentSlideIndex)
    }
    
    // MARK: - Final Slide Content (Special Layout)
    
    private var finalSlideContent: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 44))
                    .foregroundColor(.green)
            }
            
            // Title & Subtitle
            VStack(spacing: 8) {
                Text(currentSlide.title)
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text(currentSlide.subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // Description
            Text(currentSlide.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // CTA Buttons
            VStack(spacing: 12) {
                // Primary: Add API Key
                Button(action: {
                    completeOnboarding(navigateTo: nil, openSettings: true)
                }) {
                    HStack {
                        Image(systemName: "key.fill")
                        Text("Add API Key")
                    }
                    .frame(width: 220)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                // Secondary: Start with Search
                Button(action: {
                    completeOnboarding(navigateTo: .search)
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Start with Search")
                    }
                    .frame(width: 220)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                // Tertiary: Go to Input
                Button(action: {
                    completeOnboarding(navigateTo: .input)
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Go to Input")
                    }
                    .frame(width: 220)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        HStack {
            // Back button (hidden on first slide)
            if currentSlideIndex > 0 {
                Button(action: goToPreviousSlide) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            } else {
                // Placeholder to maintain layout
                Spacer()
                    .frame(width: 60)
            }
            
            Spacer()
            
            // Page indicators
            pageIndicators
            
            Spacer()
            
            // Next / Get Started button
            if isLastSlide {
                Button("Get Started") {
                    completeOnboarding()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            } else {
                Button(action: goToNextSlide) {
                    HStack(spacing: 4) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    // MARK: - Page Indicators
    
    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<slides.count, id: \.self) { index in
                Circle()
                    .fill(index == currentSlideIndex ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: index == currentSlideIndex ? 10 : 8, height: index == currentSlideIndex ? 10 : 8)
                    .animation(.spring(response: 0.3), value: currentSlideIndex)
                    .onTapGesture {
                        withAnimation {
                            currentSlideIndex = index
                        }
                    }
                    .accessibilityLabel("Page \(index + 1) of \(slides.count)")
                    .accessibilityAddTraits(index == currentSlideIndex ? .isSelected : [])
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentSlide: WelcomeSlideData {
        slides[currentSlideIndex]
    }
    
    private var isLastSlide: Bool {
        currentSlideIndex == slides.count - 1
    }
    
    private var slideTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    // MARK: - Actions
    
    private func goToNextSlide() {
        guard currentSlideIndex < slides.count - 1 else { return }
        withAnimation {
            currentSlideIndex += 1
        }
    }
    
    private func goToPreviousSlide() {
        guard currentSlideIndex > 0 else { return }
        withAnimation {
            currentSlideIndex -= 1
        }
    }
    
    private func completeOnboarding(navigateTo section: NavigationSection? = nil, openSettings: Bool = false) {
        appState.hasCompletedOnboarding = true
        
        // Set navigation/settings state BEFORE dismissing
        if let section = section {
            appState.selectedSection = section
        }
        
        if openSettings {
            // Delay settings open slightly to allow wizard to close first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appState.showSettings = true
            }
        }
        
        dismiss()
    }
}

// MARK: - Preview

#Preview("Welcome Wizard") {
    WelcomeWizardView()
        .environmentObject(AppState())
}
