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

struct AccountView: View {
    @EnvironmentObject var viewModel: AccountViewModel
    @AppStorage("appState") var appState = "opening"

    @State private var showDeleteAccount = false

    @Environment(\.dismiss) var dismiss
    
    @State private var userPhoto: Image = Image("background1")
    @State private var isUsernameTaken: Bool = false
    
    @State private var showFriendView = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink("Manage Friends") {
                        ManageFriendsView()
                    }
                }
                Section {
                    NavigationLink("Change Username") {
                        ChangeUsernameView()
                    }
                }
                Section {
                    Button("Sign Out") {
                        viewModel.signOut()
                        dismiss()
                        appState = "notAuthenticated"
                    }
                    NavigationLink("Delete Account") {
                        ConfirmDeleteAccountView()
                    }
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toast(isPresenting: $viewModel.usernameChanged) {
                AlertToast(displayMode: .alert, type: .complete(.green), title: "Username changed")
            }
        }
    }
}
//
//#Preview {
//    AccountView(viewModel: AccountViewModel)
//}
