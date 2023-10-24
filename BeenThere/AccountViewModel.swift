//
//  AccountViewModel.swift
//  BeenThere
//
//  Created by Jared Jones on 10/22/23.
//

import Foundation
import Firebase
import AuthenticationServices
import SwiftUI

class AccountViewModel: ObservableObject {
    static let shared = AccountViewModel()
    
    @Published var uid = ""
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var email = ""
    @Published var newUsername = ""
    @AppStorage("username") var username = ""
    @Published var friends: [[String: Any]] = []
    @Published var locations: [Location] = []
    @Published var isCheckingUsername: Bool = false
    @Published var isUsernameTaken: Bool = false
    @Published var sentFriendRequests: [[String: Any]] = []
    @Published var receivedFriendRequests: [[String: Any]] = []
    
    private var accountListener: ListenerRegistration?
    var listeners: [ListenerRegistration] = []
    private var db = Firestore.firestore()
    
    var isUsernameValid: Bool {
        let regex = "^[a-z]{5,}$"
        return newUsername.range(of: regex, options: .regularExpression) != nil
    }
    
    var minutesSinceLastLogin: Int? {
        guard let user = Auth.auth().currentUser else {
            return nil
        }

        let now = Date()
        let lastSignInDate = user.metadata.lastSignInDate!
        let timeInterval = now.timeIntervalSince(lastSignInDate)
        let minutes = Int(timeInterval / 60)

        return minutes
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


    
    init() {
        self.setUpFirestoreListener()
    }
    deinit {
        accountListener?.remove()
        for listener in listeners {
            listener.remove()
        }
    }
    
    func sortedFriendsByLocationCount() -> [[String: Any]] {
        return friends.sorted { friendA, friendB in
            let locationsCountA = (friendA["locations"] as? [[String: Any]])?.count ?? 0
            let locationsCountB = (friendB["locations"] as? [[String: Any]])?.count ?? 0
            return locationsCountA > locationsCountB
        }
    }

    
    func fetchFriendsData() {
        print("LOG: fetching friends data")
        print(friends)
        for friend in friends {
                print(friend)
                guard let friendUID = friend["uid"] as? String else { continue }
                
                let friendRef = db.collection("users").document(friendUID)
                
                let listener = friendRef.addSnapshotListener { [weak self] (snapshot, error) in
                    guard let data = snapshot?.data() else {
                        print("Failed to fetch data for friend: \(friendUID)")
                        return
                    }
                    print("Fetched data for friend \(friendUID): \(data)")
                    if let friendIndex = self?.friends.firstIndex(where: { ($0["uid"] as? String) == friendUID }) {
                        self?.friends[friendIndex] = data
                    }
                }

                
                listeners.append(listener)
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
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch let signOutError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }
    
    func deleteAccount() {
        // 1. Get the currently authenticated user
        guard let user = Auth.auth().currentUser else {
            print("No user is signed in.")
            return
        }
        
        // 2. Delete the user's document from Firestore
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).delete { (error) in
            if let error = error {
                print("Error removing document: \(error.localizedDescription)")
                return
            }
            
            // 3. Delete the user from Firebase Authentication
            user.delete { (error) in
                if let error = error {
                    print("Error deleting user: \(error.localizedDescription)")
                    return
                }
                self.username = ""
                print("User account and associated document deleted successfully.")
            }
        }
    }


    
    func setUsernameInFirestore() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }

        let userRef = db.collection("users").document(userID)

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
        db.collection("users").whereField("username", isEqualTo: newUsername).getDocuments { (snapshot, error) in
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

    
    func setUpFirestoreListener() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }
        
        accountListener = db.collection("users").document(userID).addSnapshotListener { [weak self] (documentSnapshot, error) in
            guard let data = documentSnapshot?.data() else {
                print("No data in document")
                return
            }
            
            self?.firstName = data["firstName"] as? String ?? ""
            self?.lastName = data["lastName"] as? String ?? ""
            self?.email = data["email"] as? String ?? ""
            self?.username = data["username"] as? String ?? ""
            self?.friends = data["friends"] as? [[String: Any]] ?? []
            self?.uid = userID
            self?.sentFriendRequests = data["sentFriendRequests"] as? [[String: Any]] ?? []
            self?.receivedFriendRequests = data["receivedFriendRequests"] as? [[String: Any]] ?? []
            self?.fetchFriendsData()

            if let locationData = data["locations"] as? [[String: Any]] {
                self?.locations = locationData.compactMap { locationDict in
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: locationDict, options: [])
                        let location = try JSONDecoder().decode(Location.self, from: jsonData)
                        return location
                    } catch {
                        print("Error decoding location: \(error)")
                        return nil
                    }
                }
            }

        }
    }
}
