import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var logoOpacity = 0.0
    @State private var logoScale = 0.8
    @State private var titleOffset = 50.0
    @State private var titleOpacity = 0.0
    
    var body: some View {
        ZStack {
            // Background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App Logo
                Image("trading-pro")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .opacity(logoOpacity)
                    .scaleEffect(logoScale)
                    .animation(.spring(response: 1.2, dampingFraction: 0.6, blendDuration: 0), value: logoScale)
                    .animation(.easeInOut(duration: 1.0), value: logoOpacity)
                
                // App Title
                Text("TradePro")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.8))
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
                    .animation(.easeInOut(duration: 0.8).delay(0.5), value: titleOpacity)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0).delay(0.5), value: titleOffset)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Start logo animation
        withAnimation(.easeInOut(duration: 1.0)) {
            logoOpacity = 1.0
        }
        
        withAnimation(.spring(response: 1.2, dampingFraction: 0.6, blendDuration: 0)) {
            logoScale = 1.0
        }
        
        // Start title animation with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.8)) {
                titleOpacity = 1.0
                titleOffset = 0
            }
        }
        
        // Add a subtle pulse animation to the logo
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                logoScale = 1.05
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
