//
//  Timer
//
//  Created by James Backhouse on 10/09/2024.
//

import SwiftUI
import UserNotifications

enum TimerStatus: String {
  case idle
  case running
  case finished
  case paused
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
  UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
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
    let minutes = duration / 60
    let formattedDuration = numberFormatter.string(from: NSNumber(value: minutes)) ?? String(minutes)
    content.title = "\(formattedDuration) minute timer finished"
  } else {
    content.title = "Timer finished"
  }
  content.subtitle = "C'est fini"
  content.sound = .default
  let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
  UNUserNotificationCenter.current().add(request)
}

struct PressableButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.7 : 1.0)
      .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
      .background(.red)
      .opacity(0.8)
      .clipShape(Capsule())
      .shadow(color: .purple, radius: 3, x: 0, y: 0)
  }
}

let timerId = UUID().uuidString

struct TimerState: Equatable {
  var timer: Timer?
  var status: TimerStatus
  var value: Double
  var duration: Double

  static func == (lhs: TimerState, rhs: TimerState) -> Bool {
    lhs.status == rhs.status && lhs.value == rhs.value && lhs.duration == rhs.duration
  }
}

struct MenuBar: View {
  @State private var timers: [String: TimerState] = [
    timerId: TimerState(
      timer: nil,
      status: .idle,
      value: 300.0, // 5 minutes in seconds
      duration: 300.0
    )
  ]
  @State private var hasPermission = false
  @State private var isFinishMsgVisible = false

  func toggleTimer(name: String) {
    print("toggle status: \(timers[name]?.status.rawValue ?? "none")")
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

    let newTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
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
      duration: timers[name]!.value
    )
  }

  func stopTimer(name: String) {
    if let existingTimer = timers[name]?.timer {
      existingTimer.invalidate()
    }

    var state = timers[name] ?? TimerState(timer: nil, status: .idle, value: 0, duration: 0)
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

  func onDisappear(name: String) {
    stopTimer(name: name)
  }

  private func timerRow(key: String, timerState: TimerState) -> some View {
    VStack {
      HStack {
        Image(systemName: "hourglass.circle.fill")
          .font(.title2)
          .padding(.leading, 20)

        TextField("mins", value: Binding(
          get: { (timers[key]?.value ?? 0) / 60 },
          set: { newValue in
            if var state = timers[key] {
              state.value = newValue * 60
              state.duration = newValue * 60
              timers[key] = state
            }
          }
        ), formatter: numberFormatter)
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

        Button(action: {
          toggleTimer(name: key)
        }, label: {
          HStack {
            Image(systemName: timerState.status == .running ? "pause" : "chevron.right")
              .bold()
              .foregroundStyle(.primary)
              .frame(width: 10)
              .padding(.horizontal, 6)
              .padding(.vertical, 3)
          }
        })
        .buttonStyle(PressableButtonStyle())

        HStack {
          if timerState.status == .finished {
            Image(systemName: "checkmark")
              .bold()
              .foregroundStyle(.green)
              .shadow(color: .blue, radius: 4, x: 0, y: 0)
              .padding(.leading, -4)
              .opacity(isFinishMsgVisible ? 1 : 0)
          }
        }.frame(width: 20)
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
              ForEach(Array(timers), id: \.key) { key, timerState in
                timerRow(key: key, timerState: timerState)
              }
            }
          }
        }
        .frame(width: 180)
      }
      .frame(maxHeight: 200)
      .padding(.top, 14)

      Button {
        let newId = UUID().uuidString
        timers[newId] = TimerState(timer: nil, status: .idle, value: 300.0, duration: 300.0)
      } label: {
        Image(systemName: "plus.circle.fill")
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
