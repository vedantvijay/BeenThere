//
//  CreateUsernameView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/22/23.
//

import SwiftUI

struct CreateUsernameView: View {
    @ObservedObject var accountViewModel: AccountViewModel
    
    var body: some View {
        VStack {
            TextField("Username", text: $accountViewModel.newUsername)
                .onChange(of: accountViewModel.newUsername) {
                    accountViewModel.checkAndSetUsername()
                }
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if accountViewModel.invalidUsernameReason != "" {
                Text(accountViewModel.invalidUsernameReason)
            } else if accountViewModel.isUsernameTaken {
                Text("Username is already taken")
            }
            if accountViewModel.isCheckingUsername {
                ProgressView()
            } else {
                Button("Create Username") {
                    accountViewModel.setUsernameInFirestore()
                }
                .disabled(!accountViewModel.isUsernameValid || accountViewModel.isCheckingUsername || accountViewModel.isUsernameTaken)
                .buttonStyle(.bordered)
                .tint(.green)
            }
        }
    }
}

#Preview {
    CreateUsernameView(accountViewModel: AccountViewModel())
}
