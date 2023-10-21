//
//  LoginView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/21/23.
//

import SwiftUI
import AuthenticationServices
import Firebase
import FirebaseAuth

struct LoginView: View {
    @State private var isAppleSignInPresented: Bool = false

    var body: some View {
        VStack {
            Button(action: {
                isAppleSignInPresented = true
            }) {
                HStack {
                    Image(systemName: "applelogo")
                    Text("Sign in with Apple")
                }
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .fullScreenCover(isPresented: $isAppleSignInPresented, content: {
                AppleSignInViewControllerWrapper()
            })
        }
        .padding()
    }
}

struct AppleSignInViewControllerWrapper: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> AppleSignInViewController {
        return AppleSignInViewController()
    }
    
    func updateUIViewController(_ uiViewController: AppleSignInViewController, context: Context) {}
}

class AppleSignInViewController: UIViewController, ASAuthorizationControllerDelegate {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: String(data: appleIDCredential.identityToken!, encoding: .utf8)!,
                                                      rawNonce: nil)

            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    print("Firebase Auth Error: \(error.localizedDescription)")
                    return
                }
                print("Successfully signed in with Apple!")
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Authorization failed: \(error.localizedDescription)")
        self.dismiss(animated: true, completion: nil)
    }
}

extension AppleSignInViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}



#Preview {
    LoginView()
}
