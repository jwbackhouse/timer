import UserNotifications

func getNotificationPermission(completion: @escaping (Bool) -> Void) {
  UNUserNotificationCenter.current().requestAuthorization(options: [
    .alert, .badge, .sound,
  ]) { success, error in
    if success {
      completion(true)
    } else if let error {
      print("Error getting permissions: \(error.localizedDescription)")
      completion(false)
    } else {
      completion(false)
    }
  }
}

func fireNotification(duration: Double?) {
  let content = UNMutableNotificationContent()
  if let duration {
    let timeFormatter = TimeFormatter()
    let formattedDuration =
      timeFormatter.string(for: TimeInterval(duration)) ?? ""
    content.title = "\(formattedDuration) minute timer"
  } else {
    content.title = "Timer finished"
  }
  content.subtitle = "C'est fini"
  content.sound = .default
  let request = UNNotificationRequest(
    identifier: UUID().uuidString, content: content, trigger: nil)
  UNUserNotificationCenter.current().add(request)
}
