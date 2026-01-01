//
//  ThothError.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

enum ThothError: Error, LocalizedError {
    case validation(ValidationError)
    case network(NetworkError)
    case parsing(ParsingError)
    case ai(AIError)
    case export(ExportError)
    case keychain(KeychainError)
    
    var errorDescription: String? {
        switch self {
        case .validation(let error): return error.localizedDescription
        case .network(let error): return error.localizedDescription
        case .parsing(let error): return error.localizedDescription
        case .ai(let error): return error.localizedDescription
        case .export(let error): return error.localizedDescription
        case .keychain(let error): return error.localizedDescription
        }
    }
}

// MARK: - Validation Errors

enum ValidationError: Error, LocalizedError {
    case invalidURL(String)
    case notWikipedia(URL)
    case missingWikiPath(URL)
    case emptyInput
    case batchTooLarge(Int, max: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url): return "Invalid URL: \(url)"
        case .notWikipedia(let url): return "Not a Wikipedia URL: \(url)"
        case .missingWikiPath(let url): return "Missing /wiki/ path: \(url)"
        case .emptyInput: return "No URLs provided"
        case .batchTooLarge(let count, let max): return "Batch size \(count) exceeds maximum of \(max)"
        }
    }
}

// MARK: - Network Errors

enum NetworkError: Error, LocalizedError {
    case noConnection
    case timeout
    case serverError(Int)
    case rateLimited
    case articleNotFound(String)
    case invalidResponse
    case unexpectedStatus(Int)
    
    var errorDescription: String? {
        switch self {
        case .noConnection: return "No internet connection"
        case .timeout: return "Request timed out"
        case .serverError(let code): return "Server error: \(code)"
        case .rateLimited: return "Rate limited - please wait"
        case .articleNotFound(let title): return "Article not found: \(title)"
        case .invalidResponse: return "Invalid response from server"
        case .unexpectedStatus(let code): return "Unexpected HTTP status: \(code)"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .timeout, .serverError, .rateLimited: return true
        default: return false
        }
    }
}

// MARK: - Parsing Errors

enum ParsingError: Error, LocalizedError {
    case invalidHTML
    case missingContent
    case encodingError
    case noTextContent
    
    var errorDescription: String? {
        switch self {
        case .invalidHTML: return "Invalid HTML content"
        case .missingContent: return "Missing article content"
        case .encodingError: return "Text encoding error"
        case .noTextContent: return "No text content found"
        }
    }
}

// MARK: - AI Errors

enum AIError: Error, LocalizedError {
    case noAPIKey
    case invalidAPIKey
    case rateLimited
    case invalidResponse
    case timeout
    case serverError
    case unexpectedError(Int)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "No API key configured"
        case .invalidAPIKey: return "Invalid API key"
        case .rateLimited: return "AI rate limited - please wait"
        case .invalidResponse: return "Invalid response from AI"
        case .timeout: return "AI request timed out"
        case .serverError: return "AI server error"
        case .unexpectedError(let code): return "Unexpected AI error: \(code)"
        }
    }
}

// MARK: - Export Errors

enum ExportError: Error, LocalizedError {
    case directoryNotWritable(URL)
    case fileExists(URL)
    case diskFull
    case encodingFailed
    case writeError(String)
    
    var errorDescription: String? {
        switch self {
        case .directoryNotWritable(let url): return "Cannot write to: \(url.path)"
        case .fileExists(let url): return "File already exists: \(url.lastPathComponent)"
        case .diskFull: return "Disk is full"
        case .encodingFailed: return "Failed to encode content"
        case .writeError(let msg): return "Write error: \(msg)"
        }
    }
}

// MARK: - Keychain Errors

enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status): return "Failed to save to Keychain: \(status)"
        case .retrieveFailed(let status): return "Failed to retrieve from Keychain: \(status)"
        case .deleteFailed(let status): return "Failed to delete from Keychain: \(status)"
        case .notFound: return "Item not found in Keychain"
        }
    }
}
