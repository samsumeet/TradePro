//
//  AuthenticationManager.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 05.10.25.
//

import Foundation
import SwiftUI

class AuthenticationManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let userDefaultsKey = "currentUser"
    
    init() {
        loadUser()
    }
    
    // Sign Up
    func signUp(fullName: String, email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Validate
        guard !fullName.isEmpty, !email.isEmpty, password.count >= 6 else {
            await MainActor.run {
                errorMessage = "Please fill all fields. Password must be at least 6 characters."
                isLoading = false
            }
            return
        }
        
        guard email.contains("@") else {
            await MainActor.run {
                errorMessage = "Please enter a valid email address"
                isLoading = false
            }
            return
        }
        
        // Create user
        let newUser = User(fullName: fullName, email: email)
        
        await MainActor.run {
            currentUser = newUser
            isAuthenticated = true
            isLoading = false
            saveUser()
        }
    }
    
    // Sign In
    func signIn(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Validate
        guard !email.isEmpty, !password.isEmpty else {
            await MainActor.run {
                errorMessage = "Please enter email and password"
                isLoading = false
            }
            return
        }
        
        // For demo: any email/password combination works
        let user = User(fullName: "Demo User", email: email)
        
        await MainActor.run {
            currentUser = user
            isAuthenticated = true
            isLoading = false
            saveUser()
        }
    }
    
    // Sign Out
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // Update Profile
    func updateProfile(fullName: String) {
        guard var user = currentUser else { return }
        user.fullName = fullName
        currentUser = user
        saveUser()
    }
    
    // Save to UserDefaults
    private func saveUser() {
        guard let user = currentUser else { return }
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    // Load from UserDefaults
    private func loadUser() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return
        }
        currentUser = user
        isAuthenticated = true
    }
}
