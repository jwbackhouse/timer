import SwiftUI

let timerId = UUID().uuidString

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
