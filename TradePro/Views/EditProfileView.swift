//
//  EditProfileView.swift
//  TradePro
//
//  Created by Sumeet Bachchas on 05.10.25.
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var fullName = ""
    
    private let cardBackground = Color(red: 0.13, green: 0.15, blue: 0.19)
    private let accentBlue = Color(red: 0.20, green: 0.51, blue: 0.98)
    private let textPrimary = Color(red: 0.95, green: 0.96, blue: 0.97)
    private let borderColor = Color(red: 0.18, green: 0.21, blue: 0.26)
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Full Name", text: $fullName)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        authManager.updateProfile(fullName: fullName)
                        dismiss()
                    }
                    .disabled(fullName.isEmpty)
                }
            }
        }
        .onAppear {
            fullName = authManager.currentUser?.fullName ?? ""
        }
    }
}
