//
//  TimerApp.swift
//  Timer
//
//  Created by James Backhouse on 10/09/2024.
//

import SwiftUI

@main
struct TimerApp: App {
  var body: some Scene {
    MenuBarExtra("Timertronics", systemImage: "deskclock") {
      MenuBar()
      //      ContentView()
      //        .frame(width: 300, height: 150)
    }.menuBarExtraStyle(.window)

    WindowGroup {
      ContentView()
    }
  }
}
