// WallpaperCategory.swift
// Rylai ❄️

import Foundation
import SwiftUI

enum WallpaperCategory: String, CaseIterable, Codable, Identifiable {
    case featured         = "featured"
    case wallpapers       = "wallpapers"
    case renders3d        = "3d-renders"
    case nature           = "nature"
    case spring           = "spring"
    case textures         = "textures"
    case film             = "film"
    case architecture     = "architecture"
    case street           = "street"
    case experimental     = "experimental"
    case travel           = "travel"
    case people           = "people"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .featured:     return "⭐"
        case .wallpapers:   return "🖼️"
        case .renders3d:    return "🔮"
        case .nature:       return "🌿"
        case .spring:       return "🌸"
        case .textures:     return "🧩"
        case .film:         return "🎬"
        case .architecture: return "🏛️"
        case .street:       return "🏙️"
        case .experimental: return "🎨"
        case .travel:       return "✈️"
        case .people:       return "👤"
        }
    }

    var displayName: String {
        switch self {
        case .featured:     return "Featured"
        case .wallpapers:   return "Wallpapers"
        case .renders3d:    return "3D Renders"
        case .nature:       return "Nature"
        case .spring:       return "Spring"
        case .textures:     return "Textures"
        case .film:         return "Film"
        case .architecture: return "Architecture"
        case .street:       return "Street"
        case .experimental: return "Experimental"
        case .travel:       return "Travel"
        case .people:       return "People"
        }
    }

    var topicId: String? {
        switch self {
        case .featured:     return nil
        case .wallpapers:   return "bo8jQKTaE0Y"
        case .renders3d:    return "CDwuwXJAbEw"
        case .nature:       return "6sMVjTLSkeQ"
        case .spring:       return "Jr6fAMtfciU"
        case .textures:     return "iUIsnVtjB0Y"
        case .film:         return "hmenvQhUmxM"
        case .architecture: return "M8jVbLbTRws"
        case .street:       return "xHxYTMHLgOc"
        case .experimental: return "qPYsDzvJOYc"
        case .travel:       return "Fzo3zuOHN6w"
        case .people:       return "towJZFskpGg"
        }
    }

    var isEditorial: Bool { self == .featured }

    var accentColor: Color {
        switch self {
        case .featured:     return .yellow
        case .wallpapers:   return .blue
        case .renders3d:    return .pink
        case .nature:       return .green
        case .spring:       return .pink
        case .textures:     return .brown
        case .film:         return .gray
        case .architecture: return .orange
        case .street:       return .indigo
        case .experimental: return .purple
        case .travel:       return .cyan
        case .people:       return .teal
        }
    }
}
