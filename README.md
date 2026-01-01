# Thoth

**AI-Powered Wikipedia Article Extraction & Summarization for macOS**

Thoth is a native macOS application that extracts Wikipedia articles and uses Claude AI to create intelligent summaries, extract key facts, and provide structured analysis. Perfect for researchers, students, and anyone who needs to process Wikipedia content efficiently.

![Thoth Banner](screenshots/banner.png)

## ✨ Features

### Core Functionality
- **Wikipedia Extraction**: Extract any Wikipedia article by URL or article title
- **AI-Powered Summarization**: Compress articles to 60% of original length while preserving key information
- **Batch Processing**: Process up to 200 articles at once
- **Smart Article Classification**: Automatically categorizes articles (Person, Place, Event, Concept, etc.)
- **Structured Data Extraction**: Automatically extracts:
  - Key facts and statistics
  - Important dates and events
  - Geographic locations
  - Related topics and categories
  - Tables and infoboxes

### Export Options
- **Multiple Formats**: Export to Markdown or JSON
- **Batch Export**: Export all extractions to individual files
- **Session Export**: Combine multiple articles into a single document
- **Cost Tracking**: Monitor AI API usage and costs

### User Experience
- **Progress Tracking**: Real-time progress indicators for each extraction step
- **Global Progress Banner**: Always-visible status bar showing current work
- **Recent Articles**: Quick access to recently extracted articles
- **Keyboard Shortcuts**: Full keyboard control for power users
- **Copy to Clipboard**: One-click copy of any section

## 📸 Screenshots

![Main Interface](screenshots/main-interface.png)
*Main extraction interface with AI enhancement options*

![Extraction Details](screenshots/extraction-detail.png)
*Detailed view of extracted article with collapsible sections*

![Progress Tracking](screenshots/progress-tracking.png)
*Real-time progress tracking for AI enhancement steps*

## 🚀 Getting Started

### Requirements

- **macOS**: 14.0 (Sonoma) or later
- **Xcode**: 15.0 or later (for building from source)
- **Anthropic API Key**: Required for AI features ([Get one here](https://console.anthropic.com))

### Installation

#### Option 1: Download Pre-built App (Coming Soon)
1. Download the latest release from [Releases](https://github.com/trodelli/Thoth/releases)
2. Open the `.dmg` file
3. Drag Thoth to your Applications folder
4. Launch Thoth

#### Option 2: Build from Source

1. **Clone the repository**
   ```bash
   git clone https://github.com/trodelli/Thoth.git
   cd Thoth
   ```

2. **Open in Xcode**
   ```bash
   open Thoth.xcodeproj
   ```

3. **Build and Run**
   - Select "Thoth" scheme
   - Press `⌘R` to build and run
   - Or: Product → Run

### Setup

1. **Launch Thoth**

2. **Add Your API Key**
   - Go to Settings (⌘,)
   - Enter your Anthropic API key
   - Enable "AI Enhancement"

3. **Start Extracting!**
   - Enter a Wikipedia URL or article title
   - Click "Extract"
   - Watch the magic happen ✨

## 📖 Usage Guide

### Basic Extraction

1. **Enter URL or Article Title**
   - Full URL: `https://en.wikipedia.org/wiki/Confucius`
   - Or just: `Confucius`

2. **Choose Options**
   - **Summary Ratio**: How much to compress (default: 60%)
   - **AI Enhancement**: Enable for intelligent summarization

3. **Click Extract**
   - Watch real-time progress
   - Article appears in Extractions tab when done

### Batch Processing

1. Enter multiple URLs (one per line)
2. Click "Extract"
3. All articles process sequentially
4. Progress shown for each article

### Exporting

**Single Article:**
- Open extraction detail
- Click "Export" button (⌘E)
- Choose format and location

**All Articles:**
- In Extractions tab, click menu (•••)
- Choose:
  - "Export All to Single File" (⌘⌥E)
  - "Export All to Folder" (⌘⇧E)

### Keyboard Shortcuts

- `⌘N` - New Extraction
- `⌘1` - Input Tab
- `⌘2` - Extractions Tab
- `⌘3` - Activity Log Tab
- `⌘,` - Settings
- `⌘E` - Export Current
- `⌘⇧E` - Export All to Folder
- `⌘⌥E` - Export Session to File
- `⌘K` - Clear All

## 🏗️ Architecture

Thoth is built with modern Swift and SwiftUI:

### Core Components

- **ExtractionEngine**: Orchestrates Wikipedia fetching and AI enhancement
- **WikipediaService**: HTTP client for Wikipedia API
- **WikipediaParser**: HTML parsing and content extraction
- **AIEnhancementService**: Claude AI integration
- **ExportService**: Multi-format export functionality

### Tech Stack

- **Language**: Swift 5.9
- **Framework**: SwiftUI
- **Architecture**: MVVM
- **AI**: Anthropic Claude Sonnet 4
- **Networking**: URLSession
- **HTML Parsing**: Custom parser using Foundation

## 💰 Cost Information

- **AI Enhancement**: Uses Claude Sonnet 4
- **Pricing**: ~$0.02-0.05 per article (varies by length)
- **Cost Tracking**: Built-in session cost monitoring
- **No Subscription**: You only pay for API usage

## 🛠️ Development

### Project Structure

```
Thoth/
├── App/                    # App entry point
├── Configuration/          # Constants and configuration
├── Models/                 # Data models
├── Services/              # Business logic
│   ├── AI/               # Claude integration
│   ├── Extraction/       # Wikipedia extraction
│   ├── Export/           # Export functionality
│   └── Wikipedia/        # Wikipedia API
├── Utilities/            # Helper utilities
├── ViewModels/           # State management
└── Views/                # SwiftUI views
    ├── Components/       # Reusable components
    ├── Extraction/       # Extraction views
    ├── Input/           # Input views
    ├── Logs/            # Activity log
    └── Settings/        # Settings views
```

### Building

```bash
# Build for development
xcodebuild -scheme Thoth -configuration Debug

# Build for release
xcodebuild -scheme Thoth -configuration Release

# Run tests (when available)
xcodebuild test -scheme Thoth
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Guidelines

1. Follow Swift style guidelines
2. Add comments for complex logic
3. Test thoroughly before submitting
4. Update documentation as needed

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Claude AI](https://www.anthropic.com/claude) by Anthropic
- Wikipedia content via [Wikimedia API](https://www.mediawiki.org/wiki/API:Main_page)
- Developed with assistance from Claude Code

## 📧 Contact

**Author**: theway.ink  
**Website**: [theway.ink](https://theway.ink)  
**Issues**: [GitHub Issues](https://github.com/trodelli/Thoth/issues)

## 🗺️ Roadmap

### v1.1 (Planned)
- [ ] Search within extractions
- [ ] Data persistence between sessions
- [ ] Custom extraction templates
- [ ] Multi-language Wikipedia support
- [ ] PDF export format
- [ ] Obsidian/Notion integration

### v2.0 (Future)
- [ ] iOS/iPadOS versions
- [ ] Collaborative features
- [ ] Custom AI prompts
- [ ] Parallel processing

---

**Made with ❤️ using Swift and SwiftUI**

*Thoth - Named after the ancient Egyptian god of knowledge and writing*
