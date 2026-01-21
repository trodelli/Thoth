# Changelog

All notable changes to Thoth will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-01-21

### 🎉 Major Release: AI-Powered Search & Onboarding

This release introduces two major features that transform how users discover and interact with Wikipedia content.

### ✨ New Features

#### AI-Powered Search Tab
A completely new way to discover Wikipedia articles using natural language:

- **Intelligent Article Discovery** — Describe what you're looking for in plain English
- **Claude AI Integration** — Uses Claude Sonnet 4 to find relevant articles
- **Article Validation** — Every suggested article is verified to exist on Wikipedia
- **Rich Previews** — See article descriptions and preview content before extracting
- **Batch Selection** — Select multiple articles with checkboxes
- **Add to Input** — Transfer selected articles directly to extraction queue
- **Export Results** — Save search results as TXT, Markdown, or JSON
- **Recent Searches** — Quick access to previous searches in sidebar (session-only)
- **Search Cost Tracking** — Real-time token usage and cost display
- **AI-Powered Badge** — Visual indicator for AI-enhanced features

#### Welcome Wizard
A beautiful onboarding experience for new users:

- **6 Informative Slides** — Covers Search, Input, AI Enhancement, Export, and Getting Started
- **First-Launch Detection** — Automatically shows for new users
- **Interactive Navigation** — Next/Back buttons and clickable page indicators
- **Quick Actions** — Add API key, start searching, or go to input directly
- **Re-accessible** — Available anytime from Settings → "Show Welcome Tour" or Help menu
- **Polished Design** — Consistent with macOS design language

#### UI/UX Improvements
- **Standardized Navigation** — Search tab integrated into main navigation
- **AI-Enhanced Badge** — Purple badge with brain icon for AI features in Input tab
- **Anthropic Console Link** — Clickable link in API settings to get API key
- **Export Button Placement** — Moved to header in Search and Extractions tabs
- **Clear All Button** — Standalone button in Extractions tab (prevents accidental clicks)
- **Blue Recent Searches** — Improved visibility in sidebar

### 🔧 Technical Improvements

#### New Files (14)
- `SearchViewModel.swift` — Search tab state management
- `WikipediaSearchService.swift` — Claude-powered article discovery
- `SearchResult.swift` — Search result data model
- `SearchStep.swift` — Search progress steps enum
- `SearchCostTracker.swift` — Search API cost tracking
- `ArticlePreview.swift` — Wikipedia article preview model
- `SearchView.swift` — Main search interface
- `SearchDetailPanel.swift` — Search results detail panel
- `SearchResultRow.swift` — Individual result row component
- `WelcomeWizardView.swift` — Main wizard container
- `WelcomeSlideView.swift` — Reusable slide component
- `WelcomeSlideData.swift` — Slide content model

#### Modified Files (12)
- `AppState.swift` — Added onboarding and search state management
- `ThothApp.swift` — Welcome wizard integration, Help menu item
- `MainView.swift` — Search tab routing, fixed shared AppState
- `Sidebar.swift` — Search navigation, recent searches display
- `SettingsView.swift` — "Show Welcome Tour" button
- `APIKeyView.swift` — Anthropic Console clickable link
- `InputView.swift` — AI-Enhanced badge styling
- `ExtractionListView.swift` — Export icon, Clear All button placement
- `ExtractionDetailView.swift` — Expand/Collapse All state fix
- `ClaudeService.swift` — API key validation endpoint
- `CollapsibleSection.swift` — State change handler improvement

### 🐛 Bug Fixes

- Fixed AppState not being shared between MainView and ThothApp
- Fixed Expand/Collapse All not affecting all sections in extraction detail
- Fixed recent searches reordering when selecting existing search
- Fixed navigation not working from Welcome Wizard CTA buttons

---

## [1.0.1] - 2026-01-07

### ✨ New Features

#### Custom About Window
- Beautiful About window with app icon, description, and attribution
- Accessible via Thoth → About Thoth menu
- Removed redundant About tab from Settings

#### Improved UI/UX
- **Fixed Expand/Collapse buttons** — Expand All and Collapse All now work correctly in extraction detail view
- **Fixed button icons** — Icons now correctly represent expand and collapse actions
- **Improved progress banner** — Content properly adjusts when the global progress banner appears/disappears
- **Tighter layout** — Removed excessive spacing when progress banner is visible

### 🐛 Bug Fixes

- Fixed "Publishing changes from within view updates" warnings by adding debounce to URL validation
- Fixed CollapsibleSection not responding to parent expand/collapse state changes
- Removed unused `showAbout` property from AppState
- Removed unused toolbar button from Sidebar

### 🧹 Code Quality

- Cleaned up redundant spacers in InputView, ExtractionListView, LogView, and ExtractionDetailView
- Removed unused UI constants from AppConstants
- Improved code organization and reduced console warnings

---

## [1.0.0] - 2026-01-01

### 🎉 Initial Release

#### Added
- Wikipedia article extraction by URL or article title
- AI-powered summarization using Claude Sonnet 4
- Automatic article classification (10 types)
- Key facts extraction
- Important dates and events extraction
- Geographic location extraction
- Related topics discovery
- Table structure preservation
- Batch processing (up to 200 URLs)
- Export formats: Markdown, JSON
- Session export (combine multiple articles)
- Batch export to folder
- Real-time progress tracking
- Global progress banner
- Cost tracking and estimation
- Recent articles quick access
- Collapsible content sections
- Copy to clipboard functionality
- Keyboard shortcuts (9 commands)
- Activity logging
- Settings management
- Keychain-secured API key storage

#### Features in Detail

**Extraction Pipeline:**
- Fetch from Wikipedia API
- Parse HTML content
- Generate AI summary (60% compression)
- Classify article type
- Extract key facts
- Extract dates and events
- Extract locations
- Extract related topics

**Export Options:**
- Single article export
- Batch export (individual files)
- Session export (combined file)
- Markdown format
- JSON format

**User Experience:**
- Native macOS app (SwiftUI)
- Real-time progress indicators
- Step-by-step AI progress
- Cost estimation and tracking
- Keyboard shortcut support
- Recent articles history
- Clean, modern interface

#### Technical
- Built with Swift 5.9
- SwiftUI framework
- MVVM architecture
- Claude Sonnet 4 integration
- Custom HTML parser
- Secure keychain storage
- Comprehensive error handling
- Retry logic for API calls

---

## [Unreleased]

### Planned for Future Versions
- Search within extracted content
- Data persistence between sessions
- Custom extraction templates
- Multi-language Wikipedia support
- PDF export format
- Obsidian/Notion integration
- Cloud sync

---

**Note**: For the latest updates, visit the [GitHub Releases](https://github.com/trodelli/Thoth/releases) page.
