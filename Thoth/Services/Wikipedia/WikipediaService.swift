//
//  WikipediaService.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

/// Lightweight preview data for an article (fetched via Wikipedia API)
struct ArticlePreviewData {
    let title: String
    let extract: String
    let categories: [String]
    let thumbnail: URL?
    let pageURL: URL
    
    /// Formatted categories for display (max 5)
    var displayCategories: [String] {
        Array(categories.prefix(5))
    }
    
    /// Truncated extract for preview
    var shortExtract: String {
        if extract.count <= 300 {
            return extract
        }
        let truncated = String(extract.prefix(300))
        if let lastPeriod = truncated.lastIndex(of: ".") {
            return String(truncated[...lastPeriod])
        }
        return truncated + "..."
    }
}

class WikipediaService: WikipediaServiceProtocol {
    private let session: URLSession
    private let logger = Logger.shared
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchArticle(url: URL) async throws -> WikipediaArticle {
        guard let title = URLValidator.extractArticleTitle(from: url) else {
            throw ValidationError.missingWikiPath(url)
        }
        
        logger.info("Fetching article: \(title)")
        
        let apiURL = buildAPIURL(title: title)
        var request = URLRequest(url: apiURL)
        request.setValue(AppConstants.Wikipedia.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        logger.info("Received response: \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200:
            return try parseResponse(data: data)
        case 429:
            throw NetworkError.rateLimited
        case 500...599:
            throw NetworkError.serverError(httpResponse.statusCode)
        default:
            throw NetworkError.unexpectedStatus(httpResponse.statusCode)
        }
    }
    
    // MARK: - Article Preview (Lightweight fetch for search results)
    
    /// Fetch lightweight preview data for an article (extract + categories)
    /// This is much faster than fetching the full article and costs nothing (no AI)
    func fetchArticlePreview(title: String) async throws -> ArticlePreviewData {
        let apiURL = buildPreviewAPIURL(title: title)
        
        var request = URLRequest(url: apiURL)
        request.setValue(AppConstants.Wikipedia.userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10 // Quick timeout for preview
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        return try parsePreviewResponse(data: data, title: title)
    }
    
    /// Build API URL for preview (extracts + categories + thumbnail)
    private func buildPreviewAPIURL(title: String) -> URL {
        var components = URLComponents(string: AppConstants.Wikipedia.baseURL)!
        components.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2"),
            URLQueryItem(name: "titles", value: title),
            URLQueryItem(name: "prop", value: "extracts|categories|pageimages|info"),
            URLQueryItem(name: "exintro", value: "true"),           // Only intro section
            URLQueryItem(name: "explaintext", value: "true"),       // Plain text, no HTML
            URLQueryItem(name: "exsentences", value: "4"),          // First 4 sentences
            URLQueryItem(name: "cllimit", value: "10"),             // Max 10 categories
            URLQueryItem(name: "clshow", value: "!hidden"),         // Exclude hidden categories
            URLQueryItem(name: "piprop", value: "thumbnail"),       // Get thumbnail
            URLQueryItem(name: "pithumbsize", value: "200"),        // Thumbnail size
            URLQueryItem(name: "inprop", value: "url"),             // Get page URL
            URLQueryItem(name: "redirects", value: "true"),
            URLQueryItem(name: "origin", value: "*")
        ]
        return components.url!
    }
    
    /// Parse preview response
    private func parsePreviewResponse(data: Data, title: String) throws -> ArticlePreviewData {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let query = json["query"] as? [String: Any],
              let pages = query["pages"] as? [[String: Any]],
              let page = pages.first else {
            throw ParsingError.missingContent
        }
        
        // Check if page is missing
        if page["missing"] != nil {
            throw NetworkError.articleNotFound(title)
        }
        
        let pageTitle = page["title"] as? String ?? title
        let extract = page["extract"] as? String ?? ""
        
        // Parse categories
        var categories: [String] = []
        if let cats = page["categories"] as? [[String: Any]] {
            categories = cats.compactMap { cat in
                guard let catTitle = cat["title"] as? String else { return nil }
                // Remove "Category:" prefix
                return catTitle.replacingOccurrences(of: "Category:", with: "")
            }
        }
        
        // Parse thumbnail
        var thumbnail: URL? = nil
        if let thumbInfo = page["thumbnail"] as? [String: Any],
           let thumbSource = thumbInfo["source"] as? String {
            thumbnail = URL(string: thumbSource)
        }
        
        // Parse page URL
        let pageURLString = page["fullurl"] as? String ?? "https://en.wikipedia.org/wiki/\(title.replacingOccurrences(of: " ", with: "_"))"
        let pageURL = URL(string: pageURLString) ?? URL(string: "https://en.wikipedia.org")!
        
        return ArticlePreviewData(
            title: pageTitle,
            extract: extract,
            categories: categories,
            thumbnail: thumbnail,
            pageURL: pageURL
        )
    }
    
    // MARK: - Private Methods
    
    private func buildAPIURL(title: String) -> URL {
        var components = URLComponents(string: AppConstants.Wikipedia.baseURL)!
        components.queryItems = [
            URLQueryItem(name: "action", value: "parse"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "page", value: title),
            URLQueryItem(name: "prop", value: "text|categories|displaytitle|sections"),
            URLQueryItem(name: "disableeditsection", value: "true"),
            URLQueryItem(name: "redirects", value: "true"),
            URLQueryItem(name: "origin", value: "*")
        ]
        return components.url!
    }
    
    private func parseResponse(data: Data) throws -> WikipediaArticle {
        let response = try JSONDecoder().decode(WikipediaResponse.self, from: data)
        
        if let error = response.error {
            if error.code == "missingtitle" {
                throw NetworkError.articleNotFound(error.info)
            }
            throw NetworkError.invalidResponse
        }
        
        guard let parse = response.parse else {
            throw ParsingError.missingContent
        }
        
        let wordCount = countWords(in: parse.text.content)
        logger.info("Parsed: \(parse.title) (\(wordCount) words)")
        
        return WikipediaArticle(
            title: parse.title,
            pageID: parse.pageid,
            displayTitle: parse.displaytitle,
            html: parse.text.content,
            categories: parse.categories.map { $0.name },
            sectionStructure: parse.sections,
            wordCount: wordCount
        )
    }
    
    private func countWords(in html: String) -> Int {
        // Simple word count from HTML text
        let text = html.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }
}
