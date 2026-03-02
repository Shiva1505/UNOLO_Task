//
//  PhotoAPIService.swift
//  UNOLO Task
//
//  Created by Shiva Kaushik on 28/02/26.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case networkError(Error)
}

final class PhotoAPIService {

    private let baseURL = "https://jsonplaceholder.typicode.com"
    private let session: URLSession
    let batchSize: Int

    init(session: URLSession = .shared, batchSize: Int = 50) {
        self.session = session
        self.batchSize = batchSize
    }

    func fetchPhotos(page: Int = 1, limit: Int? = nil) async throws -> [Photo] {
        let limit = limit ?? batchSize
        var components = URLComponents(string: "\(baseURL)/photos")!
        components.queryItems = [
            URLQueryItem(name: "_page", value: "\(page)"),
            URLQueryItem(name: "_limit", value: "\(limit)")
        ]
        guard let url = components.url else {
            throw APIError.invalidURL
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        do {
            let photos = try JSONDecoder().decode([Photo].self, from: data)
            print("[API] fetchPhotos page=\(page) limit=\(limit) → \(photos.count) items")
            if let first = photos.first {
                print("[API] Sample: id=\(first.id) title=\(first.title.prefix(40))... thumbnailUrl=\(first.thumbnailUrl)")
            }
            if let json = String(data: data, encoding: .utf8), json.count < 2000 {
                print("[API] Response: \(json)")
            }
            return photos
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func fetchAllPhotosInBatches(batchHandler: ([Photo]) async -> Void) async throws {
        var page = 1
        var totalReceived = 0
        while true {
            let batch = try await fetchPhotos(page: page, limit: batchSize)
            if batch.isEmpty { break }
            totalReceived += batch.count
            print("[API] Batch page \(page): \(batch.count) photos (total so far: \(totalReceived))")
            await batchHandler(batch)
            if batch.count < batchSize { break }
            page += 1
        }
        print("[API] fetchAllPhotosInBatches finished. Total: \(totalReceived) photos")
    }
}
