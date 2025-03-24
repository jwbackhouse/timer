import SwiftUI

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
