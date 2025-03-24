//
//  Timer
//
//  Created by James Backhouse on 10/09/2024.
//

import SwiftUI
import UserNotifications

enum TimerStatus: Equatable {
  case idle
  case running
  case finished
  case paused
}

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

struct PressableButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.7 : 1.0)
      .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
      .background(.red)
      .opacity(0.9)
      .clipShape(Capsule())
      .shadow(color: .purple, radius: 1, x: 0, y: 0)
  }
}

let timerId = UUID().uuidString

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

struct MenuBar: View {
  @State private var timers: [String: TimerState] = [
    timerId: TimerState(
      timer: nil,
      status: .idle,
      value: 300.0,  // 5 minutes in seconds
      duration: 300.0,
      isHovered: false,
      createdAt: Date()
    )
  ]
  @State private var hasPermission = false
  @State private var isFinishMsgVisible = false

  func toggleTimer(name: String) {
    switch timers[name]?.status {
    case .idle:
      startTimer(name: name)
    case .paused:
      restartTimer(name: name)
    case .running:
      pauseTimer(name: name)
    case .finished, .none:
      break
    }
  }

  func pauseTimer(name: String) {
    if var state = timers[name], state.value > 0 {
      state.status = .paused
      timers[name] = state
    }
  }

  func restartTimer(name: String) {
    if var state = timers[name], state.value > 0 {
      state.status = .running
      timers[name] = state
    }
  }

  func startTimer(name: String) {
    if let existingTimer = timers[name]?.timer {
      existingTimer.invalidate()
    }

    let newTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
      _ in
      if var state = timers[name], state.value > 0, state.status == .running {
        state.value -= 1.0
        timers[name] = state

        if state.value <= 0 {
          stopTimer(name: name)
          fireNotification(duration: timers[name]?.duration)
        }
      }
    }

    timers[name] = TimerState(
      timer: newTimer,
      status: .running,
      value: timers[name]!.value,
      duration: timers[name]!.value,
      isHovered: false,
      createdAt: Date()  // TODO this is overwriting existing createdAt when called to start a paused timer
    )
  }

  func stopTimer(name: String) {
    if let existingTimer = timers[name]?.timer {
      existingTimer.invalidate()
    }

    var state =
      timers[name]
      ?? TimerState(
        timer: nil, status: .idle, value: 0, duration: 0, isHovered: false,
        createdAt: Date())
    state.timer = nil
    state.status = .finished
    timers[name] = state

    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
      if var state = timers[name] {
        state.status = .idle
        timers[name] = state
      }
    }
  }

  func deleteTimer(name: String) {
    timers.removeValue(forKey: name)
  }

  func onDisappear(name: String) {
    stopTimer(name: name)
  }

  private func timerRow(key: String, timerState: TimerState) -> some View {
    VStack {
      HStack {
        Image(
          systemName: timerState.isHovered && timers.count > 1
            ? "trash.circle.fill" : "hourglass.circle.fill"
        )
        .font(.system(size: 18))
        .padding(.leading, 20)
        .onHover { hovering in
          withAnimation {
            if var state = timers[key] {
              state.isHovered = hovering
              timers[key] = state
            }
          }
        }
        .onTapGesture {
          if timers.count > 1 {
            withAnimation {
              deleteTimer(name: key)
            }
          }
        }
        TextField(
          "mins",
          value: Binding(
            get: { timers[key]?.value ?? 0 },
            set: { newValue in
              if var state = timers[key] {
                state.value = newValue
                state.duration = newValue
                timers[key] = state
              }
            }
          ),
          formatter: TimeFormatter()
        )
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .frame(width: 60)
        .onSubmit {
          startTimer(name: key)
        }
        .disabled(timerState.status == .running)
        .textSelection(.enabled)
        .onTapGesture {
          if let textField = NSApp.keyWindow?.firstResponder as? NSTextField {
            textField.selectText(nil)
          }
        }

        if timerState.status == .finished {
          HStack {
            Image(systemName: "checkmark")
              .bold()
              .foregroundStyle(.green)
              .shadow(color: .blue, radius: 4, x: 0, y: 0)
              .padding(.leading, -4)
              .opacity(isFinishMsgVisible ? 1 : 0)
          }.frame(width: 20)
        } else {
          Button(
            action: {
              toggleTimer(name: key)
            },
            label: {
              HStack {
                Image(
                  systemName: timerState.status == .running
                    ? "pause" : "chevron.right"
                )
                .bold()
                .foregroundStyle(.primary)
                .font(.system(size: 12))
                .frame(width: 18, height: 18)
                .background(Circle().fill(.red))
              }
            }
          )
          .buttonStyle(PressableButtonStyle())
        }
      }
    }.padding(.bottom, 10)
  }

  private func permissionButton() -> some View {
    Button {
      getNotificationPermission { isPermissionGranted in
        hasPermission = isPermissionGranted
      }
    } label: {
      Text("Get permission")
    }
  }

  var body: some View {
    VStack(alignment: .center) {
      ScrollView {
        HStack(alignment: .center) {
          if !hasPermission {
            permissionButton()
          } else {
            VStack(spacing: 0) {
              ForEach(
                Array(timers).sorted(by: {
                  $0.value.createdAt < $1.value.createdAt
                }), id: \.key
              ) { key, timerState in
                timerRow(key: key, timerState: timerState)
              }
            }
          }
        }
        .frame(width: 140)
        .padding(.trailing, 20)
      }
      .frame(maxHeight: 200)
      .padding(.top, 14)

      Button {
        let newId = UUID().uuidString
        timers[newId] = TimerState(
          timer: nil,
          status: .idle,
          value: 300.0,
          duration: 300.0,
          isHovered: false,
          createdAt: Date()
        )
      } label: {
        Image(systemName: "plus.circle.fill")
          .font(.system(size: 18))
          .foregroundStyle(.white)
      }
      .buttonStyle(PressableButtonStyle())
      .padding(.init(top: 4, leading: 0, bottom: 10, trailing: 0))
    }
    .animation(.easeInOut(duration: 0.5), value: isFinishMsgVisible)
    .onAppear {
      getNotificationPermission { isPermissionGranted in
        hasPermission = isPermissionGranted
      }
    }
    .onChange(of: timers) { oldTimers, newTimers in
      if newTimers[timerId]?.status == .finished {
        withAnimation(.easeInOut(duration: 0.3)) {
          isFinishMsgVisible = true
        }
      } else if oldTimers[timerId]?.status == .finished {
        withAnimation(.easeInOut(duration: 0.3)) {
          isFinishMsgVisible = false
        }
      }
    }
  }
}

#Preview {
  MenuBar()
}
