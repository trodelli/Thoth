# Changelog

All notable changes to Thoth will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

### Planned for v1.1
- Search within extracted content
- Data persistence between sessions
- Custom extraction templates
- Multi-language Wikipedia support
- PDF export format
- Obsidian/Notion integration

---

**Note**: This is the initial public release of Thoth. Future updates will be documented here.
