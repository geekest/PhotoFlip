import Foundation
import CoreLocation

/// Reverse-geocodes a `CLLocation` into a short Chinese-friendly place name
/// like "上海市 · 黄浦区". Caches results in-memory keyed by `PHAsset.localIdentifier`
/// so we don't hit Apple's geocoding rate limit when revisiting cards.
@MainActor
enum LocationResolver {
    private static var cache: [String: String] = [:]

    static func cached(for assetID: String) -> String? {
        cache[assetID]
    }

    /// Returns a formatted place name, or nil if reverse-geocoding fails (offline,
    /// rate-limited, no matching placemark, or task cancelled).
    static func resolve(location: CLLocation, assetID: String) async -> String? {
        if let hit = cache[assetID] { return hit }
        // Fresh geocoder per call: a single instance only handles one request at
        // a time, so reusing one would serialize otherwise-cancellable requests.
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }
            let name = format(placemark)
            cache[assetID] = name
            return name
        } catch {
            return nil
        }
    }

    private static func format(_ p: CLPlacemark) -> String {
        var parts: [String] = []
        // 省 / 直辖市（仅当与 locality 不同才加，避免"上海市 · 上海市"）
        if let admin = p.administrativeArea, !admin.isEmpty, admin != p.locality {
            parts.append(admin)
        }
        if let locality = p.locality, !locality.isEmpty {
            parts.append(locality)
        }
        if let sub = p.subLocality, !sub.isEmpty, sub != p.locality {
            parts.append(sub)
        }
        if parts.isEmpty {
            return p.name ?? p.country ?? "未知位置"
        }
        return parts.joined(separator: " · ")
    }
}
