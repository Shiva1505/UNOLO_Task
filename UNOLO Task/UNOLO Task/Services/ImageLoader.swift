//
//  ImageLoader.swift
//  UNOLO Task
//
//  Created by Shiva Kaushik on 28/02/26.
//
import UIKit

/// Loads and caches images from URLs
final class ImageLoader {

    static let shared = ImageLoader()

    private let session: URLSession
    private let cache = NSCache<NSString, UIImage>()

    private init(session: URLSession = .shared) {
        self.session = session
        cache.countLimit = 100
    }

    func loadImage(from urlString: String?) async -> UIImage? {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            print("[ImageLoader] Skip: invalid URL \(urlString ?? "nil")")
            return nil
        }

        let key = urlString as NSString
        if let cached = cache.object(forKey: key) {
            print("[ImageLoader] Cache hit: \(urlString)")
            return cached
        }

        if let image = await fetchImage(from: url, cacheKey: key, urlString: urlString) {
            return image
        }

        if urlString.contains("via.placeholder.com") {
            // Derive a stable seed from the color/id part so 150 and 600 variants map to same fallback.
            let seed = placeholderSeed(from: url) ?? String(abs(urlString.hashValue))
            let size = placeholderSize(from: url) ?? 150
            let fallbackURLString = "https://picsum.photos/seed/\(seed)/\(size)"
            print("[ImageLoader] Fallback: \(fallbackURLString)")
            if let fallbackURL = URL(string: fallbackURLString),
               let image = await fetchImage(from: fallbackURL, cacheKey: key, urlString: urlString) {
                return image
            }
        }
        return nil
    }

    private func fetchImage(from url: URL, cacheKey: NSString, urlString: String) async -> UIImage? {
        print("[ImageLoader] Loading: \(urlString)")
        do {
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                print("[ImageLoader] HTTP \(http.statusCode): \(urlString)")
                return nil
            }
            if let image = UIImage(data: data) {
                cache.setObject(image, forKey: cacheKey)
                print("[ImageLoader] Loaded OK: \(urlString)")
                return image
            }
            print("[ImageLoader] Invalid image data: \(urlString)")
        } catch {
            print("[ImageLoader] Error: \(error.localizedDescription) — \(urlString)")
        }
        return nil
    }

    private func placeholderSeed(from url: URL) -> String? {
        let candidate = url.lastPathComponent
        guard !candidate.isEmpty else { return nil }
        return candidate
    }

    private func placeholderSize(from url: URL) -> Int? {
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count >= 2 else { return nil }
        return Int(parts[parts.count - 2])
    }
}
