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
    @AppStorage("appState") var appState = "opening"
    @EnvironmentObject var accountViewModel: SettingsViewModel
    @State private var isAppleSignInPresented: Bool = false
    @State private var currentImageIndex: Int = 0

    let imageNames = ["background1", "background2", "background3", "background4", "background5", "background6", "background7", "background8", "background9", "background10"]

    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    private var db = Firestore.firestore()

    var body: some View {
        ZStack {
            // Background
            ForEach(imageNames.indices, id: \.self) { index in
                           Image(imageNames[index])
                               .resizable()
                               .scaledToFill()
                               .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                               .clipped()
                               .opacity(currentImageIndex == index ? 1 : 0)
                               .animation(.easeIn(duration: 2), value: currentImageIndex)  // Only animate opacity changes
                               .ignoresSafeArea()
                       }
                
                // Vignette Effect
//            LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(1)]), startPoint: .top, endPoint: .bottom)
                RadialGradient(gradient: Gradient(colors: [Color.clear, Color.black.opacity(1)]),
                               center: .center,
                               startRadius: UIScreen.main.bounds.height*0,
                               endRadius: UIScreen.main.bounds.height*0.55)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Text("Been There")
                    .shadow(color: .black, radius: 3, x: 1, y: 2)
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                SignInWithAppleButton { request in
                    request.requestedScopes = [.fullName]
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
                .shadow(color: .black, radius: 3, x: 1, y: 2)
                .signInWithAppleButtonStyle(.white)
                .frame(width: 225, height: 50)
                .padding()
                .padding(.bottom, 100)
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 2)) {
                currentImageIndex = Int.random(in: 0..<imageNames.count)
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
                    "uid": Auth.auth().currentUser?.uid ?? "",
                    "firstName": appleIDCredential.fullName?.givenName?.description as? String ?? "",
                    "lastName": appleIDCredential.fullName?.familyName?.description as? String ?? ""
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
