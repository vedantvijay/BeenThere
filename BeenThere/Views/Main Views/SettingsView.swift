//
//  AccountView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/22/23.
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices
import AlertToast

struct SettingsView: View {
    @EnvironmentObject var viewModel: AccountViewModel
    @AppStorage("appState") var appState = "opening"

    @State private var showDeleteAccount = false

    @Environment(\.dismiss) var dismiss
    
    @State private var userPhoto: Image = Image("background1")
    @State private var isUsernameTaken: Bool = false
    @State private var showFriendView = false
//    @AppStorage("units") var units = "chunks"
    
    var body: some View {
            Form {
//                Section {
//                    Picker("Units", selection: $units) {
//                        ForEach(["chunks", "area"], id: \.self) {
//                            Text($0)
//                        }
//                    }
//                }
//                Section {
//                    Button("Sign Out") {
//                        viewModel.signOut()
//                        dismiss()
//                        appState = "notAuthenticated"
//                    }
//                    NavigationLink("Delete Account") {
//                        ConfirmDeleteAccountView()
//                            .environmentObject(viewModel)
//                    }
//                }
            }
            .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}
