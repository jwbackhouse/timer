import Foundation

class TimeFormatter: Formatter {
  private let formatter: DateComponentsFormatter = {
    let f = DateComponentsFormatter()
    f.allowedUnits = [.minute, .second]
    f.zeroFormattingBehavior = [.pad]
    return f
  }()

  // Converts input into mm:ss
  override func string(for obj: Any?) -> String? {
    guard let seconds = obj as? Double else { return nil }
    return formatter.string(from: TimeInterval(seconds))
  }

  // Ensures that even while editing, the formatted string is used.
  override func editingString(for object: Any?) -> String? {
    return string(for: object)
  }

  override func getObjectValue(
    _ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
    for string: String,
    errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
  ) -> Bool {
    if string.contains(":") {

      let parts = string.split(separator: ":").map(String.init)
      guard parts.count == 2,
        let minutes = Double(parts[0]),
        let seconds = Double(parts[1])
      else {
        error?.pointee = "Invalid format. Use mm:ss" as NSString
        return false
      }
      let totalSeconds = minutes * 60 + seconds
      obj?.pointee = totalSeconds as AnyObject
      return true
    } else {
      // No colon, so assume user entered minutes
      guard let minutes = Int(string.trimmingCharacters(in: .whitespaces))
      else {
        error?.pointee = "Invalid number" as NSString
        return false
      }
      let totalSeconds = minutes * 60
      obj?.pointee = totalSeconds as AnyObject
      return true
    }
  }
}

let numberFormatter: NumberFormatter = {
  let formatter = NumberFormatter()
  formatter.numberStyle = .decimal
  formatter.allowsFloats = true
  formatter.minimumFractionDigits = 0
  formatter.maximumFractionDigits = 1
  return formatter
}()
