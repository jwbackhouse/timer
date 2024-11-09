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
}

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
  content.title = "Timer done for \(duration)"
  content.subtitle = "C'est fini"
  content.sound = .default
  let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
  UNUserNotificationCenter.current().add(request)
}

struct PressableButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.5 : 1.0)
      .animation(.easeInOut(duration: 0.6), value: configuration.isPressed)
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
  var duration: Int
  
  static func == (lhs: TimerState, rhs: TimerState) -> Bool {
    lhs.status == rhs.status && lhs.value == rhs.value && lhs.duration == rhs.duration
  }
}

struct MenuBar: View {
  @State private var timers: [String: TimerState] = [:]
  @State private var hasPermission = false
  @State private var isFinishMsgVisible = false
  

  let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.allowsFloats = true
    return formatter
  }()

  func startTimer(name: String) {
    if let existingTimer = timers[name]?.timer {
      existingTimer.invalidate()
    }
    
    let newTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      if var state = timers[name], state.value > 0 {
        state.value -= 1.0
        timers[name] = state
        
        if state.value <= 0 {
          stopTimer(name: name)
          fireNotification(duration: timers[name]?.value)
        }
      }
    }
    
    timers[name] = TimerState(
      timer: newTimer,
      status: .running,
      value: timers[name]?.value ?? 5.0,
      duration: 0
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

  var body: some View {
    VStack(alignment: .center) {
      HStack(alignment: .center) {
        if !hasPermission {
          Button {
            getNotificationPermission { isPermissionGranted in
              hasPermission = isPermissionGranted
            }
          } label: {
            Text("Get permission")
          }
        } else {
          VStack {
            ForEach(Array(timers), id: \.key) { key, timerState in
              HStack {
                Image(systemName: "hourglass.circle.fill")
                  .font(.title2)
                
                TextField("mins", value: Binding(
                  get: { timers[key]?.value ?? 0 },
                  set: { newValue in
                    if var state = timers[key] {
                      state.value = newValue
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
                
                Button(action: {
                  startTimer(name: key)
                }, label: {
                  HStack {
                    Image(systemName: "chevron.right")
                      .bold()
                      .foregroundStyle(.primary)
                      .padding(.horizontal, 6)
                      .padding(.vertical, 3)
                  }
                })
                .buttonStyle(PressableButtonStyle())
                .disabled(timerState.status == .running)
              }
              
              if timerState.status == .finished {
                Text("All done")
                  .bold()
                  .foregroundColor(.pink)
                  .padding(.bottom)
                  .shadow(color: .purple, radius: 4, x: 0, y: 0)
                  .opacity(isFinishMsgVisible ? 1 : 0)
              }
            }
          }
        }
      }
      .padding()
      .frame(width: 200)

      Button {
        let newId = UUID().uuidString
        timers[newId] = TimerState(timer: nil, status: .idle, value: 5.0, duration: 5)
      } label: {
        Image(systemName: "plus.circle.fill")
      }
      .buttonStyle(PressableButtonStyle())
      .padding(.bottom)
    }
    .animation(.easeInOut(duration: 0.5), value: isFinishMsgVisible)
    .onAppear {
      getNotificationPermission { isPermissionGranted in
        hasPermission = isPermissionGranted
      }
    }
    .onChange(of: timers) { oldTimers, newTimers in
      if newTimers[timerId]?.status == .finished {
        withAnimation(.easeInOut(duration: 0.5)) {
          isFinishMsgVisible = true
        }
      } else if oldTimers[timerId]?.status == .finished {
        withAnimation(.easeInOut(duration: 0.5)) {
          isFinishMsgVisible = false
        }
      }
    }
  }
}

#Preview {
  @Previewable @State var status = TimerStatus.running
  return MenuBar()
}
