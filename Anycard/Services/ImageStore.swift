import UIKit

/// Stores user-picked photos (pass backgrounds and photographed codes) as
/// JPEG files in Application Support, referenced from `Card` by filename.
@MainActor
enum ImageStore {
    private static let cache = NSCache<NSString, UIImage>()

    private static var directory: URL {
        let url = URL.applicationSupportDirectory.appending(path: "Anycard/Images")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Saves picked image data, downscaled for display, and returns the filename.
    static func save(_ data: Data) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        let scaled = image.scaledToFit(maxDimension: 1400)
        guard let jpeg = scaled.jpegData(compressionQuality: 0.85) else { return nil }
        let name = UUID().uuidString + ".jpg"
        do {
            try jpeg.write(to: directory.appending(path: name), options: .atomic)
            cache.setObject(scaled, forKey: name as NSString)
            return name
        } catch {
            return nil
        }
    }

    static func image(named name: String?) -> UIImage? {
        guard let name else { return nil }
        if let cached = cache.object(forKey: name as NSString) { return cached }
        guard let image = UIImage(contentsOfFile: directory.appending(path: name).path()) else {
            return nil
        }
        cache.setObject(image, forKey: name as NSString)
        return image
    }
}

private extension UIImage {
    func scaledToFit(maxDimension: CGFloat) -> UIImage {
        let largest = max(size.width, size.height)
        guard largest > maxDimension else { return self }
        let scale = maxDimension / largest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
