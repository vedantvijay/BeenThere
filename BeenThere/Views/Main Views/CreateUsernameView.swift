//
//  CreateUsernameView.swift
//  BeenThere
//
//  Created by Jared Jones on 11/6/23.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct CreateUsernameView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("appState") var appState = "opening"
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var accountViewModel = AccountViewModel()
    @AppStorage("username") var username = ""
    @State private var newUsername = ""
    @State private var isCheckingUsername = false
    @State private var isUsernameTaken = false
    @State private var currentImageIndex: Int = 0
    private let debouncer = Debouncer()
    @State private var lastCheckInitiationTime: Date? = nil
    private let debounceInterval = 0.5 // or whatever value you've determined is appropriate
    @FocusState private var isUsernameFieldFocused: Bool
    @State private var showSplash = true
    
    var isUsernameValid: Bool {
        let regex = "^[a-zA-Z0-9]{4,15}$"
        return newUsername.range(of: regex, options: .regularExpression) != nil && newUsername.count < 16
    }
    
    var isChangeButtonDisabled: Bool {
            // Check if enough time has passed since the last initiated check.
            if let lastCheckTime = lastCheckInitiationTime {
                if -lastCheckTime.timeIntervalSinceNow < debounceInterval {
                    // Not enough time has passed, disable the button.
                    return true
                }
            }
            // Otherwise, use the existing conditions.
            return !isUsernameValid || isCheckingUsername || isUsernameTaken
        }
    
    let imageNames = ["background1", "background2", "background3", "background4", "background5", "background6", "background7", "background8", "background9", "background10"]

    
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if showSplash {
            SplashView()
                .task {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showSplash = false
                        }
                    }
                }
        } else {
            GeometryReader { geometry in
            ZStack {
                Color(.background)
                    .ignoresSafeArea()
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(.accent)
                                .frame(width: 125, height: 125)
                            Image("at")
                                .resizable()
                                .frame(width: 75, height: 75)
                        }
                        .padding()
                        Text("Claim you username")
                            .font(.title2)
                            .bold()
                        TextField("Username", text: $newUsername)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($isUsernameFieldFocused)
                            .textFieldStyle(WhiteBorder())
                            .frame(width: geometry.size.width * 0.9, height: 60)
                        ZStack {
                            Button {
                                if authViewModel.isAuthenticated && authViewModel.isSignedIn {
                                    appState = "authenticated"
                                    setUsernameInFirestore()
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.button)
                                    Text("Next")
                                        .foregroundStyle((isChangeButtonDisabled || isCheckingUsername) ? .white.opacity(0.1) : Color.mutedPrimary)
                                }
                            }
                            .bold()
                            .disabled(isChangeButtonDisabled || isCheckingUsername)
                            .frame(width: geometry.size.width * 0.9, height: 60)
                            if isCheckingUsername {
                                ProgressView()
                            }
                        }
                        
                        
                        if invalidUsernameReason != "" {
                            Text(invalidUsernameReason)
                                .foregroundStyle(.red)
                                .font(.caption)
                                .padding(10)
                                .background(
                                    Capsule()
                                        .foregroundStyle(.red.opacity(0.1))
                                )

                        } else if isUsernameTaken {
                            Text("Username is already taken")
                                .foregroundStyle(.red)
                                .font(.caption)
                                .padding(10)
                                .background(
                                    Capsule()
                                        .foregroundStyle(.red.opacity(0.1))
                                )
                        }
                        Spacer()
                    }
                    .padding()

                }
                
            }
            .onChange(of: newUsername) {
                checkAndSetUsername()
            }
            .onChange(of: username) {
                if username != "" {
                    appState = "authenticated"
                }
            }
            .onAppear {
                if username != "" {
                    appState = "authenticated"
                }
                if !authViewModel.isAuthenticated || !authViewModel.isSignedIn || Auth.auth().currentUser == nil {
                    accountViewModel.signOut()
                    appState = "notAuthenticated"
                }
            }
            .preferredColorScheme(.light)
            .onReceive(timer) { _ in
                withAnimation(.easeInOut(duration: 2)) {
                    currentImageIndex = Int.random(in: 0..<imageNames.count)
                }
            }
            .onDisappear {
                timer.upstream.connect().cancel()
            }
            .onAppear {
                print("LOG: \(username)")
                if accountViewModel.minutesSinceLastLogin ?? 5 > 10 {
                    appState = "notAuthenticated"
                }
                isUsernameFieldFocused = true
            }
        }

        }
            
    func setUsernameInFirestore() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }

        let userRef = Firestore.firestore().collection("users").document(userID)

        userRef.updateData([
            "username": newUsername,
            "lowercaseUsername": newUsername.lowercased()
        ]) { error in
            if let error = error {
                print("Error updating username: \(error)")
            } else {
                print("Username successfully updated")
            }
        }
    }
    
    func isUsernameTaken(username: String, completion: @escaping (Bool) -> Void) {
        let lowercasedUsername = username.lowercased()

        Firestore.firestore().collection("users").whereField("lowercaseUsername", isEqualTo: lowercasedUsername).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error checking for username: \(error)")
                completion(false)
                return
            }

            if let snapshot = snapshot, !snapshot.isEmpty {
                // The username matches the lowercase version (case-insensitive match).
                print("Username taken")
                completion(true)
            } else {
                // No matches were found, the username is available.
                print("Username available")
                completion(false)
            }
        }
    }


    
    func checkAndSetUsername() {
            guard isUsernameValid else { return }
            
            lastCheckInitiationTime = Date() // Set the last check time to now.
            
            debouncer.debounce(interval: debounceInterval) {
                // Now inside the debounce closure, we start the check
                self.isCheckingUsername = true
                isUsernameTaken(username: self.newUsername) { taken in
                    DispatchQueue.main.async {
                        self.isUsernameTaken = taken
                        self.isCheckingUsername = false
                    }
                }
            }
        }
    
    var invalidUsernameReason: String {
        if newUsername.count <= 3 {
            return "Username must be longer than 3 characters."
        }
        if newUsername.count > 15 {
            return "Username must be shorter than 16 characters"
        }
        if newUsername.contains(" ") || newUsername.contains("\n") {
            return "Username must not contain spaces or newlines."
        }
        if newUsername.range(of: "^[a-zA-Z0-9]{4,15}$", options: .regularExpression) == nil {
            return "Invalid username format."
        }
        return ""
    }
}

struct WhiteBorder: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.textFieldBorder, lineWidth:3)
                    .fill(.textField)
            )
    }
}

//#Preview {
//    CreateUsernameView()
//}

