// GalleryView.swift
// Rylai ❄️ — Gallery (Favorites + History)

import SwiftUI

struct GalleryView: View {
    @ObservedObject private var settings = WallpaperSettings.shared
    @State private var selectedTab: GalleryTab = .history
    @State private var selectedPhoto: UnsplashPhoto?
    
    enum GalleryTab: String, CaseIterable {
        case history  = "History"
        case favorites = "Favorites"
        
        var icon: String {
            switch self {
            case .history:   return "clock"
            case .favorites: return "heart"
            }
        }
    }
    
    var body: some View {
        ZStack {
            BlurredWallpaperBackground(blurRadius: 50, opacity: 0.4)
            
            VStack(spacing: 0) {
                // Tab selection
                HStack(spacing: 0) {
                    ForEach(GalleryTab.allCases, id: \.self) { tab in
                        LiquidButton(
                            title: tab.rawValue,
                            icon: tab.icon,
                            isActive: selectedTab == tab,
                            action: { selectedTab = tab }
                        )
                    }
                    Spacer()
                }
                .padding(12)
                
                GlassDivider()
                
                // Grid content
                ScrollView {
                    let photos: [UnsplashPhoto] = selectedTab == .history
                        ? settings.history
                        : settings.history.filter { settings.isFavorited($0) }
                    
                    if photos.isEmpty {
                        emptyState(for: selectedTab)
                    } else {
                        photoGrid(photos: photos)
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo)
        }
    }
    
    // MARK: - Photo Grid
    
    private func photoGrid(photos: [UnsplashPhoto]) -> some View {
        LazyVGrid(
            columns: Array(repeating: .init(.flexible(), spacing: 8), count: 4),
            spacing: 8
        ) {
            ForEach(photos) { photo in
                PhotoCardView(
                    photo: photo,
                    isFavorited: settings.isFavorited(photo)
                ) {
                    selectedPhoto = photo
                } onFavorite: {
                    settings.toggleFavorite(photo)
                }
            }
        }
        .padding(12)
    }
    
    // MARK: - Empty State
    
    private func emptyState(for tab: GalleryTab) -> some View {
        VStack(spacing: 12) {
            Image(systemName: tab == .history ? "clock" : "heart")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text(tab == .history ? "No history yet" : "No favorites yet")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - Photo Card

struct PhotoCardView: View {
    let photo: UnsplashPhoto
    let isFavorited: Bool
    var onTap: () -> Void
    var onFavorite: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail
            Button(action: onTap) {
                AsyncImage(url: URL(string: photo.urls.small)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.quaternary)
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay { ProgressView().scaleEffect(0.7) }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.white.opacity(isHovered ? 0.4 : 0.1), lineWidth: 1)
                }
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .animation(.spring(response: 0.2), value: isHovered)
            }
            .buttonStyle(.plain)
            .pointerCursor()
            .onHover { isHovered = $0 }
            
            // Favorite button (visible on hover)
            if isHovered || isFavorited {
                Button(action: onFavorite) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundStyle(isFavorited ? .red : .white)
                        .padding(6)
                        .background(.black.opacity(0.4))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .pointerCursor()
                .padding(6)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.2), value: isHovered)
            }
        }
    }
}

// MARK: - Photo Detail

struct PhotoDetailView: View {
    let photo: UnsplashPhoto
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var settings = WallpaperSettings.shared
    
    var body: some View {
        ZStack {
            // Background
            AsyncImage(url: URL(string: photo.urls.regular)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: { Color.black }
            .blur(radius: 20)
            .opacity(0.4)
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Main image
                AsyncImage(url: URL(string: photo.urls.regular)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(radius: 20)
                
                // Info card
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(photo.displayTitle)
                                .font(.system(size: 14, weight: .medium))
                            Text("by \(photo.user.name)")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 10) {
                            // Favorite
                            Button {
                                settings.toggleFavorite(photo)
                            } label: {
                                Image(systemName: settings.isFavorited(photo) ? "heart.fill" : "heart")
                            }
                            .foregroundStyle(settings.isFavorited(photo) ? .red : .primary)
                            .pointerCursor()

                            // View on Unsplash
                            Link(destination: URL(string: photo.links.html)!) {
                                Label("Unsplash", systemImage: "arrow.up.right.square")
                                    .font(.system(size: 12))
                            }
                            .pointerCursor()
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Button("Close") { dismiss() }
                    .buttonStyle(.plain)
                    .pointerCursor()
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
