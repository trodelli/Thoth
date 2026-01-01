//
//  WikipediaService.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

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
