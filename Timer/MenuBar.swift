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

func fireNotification(name: String) {
  let content = UNMutableNotificationContent()
  content.title = "Timer done for \(name)"
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

struct MenuBar: View {
  @State private var timerValue: Double = 0.0
  @State private var timer: Timer?
  @State private var status: [String: TimerStatus] = [timerId: .idle]
  @State private var hasPermission = false
  @State private var isFinishMsgVisible = false
  

  let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.allowsFloats = true
    return formatter
  }()

  func startTimer(name: String) {
    stopTimer(name: name)
    status[name] = .running
    print("start timer \(status)")

    guard timerValue > 0 else {
      print("Timer value must be positive")
      return
    }

    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      if timerValue > 0 {
        withAnimation {
          self.timerValue -= 1.0
        }
      } else {
        self.stopTimer(name: name)
        fireNotification(name: name)

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
          status[name] = .idle
        }
      }
    }
  }

  func stopTimer(name: String) {
    timer?.invalidate()
    timer = nil
    status[name] = .finished
    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
      status[name]  = .idle
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
            ForEach(Array(status), id: \.key) { key, value in
              
              HStack {
                Image(systemName: "hourglass.circle.fill")
                  .font(.title2)
                
                TextField("mins", value: $timerValue, formatter: numberFormatter)
                  .textFieldStyle(RoundedBorderTextFieldStyle())
                  .frame(width: 60)
                  .onSubmit {
                    startTimer(name: key)
                  }
                  .disabled(status[key] == .running)
                
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
                .disabled(status[key] == .running)
              }
              
              if status[timerId] == .finished {
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
//      .onDisappear(perform: onDisappear(name: name))

      Button {
        let newId = UUID().uuidString
        status[newId] = .idle
        
      } label: {
        Image(systemName: "plus.circle.fill")
      }.buttonStyle(PressableButtonStyle())
        .padding(.bottom)
    }
    .animation(.easeInOut(duration: 0.5), value: isFinishMsgVisible)
    .onAppear {
      getNotificationPermission { isPermissionGranted in
        hasPermission = isPermissionGranted
      }
    }
    .onChange(of: status) { oldStatus, newStatus in
      if newStatus[timerId] == .finished {
        withAnimation(.easeInOut(duration: 0.5)) {
          isFinishMsgVisible = true
        }
      } else if oldStatus[timerId] == .finished {
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
