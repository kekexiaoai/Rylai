#!/usr/bin/swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// macOS app icon corner radius ratio (approximately 22.37% for 1024x1024)
// Icon content should be scaled to ~85% to leave proper padding
func addRoundedCorners(to imagePath: String, outputPath: String, size: Int, cornerRadius: CGFloat, contentScale: CGFloat = 0.85) {
    guard let imageSource = CGImageSourceCreateWithURL(URL(fileURLWithPath: imagePath) as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
        print("Failed to load image: \(imagePath)")
        return
    }

    let width = CGFloat(size)
    let height = CGFloat(size)

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        print("Failed to create context")
        return
    }

    // Clear background (transparent)
    context.clear(CGRect(x: 0, y: 0, width: width, height: height))

    // Create rounded rect path
    let rect = CGRect(x: 0, y: 0, width: width, height: height)
    let path = CGPath(
        roundedRect: rect,
        cornerWidth: cornerRadius,
        cornerHeight: cornerRadius,
        transform: nil
    )

    // Clip to rounded rect
    context.addPath(path)
    context.clip()

    // Calculate scaled content rect (85% of size, centered)
    let contentSize = width * contentScale
    let contentOffset = (width - contentSize) / 2
    let contentRect = CGRect(x: contentOffset, y: contentOffset, width: contentSize, height: contentSize)

    // Draw image scaled to fit within padding
    context.draw(image, in: contentRect)

    guard let roundedImage = context.makeImage() else {
        print("Failed to create rounded image")
        return
    }

    // Save to file
    let outputURL = URL(fileURLWithPath: outputPath)
    guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        print("Failed to create destination")
        return
    }

    CGImageDestinationAddImage(destination, roundedImage, nil)
    CGImageDestinationFinalize(destination)

    print("Created: \(outputPath)")
}

// macOS icon sizes and their corner radii
// Corner radius formula: size * 0.2237 (approximately 22.37% of size)
let iconSizes: [(size: Int, cornerRadius: CGFloat)] = [
    (16, 3.5),
    (32, 7),
    (64, 14),
    (128, 28),
    (256, 56),
    (512, 112),
    (1024, 224)
]

let currentDir = FileManager.default.currentDirectoryPath
let appIconsetPath = "\(currentDir)/Rylai/Resources/Assets.xcassets/AppIcon.appiconset"

// Always use the original square icon as source
let sourceIcon = "\(appIconsetPath)/icon_original.png"

print("Adding rounded corners to app icons with 15% padding...")
print("Source: \(sourceIcon)")
print("")

for (size, cornerRadius) in iconSizes {
    let outputPath = "\(appIconsetPath)/icon_\(size)x\(size).png"
    addRoundedCorners(to: sourceIcon, outputPath: outputPath, size: size, cornerRadius: cornerRadius)
}

print("")
print("Done! Icons created with rounded corners and proper padding.")
