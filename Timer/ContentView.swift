import SwiftUI


struct ContentView: View {
  var body: some View {
    VStack {
      Image(systemName: "deskclock")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello, world!")
    }
    .padding()
  }
}

#Preview {
  ContentView()
}
