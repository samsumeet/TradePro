//
//  ProfileView.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 05.10.25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    
    // Professional Trading App Colors
    private let primaryBackground = Color(red: 0.07, green: 0.09, blue: 0.12)
    private let secondaryBackground = Color(red: 0.10, green: 0.12, blue: 0.16)
    private let cardBackground = Color(red: 0.13, green: 0.15, blue: 0.19)
    private let accentBlue = Color(red: 0.20, green: 0.51, blue: 0.98)
    private let textPrimary = Color(red: 0.95, green: 0.96, blue: 0.97)
    private let textSecondary = Color(red: 0.60, green: 0.63, blue: 0.68)
    private let borderColor = Color(red: 0.18, green: 0.21, blue: 0.26)
    
    var body: some View {
        NavigationView {
            ZStack {
                primaryBackground.ignoresSafeArea()
                
                if authManager.isAuthenticated {
                    authenticatedView
                } else {
                    authenticationView
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
    }
    
    // MARK: - Authenticated View
    private var authenticatedView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Profile")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(textPrimary)
                    
                    Spacer()
                    
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Profile Card
                VStack(spacing: 20) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [accentBlue, accentBlue.opacity(0.6)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Text(authManager.currentUser?.initials ?? "?")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: accentBlue.opacity(0.3), radius: 15, x: 0, y: 8)
                    
                    // Name and Email
                    VStack(spacing: 8) {
                        Text(authManager.currentUser?.fullName ?? "User")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(textPrimary)
                        
                        Text(authManager.currentUser?.email ?? "")
                            .font(.system(size: 14))
                            .foregroundColor(textSecondary)
                        
                        // Premium Badge
                        if authManager.currentUser?.isPremium == true {
                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12))
                                Text("Premium Member")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.yellow.opacity(0.15))
                            .cornerRadius(20)
                        }
                    }
                    
                    // Edit Profile Button
                    Button(action: { showingEditProfile = true }) {
                        Text("Edit Profile")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(accentBlue)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(accentBlue.opacity(0.15))
                            .cornerRadius(20)
                    }
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
                .background(cardBackground)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
                .padding(.horizontal, 20)
                
                // Stats Cards
                HStack(spacing: 12) {
                    statCard(title: "Total Trades", value: "24", icon: "chart.line.uptrend.xyaxis")
                    statCard(title: "Win Rate", value: "68%", icon: "trophy.fill")
                    statCard(title: "P&L", value: "+$2.4K", icon: "dollarsign.circle.fill")
                }
                .padding(.horizontal, 20)
                
                // Menu Items
                VStack(spacing: 12) {
                    menuItem(icon: "person.circle", title: "Account Settings", action: {})
                    menuItem(icon: "bell.badge", title: "Notifications", action: {})
                    menuItem(icon: "lock.shield", title: "Privacy & Security", action: {})
                    menuItem(icon: "questionmark.circle", title: "Help & Support", action: {})
                    menuItem(icon: "star.fill", title: "Upgrade to Premium", action: {}, isHighlighted: true)
                    
                    // Sign Out
                    Button(action: { authManager.signOut() }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                            
                            Text("Sign Out")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderColor, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                // App Version
                Text("TradePro v1.0.0")
                    .font(.system(size: 12))
                    .foregroundColor(textSecondary)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(authManager)
        }
    }
    
    // MARK: - Authentication View
    private var authenticationView: some View {
        AuthenticationView()
            .environmentObject(authManager)
    }
    
    // MARK: - Helper Views
    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(accentBlue)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(textPrimary)
            
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
    }
    
    private func menuItem(icon: String, title: String, action: @escaping () -> Void, isHighlighted: Bool = false) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isHighlighted ? .yellow : accentBlue)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textSecondary)
            }
            .padding(16)
            .background(cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHighlighted ? Color.yellow.opacity(0.3) : borderColor, lineWidth: 1)
            )
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
}
