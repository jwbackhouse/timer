import SwiftUI

@main
struct TimerApp: App {
  var body: some Scene {
    MenuBarExtra("Timertronics", systemImage: "deskclock") {
      MenuBar()
    }.menuBarExtraStyle(.window)

    WindowGroup {
      ContentView()
    }
  }
}
