//
//  WikipediaModels.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

// MARK: - API Response

struct WikipediaResponse: Codable {
    let parse: ParseResult?
    let error: WikipediaAPIError?
}

struct ParseResult: Codable {
    let title: String
    let pageid: Int
    let displaytitle: String
    let text: TextContent
    let categories: [WikiCategory]
    let sections: [WikiSection]
}

struct TextContent: Codable {
    let content: String
    
    enum CodingKeys: String, CodingKey {
        case content = "*"
    }
}

struct WikiCategory: Codable {
    let sortkey: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case sortkey
        case name = "*"
    }
}

struct WikiSection: Codable {
    let toclevel: Int
    let level: String
    let line: String
    let number: String
    let index: String
}

struct WikipediaAPIError: Codable {
    let code: String
    let info: String
}

// MARK: - Parsed Content

struct WikipediaArticle {
    let title: String
    let pageID: Int
    let displayTitle: String
    let html: String
    let categories: [String]
    let sectionStructure: [WikiSection]
    let wordCount: Int
}

struct ParsedWikipediaContent {
    let title: String
    let displayTitle: String
    let pageID: Int
    let categories: [String]
    let infobox: Infobox?
    let tables: [Table]
    let sections: [Section]
    let seeAlso: [SeeAlsoLink]
    let alternateNames: [String]
    let firstParagraph: String
    let wordCount: Int
}
