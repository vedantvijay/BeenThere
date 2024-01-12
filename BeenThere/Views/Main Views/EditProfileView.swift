//
//  EditProfileView.swift
//  BeenThere
//
//  Created by Jared Jones on 11/13/23.
//

import Firebase
import SwiftUI
import Kingfisher

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var accountViewModel: AccountViewModel
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var profileImage: Image?
    @StateObject var viewModel = EditProfileViewModel()
    @State private var lastCheckInitiationTime: Date? = nil
    @State private var isCheckingUsername = false  // Start with true to initially disable the button
    @State private var isUsernameTaken = false
    @State private var newUsername = ""
    @AppStorage("username") var currentUsername = ""
    
    private let debouncer = Debouncer()
    
    private let debounceInterval = 0.5
    
    var isFirstNameValid: Bool {
            // Regex for first name: allow letters, hyphens, apostrophes, up to 50 characters
            let regex = "^[a-zA-Z\\-\\']{1,20}$"
            return firstName.range(of: regex, options: .regularExpression) != nil
        }

        var isLastNameValid: Bool {
            // Regex for last name: allow letters, hyphens, apostrophes, up to 50 characters
            let regex = "^[a-zA-Z\\-\\']{1,20}$"
            return lastName.range(of: regex, options: .regularExpression) != nil
        }
    
    var isDisabled: Bool {
        if !isFirstNameValid || !isLastNameValid || newUsername.isEmpty {
            return true // Disable if any essential field is invalid or empty
        }
        
        if isChangeButtonDisabled {
            return true // Disable if any checks are ongoing or failed
        }
        
        // Enable only if all conditions are satisfied
        return profileImage == nil && firstName == accountViewModel.firstName &&
        lastName == accountViewModel.lastName && newUsername == accountViewModel.username
    }

    
    var body: some View {
            List {
                Section {
                    HStack {
                        if profileImage != nil {
                            if let profileImage = profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            }
                        } else {
                            if let imageUrl = accountViewModel.profileImageUrl {
                                KFImage(imageUrl)
                                    .resizable()
                                    .placeholder {
                                        ProgressView()
                                    }
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            }
                        }
                        
                        
                        Button("Change Photo") {
                            showingImagePicker = true
                        }
                        .foregroundStyle(Color.mutedPrimary)

                    }
                }
                .listRowBackground(Color.rowBackground)

                
                Section {
                    HStack {
                        Text("First Name: ")
                            .foregroundStyle(.tertiary)
                        TextField("First Name", text: $firstName)
                            .foregroundStyle(Color.mutedPrimary)

                    }
                    HStack {
                        Text("Last Name: ")
                            .foregroundStyle(.tertiary)
                        TextField("Last Name", text: $lastName)
                            .foregroundStyle(Color.mutedPrimary)
                        
                    }
                    HStack {
                        Text("Username: ")
                            .foregroundStyle(.tertiary)
                            .onAppear {
                                newUsername = currentUsername
                            }
                            .onChange(of: newUsername) {
                                checkAndSetUsername()
                            }
                        TextField("New Username", text: $newUsername)
                            .foregroundStyle(Color.mutedPrimary)

                            .onChange(of: newUsername) {
                                checkAndSetUsername()
                            }
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    
                    if invalidUsernameReason != "" {
                        Text(invalidUsernameReason)
                            .fontWeight(.black)
                            .foregroundStyle(Color.mutedPrimary)

                        
                    } else if isUsernameTaken {
                        Text("Username is already taken")
                            .fontWeight(.black)
                    }
                }
                .listRowBackground(Color.rowBackground)

                .onAppear {
                    firstName = accountViewModel.firstName
                    lastName = accountViewModel.lastName
                }
                
                Section {
                    HStack {
                        Spacer()
                        Button("Save Changes") {
                            viewModel.saveChanges(uid: accountViewModel.uid, firstName: firstName, lastName: lastName, username: newUsername, profileImage: inputImage) {
                                // Call a function from another ViewModel here
                                accountViewModel.fetchProfileImage()
                                accountViewModel.updateProfileImages()
                            }
                            dismiss()
                        }
                        .foregroundStyle(Color.mutedPrimary)

                        .disabled(isDisabled)
                        Spacer()
                    }
                    
                }
                .listRowBackground(Color.rowBackground)

            }
            .background(Color.background)

            .listStyle(.plain)
            //            .navigationTitle("Edit Profile")
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: self.$inputImage)
            }
            .navigationTitle("Edit Profile")

        
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
    
    var isUsernameValid: Bool {
        let regex = "^[a-zA-Z0-9]{4,15}$"
        return newUsername.range(of: regex, options: .regularExpression) != nil && newUsername.count < 16
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
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        profileImage = Image(uiImage: inputImage)
    }
    
    func checkAndSetUsername() {
        guard isUsernameValid else { return }
        
        lastCheckInitiationTime = Date() // Set the last check time to now.
        
        debouncer.debounce(interval: debounceInterval) {
            // Now inside the debounce closure, we start the check
            self.isCheckingUsername = true
            self.isUsernameTaken(username: self.newUsername) { taken in
                DispatchQueue.main.async {
                    self.isUsernameTaken = taken
                    self.isCheckingUsername = false
                }
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
    
    struct ImagePicker: UIViewControllerRepresentable {
        @Binding var image: UIImage?
        func makeUIViewController(context: Context) -> some UIViewController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            return picker
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
            let parent: ImagePicker
            
            init(_ parent: ImagePicker) {
                self.parent = parent
            }
            
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
                if let uiImage = info[.originalImage] as? UIImage {
                    parent.image = uiImage
                }
                
                picker.dismiss(animated: true)
            }
            
            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                picker.dismiss(animated: true)
            }
        }
        
        func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
            // No update code needed for the image picker
        }
    }
    
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

//#Preview {
//    EditProfileView()
//}
