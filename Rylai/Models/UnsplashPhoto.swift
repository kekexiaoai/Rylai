// UnsplashPhoto.swift
// Rylai

import Foundation

// MARK: - Unsplash API Response Models

struct UnsplashPhoto: Identifiable, Codable, Hashable {
    let id: String
    let description: String?
    let altDescription: String?
    let color: String?
    let width: Int
    let height: Int
    let urls: PhotoURLs
    let user: UnsplashUser
    let links: PhotoLinks
    let likes: Int
    let topicSubmissions: [String: TopicStatus]?

    // Local cache path (not serialized)
    var localCachePath: URL?

    enum CodingKeys: String, CodingKey {
        case id, description, color, width, height, urls, user, links, likes
        case altDescription = "alt_description"
        case topicSubmissions = "topic_submissions"
    }

    var displayTitle: String {
        description ?? altDescription ?? "Photo by \(user.name)"
    }
}

/// Unsplash topic_submissions value (status and other fields)
struct TopicStatus: Codable, Hashable {
    let status: String?
    let approvedOn: String?

    enum CodingKeys: String, CodingKey {
        case status
        case approvedOn = "approved_on"
    }
}

struct PhotoURLs: Codable, Hashable {
    let raw: String
    let full: String
    let regular: String    // 1080px
    let small: String      // 400px
    let thumb: String      // 200px

    /// Always returns 4K landscape (3840px) wallpaper URL
    func bestURL(for screenSize: CGSize) -> URL? {
        // Use raw URL with Unsplash image processing params, locked to 4K output
        guard var components = URLComponents(string: raw) else {
            return URL(string: full)
        }
        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: "w", value: "3840"))
        items.append(URLQueryItem(name: "q", value: "85"))
        items.append(URLQueryItem(name: "fit", value: "max"))
        items.append(URLQueryItem(name: "fm", value: "jpg"))
        components.queryItems = items
        return components.url ?? URL(string: full)
    }
}

struct UnsplashUser: Codable, Hashable {
    let id: String
    let username: String
    let name: String
    let portfolioURL: String?

    enum CodingKeys: String, CodingKey {
        case id, username, name
        case portfolioURL = "portfolio_url"
    }
}

struct PhotoLinks: Codable, Hashable {
    let `self`: String
    let html: String
    let download: String
    let downloadLocation: String

    enum CodingKeys: String, CodingKey {
        case `self` = "self"
        case html, download
        case downloadLocation = "download_location"
    }
}

// MARK: - Search Results

struct UnsplashSearchResult: Codable {
    let total: Int
    let totalPages: Int
    let results: [UnsplashPhoto]

    enum CodingKeys: String, CodingKey {
        case total, results
        case totalPages = "total_pages"
    }
}
