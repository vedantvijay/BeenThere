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
    @State private var newUsername = ""
    @State private var isCheckingUsername = false
    @State private var isUsernameTaken = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @FocusState private var isUsernameFieldFocused: Bool
    
    var isUsernameValid: Bool {
        let regex = "^[a-zA-Z]{4,15}$"
        return newUsername.range(of: regex, options: .regularExpression) != nil && newUsername.count < 16
    }
    
    var body: some View {
        Form {
            TextField("Username", text: $newUsername)
                .shadow(color: .black, radius: 1, x: 0.5, y: 1)
                .fontWeight(.black)
                .onChange(of: newUsername) {
                    checkAndSetUsername()
                }
                .textFieldStyle(.roundedBorder)
                .padding()
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isUsernameFieldFocused)
            
            if invalidUsernameReason != "" {
                Text(invalidUsernameReason)
                    .foregroundStyle(.white)
                    .shadow(color: .black, radius: 1, x: 0.5, y: 1)
                    .fontWeight(.black)

            } else if isUsernameTaken {
                Text("Username is already taken")
                    .foregroundStyle(.white)
                    .shadow(color: .black, radius: 1, x: 0.5, y: 1)
                    .fontWeight(.black)
            }
            if isCheckingUsername {
                ProgressView()
                    .shadow(radius: 1, x: 0.5, y: 1)

            } else {
                if !(!isUsernameValid || isCheckingUsername || isUsernameTaken) {
                    Button("Create Username") {
                        if authViewModel.isAuthenticated && authViewModel.isSignedIn {
                            setUsernameInFirestore()
                        }
                    }
                    .shadow(color: .black, radius: 1, x: 0.5, y: 1)
                    .fontWeight(.black)
                    .disabled(!isUsernameValid || isCheckingUsername || isUsernameTaken)
                    .buttonStyle(.bordered)
                    .tint(.green)
                }
                
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
        
        Firestore.firestore().collection("users").whereField("username", isEqualTo: username).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error checking for username: \(error)")
                completion(false)
                return
            }
            
            if let snapshot = snapshot, !snapshot.isEmpty {
                // The username matches as it is stored (case-sensitive match).
                print("Username taken")
                completion(true)
            } else {
                // Proceed to check the lowercase version if the case-sensitive check did not find a match.
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
                        // If we reach this point, it means no matches were found in both checks.
                        print("Username available")
                        completion(false)
                    }
                }
            }
        }
    }

    
    func checkAndSetUsername() {
        if isUsernameValid {
            isCheckingUsername = true
        }
        isUsernameTaken(username: newUsername) { taken in
            DispatchQueue.main.async {
                self.isUsernameTaken = taken
                self.isCheckingUsername = false
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
