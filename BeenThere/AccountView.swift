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
    
    var body: some View {
        Form {
            NavigationLink("Manage Friends") {
                ManageFriendsView(accountViewModel: viewModel)
            }
            NavigationLink("Setttings") {
                SettingsView()
            }
        }
    }
}

#Preview {
    AccountView(viewModel: AccountViewModel())
}
