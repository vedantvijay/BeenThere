//
//  CreateUsernameView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/22/23.
//

import SwiftUI
import Firebase

struct CreateUsernameView: View {
    @AppStorage("username") var username = ""
    @Environment(\.dismiss) var dismiss
    
    @State private var newUsername = ""
    @State private var isCheckingUsername = false
    @State private var isUsernameTaken = false
    @State private var currentImageIndex: Int = 0
    
    @FocusState private var isUsernameFieldFocused: Bool
    
    var isUsernameValid: Bool {
        let regex = "^[a-z]{5,}$"
        return newUsername.range(of: regex, options: .regularExpression) != nil
    }
    
    let imageNames = ["background1", "background2"]
    
    let timer = Timer.publish(every: 20, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            TextField("Username", text: $newUsername)
                .onChange(of: newUsername) {
                    checkAndSetUsername()
                }
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isUsernameFieldFocused)
            
            if invalidUsernameReason != "" {
                Text(invalidUsernameReason)
                    .foregroundStyle(.white)
            } else if isUsernameTaken {
                Text("Username is already taken")
                    .foregroundStyle(.white)
            }
            if isCheckingUsername {
                ProgressView()
            } else {
                Button("Create Username") {
                    setUsernameInFirestore()
                }
                .disabled(!isUsernameValid || isCheckingUsername || isUsernameTaken)
                .buttonStyle(.bordered)
                .tint(.green)
            }
            Spacer()
        }
        .padding()
        .preferredColorScheme(.dark)
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
        .task {
            // Set the focus to the text field when the view appears
            isUsernameFieldFocused = true
        }
    }
    
    func setUsernameInFirestore() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }

        let userRef = Firestore.firestore().collection("users").document(userID)

        userRef.updateData([
            "username": newUsername
        ]) { error in
            if let error = error {
                print("Error updating username: \(error)")
            } else {
                self.username = self.newUsername
                print("Username successfully updated")
            }
        }
    }
    
    func isUsernameTaken(username: String, completion: @escaping (Bool) -> Void) {
        Firestore.firestore().collection("users").whereField("username", isEqualTo: newUsername).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error checking for username: \(error)")
                completion(false)
                return
            }
            
            if let snapshot = snapshot, !snapshot.isEmpty {
                print("Username taken")
                completion(true)
            } else {
                print("Username available")
                completion(false)
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
        if newUsername.count <= 4 {
            return "Username must be longer than 4 characters."
        }
        if newUsername.range(of: "[A-Z]", options: .regularExpression) != nil {
            return "Username must not contain uppercase characters."
        }
        if newUsername.contains(" ") || newUsername.contains("\n") {
            return "Username must not contain spaces or newlines."
        }
        if newUsername.range(of: "^[a-z]{5,}$", options: .regularExpression) == nil {
            return "Invalid username format."
        }
        return ""
    }
}
