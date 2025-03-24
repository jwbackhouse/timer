import Foundation

struct TimerState: Equatable {
  var timer: Timer?
  var status: TimerStatus
  var value: Double
  var duration: Double
  var isHovered: Bool
  var createdAt: Date

  static func == (lhs: TimerState, rhs: TimerState) -> Bool {
    lhs.status == rhs.status && lhs.value == rhs.value
      && lhs.duration == rhs.duration && lhs.isHovered == rhs.isHovered
      && lhs.createdAt == rhs.createdAt
  }
}
