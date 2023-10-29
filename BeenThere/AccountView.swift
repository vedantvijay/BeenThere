//
//  AccountView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/22/23.
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices

struct AccountView: View {
    @ObservedObject var viewModel: AccountViewModel
    
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
                        ManageFriendsView(accountViewModel: viewModel)
                    }
                }
                Section {
                    Button("Sign Out") {
                        viewModel.signOut()
                        dismiss()
                    }
                    NavigationLink("Delete Account") {
                        ConfirmDeleteAccountView()
                    }
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AccountView(viewModel: AccountViewModel())
}
