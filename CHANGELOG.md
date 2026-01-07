# Changelog

All notable changes to Thoth will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

### Planned for v1.2
- Search within extracted content
- Data persistence between sessions
- Custom extraction templates
- Multi-language Wikipedia support
- PDF export format
- Obsidian/Notion integration

---

**Note**: For detailed release notes, see [RELEASE_NOTES.md](RELEASE_NOTES.md).
