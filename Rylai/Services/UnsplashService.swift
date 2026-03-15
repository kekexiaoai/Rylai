// UnsplashService.swift
// Rylai ❄️

import Foundation
import Combine

enum UnsplashError: LocalizedError {
    case invalidAPIKey
    case rateLimited
    case networkError(Error)
    case decodingError(Error)
    case noPhotosFound
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:      return "Invalid API Key, please check configuration"
        case .rateLimited:        return "API rate limited (50/hour), please try again later"
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .decodingError(let e): return "Decoding error: \(e.localizedDescription)"
        case .noPhotosFound:      return "No matching photos found"
        }
    }
}

@MainActor
class UnsplashService: ObservableObject {
    
    @Published var isLoading = false
    @Published var lastError: UnsplashError?
    @Published var currentPhoto: UnsplashPhoto?
    @Published var photoPool: [UnsplashPhoto] = []  // Prefetch pool
    
    private let session: URLSession
    private var poolRefreshTask: Task<Void, Never>?
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Fetch Random Photo

    func fetchRandomPhoto(category: WallpaperCategory) async throws -> UnsplashPhoto {
        if category.isEditorial {
            // Editorial: fetch from /photos (editorial feed) with random page
            let photos = try await fetchEditorialPhotos(count: 10)
            // Filter landscape photos (width > height)
            let landscape = photos.first { $0.width > $0.height }
            guard let photo = landscape else { throw UnsplashError.noPhotosFound }
            return photo
        }
        // Fetch 10 photos to ensure landscape availability
        let url = buildRandomURL(category: category, count: 10)
        let photos = try await fetch([UnsplashPhoto].self, from: url)
        // Filter landscape photos (width > height)
        let landscape = photos.first { $0.width > $0.height }
        guard let photo = landscape else { throw UnsplashError.noPhotosFound }
        return photo
    }

    // MARK: - Batch Prefetch

    func prefetchPhotos(category: WallpaperCategory, count: Int = Config.prefetchCount) async {
        guard photoPool.count < 3 else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            if category.isEditorial {
                let photos = try await fetchEditorialPhotos(count: count * 2)
                // Only add landscape
                let landscape = photos.filter { $0.width > $0.height }
                photoPool.append(contentsOf: landscape)
            } else {
                let url = buildRandomURL(category: category, count: count * 2)
                let photos = try await fetch([UnsplashPhoto].self, from: url)
                // Only add landscape
                let landscape = photos.filter { $0.width > $0.height }
                photoPool.append(contentsOf: landscape)
            }
        } catch {
            lastError = error as? UnsplashError ?? .networkError(error)
        }
    }
    
    // MARK: - Next Photo From Pool

    func nextPhoto(category: WallpaperCategory) async throws -> UnsplashPhoto {
        if !photoPool.isEmpty {
            return photoPool.removeFirst()
        }
        // Pool empty, fetch directly
        return try await fetchRandomPhoto(category: category)
    }

    // MARK: - Clear Pool

    func clearPool() {
        photoPool.removeAll()
    }
    
    // MARK: - Search

    func searchPhotos(query: String, page: Int = 1) async throws -> [UnsplashPhoto] {
        let apiKey = WallpaperSettings.shared.effectiveAPIKey
        var components = URLComponents(string: "\(Config.unsplashBaseURL)/search/photos")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "orientation", value: "landscape"),
            URLQueryItem(name: "per_page", value: "20"),
            URLQueryItem(name: "page", value: "\(page)"),
        ]
        let result = try await fetch(UnsplashSearchResult.self, from: components.url!)
        return result.results
    }
    
    // MARK: - Track Download (API Requirement)
    
    func trackDownload(photo: UnsplashPhoto) {
        Task {
            let apiKey = WallpaperSettings.shared.effectiveAPIKey
            guard var components = URLComponents(string: photo.links.downloadLocation) else { return }
            var items = components.queryItems ?? []
            items.append(URLQueryItem(name: "client_id", value: apiKey))
            components.queryItems = items
            guard let url = components.url else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            _ = try? await session.data(for: request)
        }
    }
    
    // MARK: - Generic Request
    
    private func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")
        
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw UnsplashError.networkError(URLError(.badServerResponse))
        }
        
        switch http.statusCode {
        case 200:
            break
        case 401:
            throw UnsplashError.invalidAPIKey
        case 403:
            throw UnsplashError.rateLimited
        case 429:
            throw UnsplashError.rateLimited
        default:
            throw UnsplashError.networkError(URLError(.badServerResponse))
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw UnsplashError.decodingError(error)
        }
    }
    
    // MARK: - URL Builder
    
    private func buildRandomURL(category: WallpaperCategory, count: Int) -> URL {
        let apiKey = WallpaperSettings.shared.effectiveAPIKey
        var components = URLComponents(string: "\(Config.unsplashBaseURL)/photos/random")!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "client_id", value: apiKey),
            URLQueryItem(name: "orientation", value: "landscape"),
            URLQueryItem(name: "count", value: "\(count)"),
        ]
        // Use Unsplash Topics API (topicId) for precise filtering
        if let topicId = category.topicId {
            items.append(URLQueryItem(name: "topics", value: topicId))
        }
        components.queryItems = items
        return components.url!
    }

    // MARK: - Editorial (/photos endpoint = Unsplash curated feed)

    private func fetchEditorialPhotos(count: Int) async throws -> [UnsplashPhoto] {
        let apiKey = WallpaperSettings.shared.effectiveAPIKey
        // Random page number for varied editorial content
        let page = Int.random(in: 1...50)
        var components = URLComponents(string: "\(Config.unsplashBaseURL)/photos")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: apiKey),
            URLQueryItem(name: "per_page", value: "\(count)"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "order_by", value: "latest"),
            URLQueryItem(name: "orientation", value: "landscape"),  // Add landscape parameter
        ]
        let photos = try await fetch([UnsplashPhoto].self, from: components.url!)
        guard !photos.isEmpty else { throw UnsplashError.noPhotosFound }
        return photos
    }
}
