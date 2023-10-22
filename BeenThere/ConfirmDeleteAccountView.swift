//
//  ConfirmDeleteAccountView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/22/23.
//

import SwiftUI
import Firebase
import AuthenticationServices

struct ConfirmDeleteAccountView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var accountViewModel = AccountViewModel.shared
    @State private var showDeleteAccount = false
    @State private var minutesSinceLastLogin: Int = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Form {
                Section {
                    Button("Delete Account", role: .destructive) {
                        showDeleteAccount.toggle()
                    }
                    .disabled(minutesSinceLastLogin > 3)
                    if minutesSinceLastLogin > 3 {
                        Text("Please reauthenticate with the button below to delete your account.")
                    }
                }
            }
            if minutesSinceLastLogin > 3 {
                SignInWithAppleButton { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                                      idToken: String(data: appleIDCredential.identityToken!, encoding: .utf8)!,
                                                                      rawNonce: nil)
                            
                            Auth.auth().signIn(with: credential) { (authResult, error) in
                                if let error = error {
                                    print("Firebase Auth Error: \(error.localizedDescription)")
                                    return
                                }
                                print("Successfully signed in with Apple!")
                            }
                        }
                    case .failure(let error):
                        print("Authentication failed: \(error)")
                    }
                }
                .frame(width: 280, height: 45)
            }
        }
        .onReceive(timer) { _ in
            minutesSinceLastLogin = accountViewModel.minutesSinceLastLogin ?? 10
        }
        .onChange(of: minutesSinceLastLogin) {
            if minutesSinceLastLogin > 3 {
                showDeleteAccount = false
            }
        }
        .onAppear {
            minutesSinceLastLogin = accountViewModel.minutesSinceLastLogin!
        }
        .confirmationDialog("This action is permanent. Are you sure?",
                            isPresented: $showDeleteAccount, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) {
                accountViewModel.deleteAccount()
            }
            Button("Cancel", role: .cancel, action: { })
        }
    }
}

#Preview {
    ConfirmDeleteAccountView()
}
