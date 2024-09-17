//
//  MenuBar.swift
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

func getNotificationPermission() {
  UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge]) { success, error in
    print("in getnotper")
    if success {
      print("All set")
    } else if let error {
      print("error: \(error.localizedDescription)")
    }
  }
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

struct MenuBar: View {
  @State private var timerValue: Double = 0.0
  @State private var timer: Timer?
  @State private var status: TimerStatus = .idle

  let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.allowsFloats = true
    return formatter
  }()

  func startTimer() {
    stopTimer()
    print("starting")
    status = .running

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
        self.stopTimer()
        // Show notification immediately
        let content = UNMutableNotificationContent()
        content.title = "Timer done"
        content.subtitle  = "C'est le fin"
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
          status = .idle
        }
      }
    }
  }

  func stopTimer() {
    timer?.invalidate()
    timer = nil
    // withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 1.0)) {
//    withAnimation(.bouncy) {
    //    }
    status = .finished
    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
      withAnimation {
        status = .idle
      }
    }
  }

  func onDisappear() {
    stopTimer()
  }

  var body: some View {
    VStack(alignment: .center) {
      HStack(alignment: .center) {
        Button {
          getNotificationPermission()
        } label: {
          Text("Get permission")
        }
        HStack {
          Image(systemName: "hourglass.circle.fill")
            .font(.title2)
          TextField("mins", value: $timerValue, formatter: numberFormatter)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: 60)
            .onSubmit {
              startTimer()
            }
            .disabled(status == .running)
        }

        Button(action: {
          startTimer()
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
        .disabled(status == .running)
      }
      .padding()
      .onDisappear(perform: onDisappear)
//      .frame(height: 200)

      Spacer()

      if status == .finished {
        Text("All done")
          .bold()
          .foregroundColor(.pink)
          .padding(.bottom)
          .shadow(color: .purple, radius: 4, x: 0, y: 0)
          .transition(.opacity)
      }
    }
//    .animation(.easeInOut(duration: 1), value: status)
//    .frame(minHeight: 200, maxHeight: status == .finished ? 500 : 200)
  }
}

#Preview {
  @State var status = TimerStatus.running
  return MenuBar()
}
