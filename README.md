<p align="center">
  <img src="Icon/Thoth%20Icon%20256x256.png" alt="Thoth App Icon" width="128" height="128">
</p>

<h1 align="center">Thoth</h1>

<p align="center">
  <strong>Transform Wikipedia articles into structured, intelligent extractions</strong>
</p>

<p align="center">
  A native macOS application that extracts Wikipedia articles and uses Claude AI to create intelligent summaries, extract key facts, and provide structured analysis.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue?style=flat-square" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange?style=flat-square" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="MIT License">
  <img src="https://img.shields.io/badge/Version-1.0.1-purple?style=flat-square" alt="Version 1.0.1">
</p>

<p align="center">
  <img src="Screenshots/Main%20Interface.png" alt="Thoth Main Interface" width="800">
</p>

---

## ✨ What's New in v1.0.1

- 🪟 **Custom About Window** — Beautiful About screen with app description and attribution
- 🔧 **Fixed Expand/Collapse** — Buttons now work correctly in extraction detail view
- 📐 **Improved Layout** — Content properly adjusts when progress banner appears
- 🧹 **Code Quality** — Reduced console warnings and cleaned up codebase

---

## Why Thoth?

**Thoth** brings AI-powered Wikipedia extraction to your Mac. Enter any Wikipedia URL or article title, and Thoth extracts clean, structured content using Claude AI's powerful language understanding. Get intelligent summaries, key facts, important dates, and geographic locations—all in one click.

- 📚 **Smart Extraction** — Extract any Wikipedia article by URL or title
- 🧠 **AI Summarization** — Compress articles to 60% while preserving key information
- 📦 **Batch Processing** — Queue up to 200 articles and process them all at once
- 📊 **Structured Data** — Automatically extract facts, dates, locations, and topics
- 💰 **Cost Transparent** — Know exactly what you'll pay before processing
- 🔒 **Private & Secure** — API keys stored in your Mac's Keychain

---

## Screenshots

|  |  |
| --- | --- |
| **Input** Add Wikipedia URLs and configure options | **Extraction** View extracted content with collapsible sections |
| ![Input View](Screenshots/Main%20Interface.png) | ![Extraction View](Screenshots/Extraction%20Example.png) |

---

## Getting Started

### 1. Download & Install

Download the latest release from the [Releases](https://github.com/trodelli/Thoth/releases) page:

1. Download `Thoth-1.0.1.dmg`
2. Open the DMG and drag **Thoth** to your Applications folder
3. Launch Thoth

> **First Launch Note:** macOS may show a security warning for apps downloaded outside the App Store. Go to **System Settings → Privacy & Security** and click **"Open Anyway"**.

### 2. Get Your API Key

Thoth uses [Claude AI](https://www.anthropic.com/claude) by Anthropic for intelligent extraction:

1. Create an account at [console.anthropic.com](https://console.anthropic.com)
2. Navigate to **API Keys** and create a new key
3. Copy the key and paste it into Thoth Settings (⌘,)

### 3. Extract Your First Article

1. **Enter a URL or title** — `https://en.wikipedia.org/wiki/Confucius` or just `Confucius`
2. **Enable AI Enhancement** — Toggle on for intelligent summarization
3. **Click Extract** — Watch real-time progress as your article is processed
4. **Browse results** — Expand sections to see summaries, facts, dates, and more
5. **Export** — Save as Markdown or JSON

---

## Features

### AI-Powered Extraction

Thoth uses Claude Sonnet 4 to intelligently process Wikipedia articles:

- **Smart Summarization** — Compress to 40-70% of original length
- **Article Classification** — Automatically categorize (Person, Place, Event, etc.)
- **Key Facts** — Extract the most important information
- **Temporal Context** — Identify important dates and events
- **Geographic Context** — Extract locations with modern equivalents
- **Related Topics** — Discover connected subjects

### Batch Processing

Process multiple articles efficiently:

- Add up to 200 URLs at once
- Real-time progress tracking for each article
- Global progress banner shows overall status
- Rate limiting respects Wikipedia's servers

### Export Options

| Format | Use Case |
| --- | --- |
| Markdown | Perfect for notes, Obsidian, or documentation |
| JSON | Ideal for data processing or integration |

Export options:
- **Single Article** — Export one extraction (⌘E)
- **All to Folder** — Export each as separate file (⌘⇧E)
- **Session to File** — Combine all into one document (⌘⌥E)

---

## Pricing

Thoth itself is **free and open source**. You only pay for Claude API usage:

| Articles | Estimated Cost |
| --- | --- |
| 1 | ~$0.02-0.05 |
| 10 | ~$0.20-0.50 |
| 100 | ~$2.00-5.00 |

Cost varies by article length. Built-in cost tracking shows your session total.

---

## Keyboard Shortcuts

| Action | Shortcut |
| --- | --- |
| New Extraction | `⌘N` |
| Input Tab | `⌘1` |
| Extractions Tab | `⌘2` |
| Activity Log Tab | `⌘3` |
| Settings | `⌘,` |
| Export Current | `⌘E` |
| Export All to Folder | `⌘⇧E` |
| Export Session | `⌘⌥E` |
| Clear All | `⌘K` |

---

## Building from Source

Prefer to build it yourself? Easy:

```bash
git clone https://github.com/trodelli/Thoth.git
cd Thoth
open Thoth.xcodeproj
```

Then press `⌘R` in Xcode to build and run.

**Requirements:**
- macOS 14.0 (Sonoma) or later
- Xcode 15.0+

---

## How It Works

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Wikipedia  │ ──▶ │   Parse &   │ ──▶ │  Claude AI  │
│     URL     │     │   Extract   │     │  Analysis   │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
┌─────────────┐     ┌─────────────┐            │
│   Export    │ ◀── │  Structured │ ◀──────────┘
│   MD/JSON   │     │    Data     │     Summary, Facts,
└─────────────┘     └─────────────┘     Dates, Locations
```

1. **Input** — Enter Wikipedia URLs or article titles
2. **Fetch** — Download article content from Wikipedia API
3. **Parse** — Extract HTML content and structure
4. **Analyze** — Claude AI generates summaries and extracts data
5. **Display** — Browse results in collapsible sections
6. **Export** — Save to Markdown or JSON

---

## Tech Stack

| Component | Technology |
| --- | --- |
| UI Framework | SwiftUI |
| Architecture | MVVM |
| AI | Claude Sonnet 4 (Anthropic) |
| Networking | URLSession + async/await |
| Security | macOS Keychain Services |
| HTML Parsing | Custom Swift parser |

---

## Project Structure

```
Thoth/
├── App/                    # App entry point
├── Configuration/          # Constants and settings
├── Models/                 # Data models
├── Services/
│   ├── AI/                # Claude integration
│   ├── Extraction/        # Extraction engine
│   ├── Export/            # Export functionality
│   └── Wikipedia/         # Wikipedia API
├── Utilities/             # Helpers
├── ViewModels/            # State management
└── Views/
    ├── Components/        # Reusable UI
    ├── Extraction/        # Extraction views
    ├── Input/             # Input view
    ├── Logs/              # Activity log
    └── Settings/          # Settings view
```

---

## Contributing

Contributions are welcome! Here's how:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-idea`)
3. Commit your changes (`git commit -m 'Add amazing idea'`)
4. Push to the branch (`git push origin feature/amazing-idea`)
5. Open a Pull Request

---

## License

MIT License — see [LICENSE](LICENSE) for details.

Free to use, modify, and distribute.

---

## Acknowledgments

- [Anthropic](https://www.anthropic.com) for Claude AI
- [Wikipedia](https://www.wikipedia.org) via the Wikimedia API
- Named after [Thoth](https://en.wikipedia.org/wiki/Thoth) — the ancient Egyptian god of knowledge and writing

---

<p align="center">
  <strong>DESIGNED BY THEWAY.INK · BUILT WITH AI · MADE IN MARSEILLE</strong>
</p>

<p align="center">
  <a href="https://github.com/trodelli/Thoth/releases">Download</a> ·
  <a href="https://github.com/trodelli/Thoth/issues">Report Bug</a> ·
  <a href="https://github.com/trodelli/Thoth/issues">Request Feature</a>
</p>
