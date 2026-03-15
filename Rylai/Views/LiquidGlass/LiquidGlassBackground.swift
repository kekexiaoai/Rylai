// LiquidGlassBackground.swift
// Rylai — Liquid Glass Background (macOS 12+ Compatible)

import SwiftUI
import AppKit

// MARK: - Liquid Glass Background (macOS 12+ Compatible)

struct LiquidGlassBackground: View {
    var intensity: Double = 0.85
    var cornerRadius: CGFloat = 20
    var tintColor: Color = .clear

    var body: some View {
        LiquidGlassFallback(intensity: intensity, cornerRadius: cornerRadius)
    }
}

// MARK: - Backward Compatible (NSVisualEffectView Wrapper)

struct LiquidGlassFallback: NSViewRepresentable {
    var intensity: Double
    var cornerRadius: CGFloat

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .withinWindow
        view.state = .active
        view.wantsLayer = true
        view.alphaValue = intensity
        view.layer?.masksToBounds = true

        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.alphaValue = intensity
        nsView.layer?.cornerRadius = cornerRadius
    }
}

// MARK: - Blurred Wallpaper Background

struct BlurredWallpaperBackground: View {
    var blurRadius: CGFloat = 50
    var opacity: Double = 0.4

    var body: some View {
        ZStack {
            LiquidGlassFallback(intensity: 0.72, cornerRadius: 0)

            // Additional blur overlay
            Rectangle()
                .fill(Color.black.opacity(opacity * 0.3))
                .blur(radius: blurRadius * 0.1)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    var content: () -> Content
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 12
    var backgroundColor: Color = .white.opacity(0.1)

    init(cornerRadius: CGFloat = 16, padding: CGFloat = 12, backgroundColor: Color = .white.opacity(0.1), @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.content = content
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(backgroundColor)

            content()
                .padding(padding)
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(colors: [
                        .white.opacity(0.2),
                        .white.opacity(0.05)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Pointer Cursor Modifier

struct PointerCursorModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

extension View {
    func pointerCursor() -> some View {
        self.modifier(PointerCursorModifier())
    }
}

// MARK: - Liquid Button

struct LiquidButton: View {
    var title: String
    var icon: String? = nil
    var emoji: String? = nil
    var isActive: Bool = false
    var isSelected: Bool = false
    var color: Color = .cyan
    var accentColor: Color? = nil
    var action: () -> Void
    @State private var isHovered = false
    @State private var isPressed = false

    private var effectiveColor: Color {
        accentColor ?? color
    }

    private var effectiveSelected: Bool {
        isActive || isSelected
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let emoji = emoji {
                    Text(emoji)
                        .font(.system(size: 12))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                Text(title)
                    .font(.system(size: 13, weight: effectiveSelected ? .semibold : .regular))
            }
            .foregroundStyle(effectiveSelected ? .white : effectiveColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(effectiveSelected ? effectiveColor : effectiveColor.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(effectiveColor.opacity(effectiveSelected ? 0 : 0.2), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .animation(.easeOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation {
                isHovered = hovering
            }
        }
        .onTapGesture {
            withAnimation {
                isPressed = true
            }
        }
        .pointerCursor()
    }

    // Convenience initializer for isActive parameter before action
    init(title: String, icon: String? = nil, emoji: String? = nil, isActive: Bool = false, color: Color = .cyan, accentColor: Color? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.emoji = emoji
        self.isActive = isActive
        self.isSelected = false
        self.color = color
        self.accentColor = accentColor
        self.action = action
    }
}

// MARK: - Ghost Icon Button

struct GhostIconButton: View {
    var icon: String
    var size: CGFloat = 16
    var color: Color = .primary
    var action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(isHovered ? 0.15 : 0))
                )
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation {
                isHovered = hovering
            }
        }
        .pointerCursor()
    }
}

// MARK: - Ghost Text Button

struct GhostTextButton: View {
    var text: String
    var icon: String? = nil
    var color: Color = .primary
    var fontSize: CGFloat = 13
    var action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: fontSize))
                }
                Text(text)
                    .font(.system(size: fontSize, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(color.opacity(isHovered ? 0.15 : 0))
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation {
                isHovered = hovering
            }
        }
        .pointerCursor()
    }
}

// MARK: - Liquid Toggle

struct LiquidToggle: View {
    var label: String
    var icon: String
    @Binding var isOn: Bool
    @State private var isHovered = false
    @State private var isDragging = false

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(isOn ? .cyan : .secondary)
                .frame(width: 24)

            // Label
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)

            Spacer()

            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .cyan))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isOn ? .cyan.opacity(0.1) : .white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isOn ? .cyan.opacity(0.3) : .white.opacity(0.1), lineWidth: 1)
        )
        .pointerCursor()
    }
}

// MARK: - Glass Divider

struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.2),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}
