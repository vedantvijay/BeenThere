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
    @Environment(\.colorScheme) var colorScheme
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
                if colorScheme == .dark {
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = []
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
                    .padding()
                    .signInWithAppleButtonStyle(.white)
                } else {
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = []
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
                    .padding()
                    .signInWithAppleButtonStyle(.black)
                }
            }
        }
        .navigationTitle("Delete Account")
        .background(Color(uiColor: UIColor.systemGroupedBackground))
        .onReceive(timer) { _ in
            if let minutes = accountViewModel.minutesSinceLastLogin {
                minutesSinceLastLogin = minutes
            }
        }
        .onChange(of: minutesSinceLastLogin) {
            if minutesSinceLastLogin > 3 {
                showDeleteAccount = false
            }
        }
        .onAppear {
            if let minutes = accountViewModel.minutesSinceLastLogin {
                minutesSinceLastLogin = minutes
            }
        }
        .onDisappear {
            timer.upstream.connect().cancel()
        }
        .confirmationDialog("This action is permanent. Are you sure?",
                            isPresented: $showDeleteAccount, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) {
                accountViewModel.deleteAccount()
                dismiss()
            }
            Button("Cancel", role: .cancel, action: { })
        }
    }
}

#Preview {
    ConfirmDeleteAccountView()
}
