//
//  AuthenticationView.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 05.10.25.
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isSignUp = false
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    
    // Professional Trading App Colors
    private let primaryBackground = Color(red: 0.07, green: 0.09, blue: 0.12)
    private let secondaryBackground = Color(red: 0.10, green: 0.12, blue: 0.16)
    private let cardBackground = Color(red: 0.13, green: 0.15, blue: 0.19)
    private let accentBlue = Color(red: 0.20, green: 0.51, blue: 0.98)
    private let textPrimary = Color(red: 0.95, green: 0.96, blue: 0.97)
    private let textSecondary = Color(red: 0.60, green: 0.63, blue: 0.68)
    private let borderColor = Color(red: 0.18, green: 0.21, blue: 0.26)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer().frame(height: 40)
                
                // Logo and Title
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(accentBlue)
                        .shadow(color: accentBlue.opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    Text("TradePro")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(textPrimary)
                    
                    Text(isSignUp ? "Create your account" : "Welcome back")
                        .font(.system(size: 16))
                        .foregroundColor(textSecondary)
                }
                .padding(.bottom, 20)
                
                // Form Card
                VStack(spacing: 20) {
                    // Full Name (Sign Up only)
                    if isSignUp {
                        customTextField(
                            icon: "person",
                            placeholder: "Full Name",
                            text: $fullName
                        )
                    }
                    
                    // Email
                    customTextField(
                        icon: "envelope",
                        placeholder: "Email",
                        text: $email
                    )
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    
                    // Password
                    HStack(spacing: 12) {
                        Image(systemName: "lock")
                            .font(.system(size: 18))
                            .foregroundColor(accentBlue)
                            .frame(width: 24)
                        
                        Group {
                            if showPassword {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .font(.system(size: 16))
                        .foregroundColor(textPrimary)
                        
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .font(.system(size: 16))
                                .foregroundColor(textSecondary)
                        }
                    }
                    .padding(16)
                    .background(secondaryBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 1.5)
                    )
                    
                    // Confirm Password (Sign Up only)
                    if isSignUp {
                        customTextField(
                            icon: "lock.fill",
                            placeholder: "Confirm Password",
                            text: $confirmPassword,
                            isSecure: true
                        )
                    }
                    
                    // Error Message
                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Action Button
                    Button(action: handleAuthentication) {
                        HStack(spacing: 10) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: isSignUp ? "person.badge.plus" : "arrow.right.circle.fill")
                                    .font(.system(size: 18))
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .font(.system(size: 17, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [accentBlue, accentBlue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: accentBlue.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .disabled(authManager.isLoading)
                    
                    // Toggle Sign Up/Sign In
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isSignUp.toggle()
                            authManager.errorMessage = nil
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(textSecondary)
                            Text(isSignUp ? "Sign In" : "Sign Up")
                                .foregroundColor(accentBlue)
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 14))
                    }
                    .padding(.top, 8)
                }
                .padding(24)
                .background(cardBackground)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .background(primaryBackground.ignoresSafeArea())
    }
    
    // MARK: - Custom Text Field
    private func customTextField(icon: String, placeholder: String, text: Binding<String>, isSecure: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(accentBlue)
                .frame(width: 24)
            
            if isSecure {
                SecureField(placeholder, text: text)
                    .font(.system(size: 16))
                    .foregroundColor(textPrimary)
            } else {
                TextField(placeholder, text: text)
                    .font(.system(size: 16))
                    .foregroundColor(textPrimary)
            }
        }
        .padding(16)
        .background(secondaryBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1.5)
        )
    }
    
    // MARK: - Handle Authentication
    private func handleAuthentication() {
        Task {
            if isSignUp {
                guard password == confirmPassword else {
                    authManager.errorMessage = "Passwords do not match"
                    return
                }
                await authManager.signUp(fullName: fullName, email: email, password: password)
            } else {
                await authManager.signIn(email: email, password: password)
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
}
