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
    
    @Environment(\.dismiss) var dismiss
    
    @State private var userPhoto: Image = Image("background1")
    @State private var isUsernameTaken: Bool = false
    
    var body: some View {
        VStack {
                VStack {
                    Text("\(viewModel.firstName) \(viewModel.lastName)")
                        .font(.title2)
                        .fontWeight(.black)
                        .padding()
                    if viewModel.username != "" {
                        Text(viewModel.username)
                            .font(.title3)
                            .fontWeight(.bold)
                            .italic()
                    } else {
                        NavigationLink("Create Username") {
                            CreateUsernameView(accountViewModel: viewModel)
                        }

                    }
                }
            Form {
                NavigationLink("Manage Friends") {
                    ManageFriendsView()
                }
            }
            Spacer()
            Form {
                Button("Sign Out") {
                    viewModel.signOut()
                    dismiss()
                }
                Button("Delete Account") {
                    viewModel.deleteAccount()
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    AccountView(viewModel: AccountViewModel())
}
