//
//  ChangeUsernameView.swift
//  BeenThere
//
//  Created by Jared Jones on 11/3/23.
//

import SwiftUI
import FirebaseAuth
import Firebase

struct ChangeUsernameView: View {
    @Environment(\.dismiss) var dismiss
    @State private var newUsername = ""
    @State private var isCheckingUsername = false
    @State private var isUsernameTaken = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: AccountViewModel
    @FocusState private var isUsernameFieldFocused: Bool
    private let debouncer = Debouncer()
    @State private var lastCheckInitiationTime: Date? = nil
    @AppStorage("username") var currentUsername = ""  // This should be set to the user's current username initially
    private let debounceInterval = 0.5 // or whatever value you've determined is appropriate

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
    
    var isUsernameValid: Bool {
        let regex = "^[a-zA-Z]{4,15}$"
        return newUsername.range(of: regex, options: .regularExpression) != nil && newUsername.count < 16
    }
    
    var body: some View {
        Form {
            TextField("New Username", text: $newUsername)
                .fontWeight(.black)
                .onChange(of: newUsername) {
                    checkAndSetUsername()
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isUsernameFieldFocused)
                .onAppear {
                    isUsernameFieldFocused = true
                }
            if invalidUsernameReason != "" {
                Text(invalidUsernameReason)
                    .fontWeight(.black)

            } else if isUsernameTaken {
                Text("Username is already taken")
                    .fontWeight(.black)
            }
            if isCheckingUsername {
//                ProgressView()

            } else {
                if !(!isUsernameValid || isCheckingUsername || isUsernameTaken) {
                    Button("Change Username") {
                        if authViewModel.isAuthenticated && authViewModel.isSignedIn {
                            setUsernameInFirestore()
                        }
                    }
                    .fontWeight(.black)
                    .disabled(isChangeButtonDisabled)
                    .buttonStyle(.bordered)
                    .tint(.green)
                }
                
            }
        }
        .navigationTitle("Change Username")
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
                viewModel.usernameChanged = true
                dismiss()
            }
        }
    }
    
    func isUsernameTaken(username: String, completion: @escaping (Bool) -> Void) {
        let lowercasedUsername = username.lowercased()
        
        // Avoid checking if the new username is the same as the current username with just different casing.
        guard lowercasedUsername != currentUsername.lowercased() else {
            completion(false)
            return
        }

        Firestore.firestore().collection("users").whereField("lowercaseUsername", isEqualTo: lowercasedUsername).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error checking for username: \(error)")
                completion(false)
                return
            }
            
            if let snapshot = snapshot, !snapshot.isEmpty {
                // The username matches the lowercase version (case-insensitive match).
                // Now we need to make sure that the document found is not the current user's document
                if snapshot.documents.first?.documentID != Auth.auth().currentUser?.uid {
                    print("Username taken")
                    completion(true)
                } else {
                    // If the document is the current user's, the username is not taken.
                    print("Username available")
                    completion(false)
                }
            } else {
                // If we reach this point, it means no matches were found.
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
        if newUsername.range(of: "^[a-zA-Z]{4,15}$", options: .regularExpression) == nil {
            return "Invalid username format."
        }
        return ""
    }
}

#Preview {
    ChangeUsernameView()
}

class Debouncer {
    private var timer: Timer?
    
    func debounce(interval: TimeInterval, action: @escaping (() -> Void)) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            action()
        }
    }
}
