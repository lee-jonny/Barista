import Foundation

/// Experimental capacity planning for OWN status items only.
/// The drop threshold is an empirical hypothesis, not an AppKit guarantee.
struct OverflowDisplay: Sendable {
  let width: Double
  let trailingWidth: Double?

  var area: Double { trailingWidth ?? width }
  var proposedLimit: Double { trailingWidth == nil ? width / 2 : area * 0.75 }
}

struct OverflowPlan: Equatable, Sendable {
  let itemWidth: Double
  let itemCount: Int

  static func propose(displays: [OverflowDisplay], maxItems: Int = 7) -> OverflowPlan? {
    guard !displays.isEmpty, (1...7).contains(maxItems),
      displays.allSatisfy({
        $0.width.isFinite && $0.width > 0 && $0.area.isFinite && $0.area > 0
          && $0.area <= $0.width
      }),
      let limit = displays.map(\.proposedLimit).min(),
      let widest = displays.map(\.area).max()
    else { return nil }
    let width = floor(limit - 64)
    guard width >= 32 else { return nil }
    let required = ceil(widest / width)
    // Do not silently under-cover a very asymmetric display arrangement.
    guard required.isFinite, required >= 1, required <= Double(maxItems) else { return nil }
    return OverflowPlan(itemWidth: width, itemCount: Int(required))
  }
}
