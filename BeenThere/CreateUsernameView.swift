//
//  CreateUsernameView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/22/23.
//

import SwiftUI
import Firebase

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
    
    @FocusState private var isUsernameFieldFocused: Bool
    
    var isUsernameValid: Bool {
        let regex = "^[a-z]{4,15}$" // Modified to enforce a maximum of 15 characters
        return newUsername.range(of: regex, options: .regularExpression) != nil && newUsername.count < 16
    }
    
    let imageNames = ["background1", "background2", "background3", "background4", "background5", "background6", "background7", "background8", "background9", "background10"]

    
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
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
                               .blur(radius: 2)
//                               .brightness(-0.1)
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
                TextField("Username", text: $newUsername)
                    .shadow(color: .black, radius: 1, x: 0.5, y: 1)
                    .fontWeight(.black)
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
                                appState = "authenticated"
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
                Spacer()
            }
            .padding()

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
        if newUsername.count <= 3 {
            return "Username must be longer than 3 characters."
        }
        if newUsername.count > 15 {
            return "Username must be shorter than 16 characters"
        }
        if newUsername.range(of: "[A-Z]", options: .regularExpression) != nil {
            return "Username must not contain uppercase characters."
        }
        if newUsername.contains(" ") || newUsername.contains("\n") {
            return "Username must not contain spaces or newlines."
        }
        if newUsername.range(of: "^[a-z]{4,15}$", options: .regularExpression) == nil {
            return "Invalid username format."
        }
        return ""
    }
}


