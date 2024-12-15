import AuthenticationServices
import Firebase
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import SwiftUI


struct LoginView: View {
    @AppStorage("appState") var appState = "opening"
    @EnvironmentObject var accountViewModel: AccountViewModel
    @State private var isAppleSignInPresented: Bool = false
    @State private var currentImageIndex: Int = 0
    @ObservedObject var viewModel = AuthenticationViewModel()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.background)
                    .opacity(0.9)
                    .ignoresSafeArea()
                VStack(spacing: 25) {
                    Image("icon")
                        .resizable()
                        .frame(width: 100, height: 100)
                    VStack {
                        Text("Welcome to Been There!")
                    }
                    .shadow(color: .black, radius: 3, x: 1, y: 2)
                    .font(.title)
                    .foregroundColor(.white)
                    VStack(spacing: 20) {
                        SignInApple()
                            .frame(width: geometry.size.width - 100, height: 50)
                            .shadow(color: .black, radius: 3, x: 1, y: 2)
                        Button {
                            Task {
                                await viewModel.signInWithGoogle()
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7)
                                    .foregroundStyle(.white)
                                    .frame(width: geometry.size.width - 100, height: 50)
                                    .shadow(color: .black, radius: 3, x: 1, y: 2)
                                HStack {
                                    Image("googleIcon")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                    Text("Sign in with Google")
                                        .foregroundStyle(.black)
                                        .bold()
                                        .font(.headline)
                                }
                            }
                            
                        }
                            
                    }
                }
            }
            .background(
                Image("splashMap")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            )
        }
    }
}

struct SignInApple: View {
    private var db = Firestore.firestore()
    
    var body: some View {
        SignInWithAppleButton { request in
            request.requestedScopes = [.fullName]
        } onCompletion: { result in
            switch result {
            case .success(let authResults):
                if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                    let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                              idToken: String(data: appleIDCredential.identityToken!, encoding: .utf8)!, accessToken: nil)
                    
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
    }
    
    func createUserDocument(user: User, appleIDCredential: ASAuthorizationAppleIDCredential) {
        let userDocumentRef = db.collection("users").document(user.uid)

        userDocumentRef.getDocument { (document, error) in
            if let document = document, !document.exists {
                let data: [String: Any] = [
                    "uid": Auth.auth().currentUser?.uid ?? "",
                    "firstName": appleIDCredential.fullName?.givenName ?? "",
                    "lastName": appleIDCredential.fullName?.familyName ?? ""
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
