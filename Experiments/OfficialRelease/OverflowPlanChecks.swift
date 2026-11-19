import Foundation

@main
struct OverflowPlanChecks {
  static func main() {
    let scenarios: [[OverflowDisplay]] = [
      [.init(width: 2056, trailingWidth: nil)],
      [.init(width: 1512, trailingWidth: 663.5)],
      [.init(width: 1512, trailingWidth: 663.5), .init(width: 2560, trailingWidth: nil)],
      [.init(width: 1920, trailingWidth: nil), .init(width: 3840, trailingWidth: nil)],
    ]
    for displays in scenarios {
      guard let plan = OverflowPlan.propose(displays: displays) else {
        fatalError("Expected a covered geometry proposal")
      }
      precondition(displays.allSatisfy { plan.itemWidth < $0.proposedLimit })
      precondition(plan.itemWidth * Double(plan.itemCount) >= displays.map(\.area).max()!)
      precondition((1...7).contains(plan.itemCount))
      print("proposal width=\(plan.itemWidth) count=\(plan.itemCount)")
    }
    precondition(OverflowPlan.propose(displays: []) == nil)
    precondition(OverflowPlan.propose(displays: [.init(width: .nan, trailingWidth: nil)]) == nil)
    precondition(OverflowPlan.propose(displays: [.init(width: 100, trailingWidth: 180)]) == nil)
    precondition(OverflowPlan.propose(displays: [.init(width: 100, trailingWidth: nil)]) == nil)
    precondition(OverflowPlan.propose(displays: [
      .init(width: 1280, trailingWidth: 300), .init(width: 3840, trailingWidth: nil),
    ]) == nil)
    precondition(OverflowPlan.propose(displays: scenarios[0], maxItems: 0) == nil)
    print("PASS: proposal bounds, notch, mixed displays, insufficient capacity, invalid input")
  }
}
