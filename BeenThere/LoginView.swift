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
    @State private var currentImageIndex: Int = 0
    
    @AppStorage("username") var username = ""

    let imageNames = ["background1", "background2"]
    
    let timer = Timer.publish(every: 20, on: .main, in: .common).autoconnect()

    private var db = Firestore.firestore()

    var body: some View {
        VStack {
            Text("Been There")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.white)
            
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
                            
                            // Create a user document by default
                            if let user = authResult?.user {
                                self.createUserDocument(user: user, appleIDCredential: appleIDCredential)
                            }
                        }
                    }
                case .failure(let error):
                    print("Authentication failed: \(error)")
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(width: 225, height: 50)
            .padding()
            .padding(.horizontal)
            
        }
        .background(
            ZStack {
                Image(imageNames[currentImageIndex])
                    .scaledToFill()
                    .transition(AnyTransition.opacity.combined(with: .move(edge: .trailing)))
                
                // Vignette Effect
                RadialGradient(gradient: Gradient(colors: [Color.clear, Color.black.opacity(1)]),
                               center: .center,
                               startRadius: 0,
                               endRadius: UIScreen.main.bounds.height*0.6)
            }
            .ignoresSafeArea()
        )
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 2)) {
                currentImageIndex = (currentImageIndex + 1) % imageNames.count
            }
        }
        .onDisappear {
            timer.upstream.connect().cancel()
        }
    }

    // Function to create user document in Firestore
    func createUserDocument(user: User, appleIDCredential: ASAuthorizationAppleIDCredential) {
        let userDocumentRef = db.collection("users").document(user.uid)

        userDocumentRef.getDocument { (document, error) in
            if let document = document, !document.exists {
                let data: [String: Any] = [
                    "firstName": appleIDCredential.fullName?.givenName ?? "",
                    "lastName": appleIDCredential.fullName?.familyName ?? "",
                    "email": appleIDCredential.email ?? ""
                ]
                userDocumentRef.setData(data) { error in
                    if let error = error {
                        print("Error creating user document: \(error)")
                    } else {
                        print("User document successfully created!")
                    }
                }
            } else if let error = error {
                print("Error checking for existing user document: \(error)")
            }
        }
    }
}




#Preview {
    LoginView()
}
