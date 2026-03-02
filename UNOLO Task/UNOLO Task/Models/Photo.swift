//
//  Photo.swift
//  UNOLO Task
//
//  Created by Shiva Kaushik on 28/02/26.
//

import Foundation

/// API response model for photo from REST API
struct Photo: Codable {
    let id: Int
    let albumId: Int
    let title: String
    let url: String
    let thumbnailUrl: String
}
