//
//  WikipediaServiceProtocol.swift
//  Thoth
//
//  Created by theway.ink on December 31, 2025.
//  Copyright © 2025 theway.ink. All rights reserved.
//

import Foundation

protocol WikipediaServiceProtocol {
    func fetchArticle(url: URL) async throws -> WikipediaArticle
}
