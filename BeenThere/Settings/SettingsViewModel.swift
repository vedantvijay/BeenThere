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

class SettingsViewModel: ObservableObject {
    @ObservedObject var authViewModel = AuthViewModel()
    @AppStorage("appState") var appState = ""
    @Published var usernameChanged = false
    @Published var usernameForUID: [String: String] = [:]
    @Published var isFetchingUsernames = false
    @Published var users: [[String: Any]] = []
    @Published var uid = ""
    @Published var newUsername = ""
    @AppStorage("username") var username = ""
    @AppStorage("lowercaseUsername") var lowercaseUsername = ""
    @Published var locations: [Location] = []
    @Published var isCheckingUsername: Bool = false
    @Published var isUsernameTaken: Bool = false
    @Published var friends: [[String: Any]] = []
    @Published var sentFriendRequests: [String] = []
    @Published var receivedFriendRequests: [String] = []
    
    private var accountListener: ListenerRegistration?
    var listeners: [ListenerRegistration] = []
    private var db = Firestore.firestore()
    
    var isUsernameValid: Bool {
        let regex = "^[a-zA-Z0-9]{4,15}$"
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
        if newUsername.range(of: "^[a-zA-Z0-9]{4,15}$", options: .regularExpression) == nil {
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
    
    
    func fetchUsernamesForUIDs(uids: [String]) {
            isFetchingUsernames = true
            
            let dispatchGroup = DispatchGroup()
            
            for uid in uids {
                dispatchGroup.enter()
                let userRef = db.collection("users").document(uid)
                userRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        let username = document.data()?["username"] as? String ?? "Unknown"
                        DispatchQueue.main.async {
                            self.usernameForUID[uid] = username
                        }
                    } else {
                        print("Document does not exist")
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.isFetchingUsernames = false
            }
        }
        
        // Call this function when the view appears or the friend requests arrays are updated
        func updateUsernames() {
            let uids = (self.sentFriendRequests + self.receivedFriendRequests)
            fetchUsernamesForUIDs(uids: uids)
        }
    
    func sortedUsersByLocationCount() -> [[String: Any]] {
        return users.sorted { userA, userB in
            let locationsCountA = (userA["locations"] as? [[String: Any]])?.count ?? 0
            let locationsCountB = (userB["locations"] as? [[String: Any]])?.count ?? 0
            return locationsCountA > locationsCountB
        }
    }
    
    func listenForGlobalLeaderboardUpdates() {
        let leaderboardRef = db.collection("leaderboards").document("globalLeaderboard")
        
        // This listener will keep updating `users` whenever the globalLeaderboard document changes.
        let listener = leaderboardRef.addSnapshotListener { [weak self] (documentSnapshot, error) in
            if let error = error {
                print("Error fetching global leaderboard: \(error.localizedDescription)")
                return
            }

            guard let document = documentSnapshot, document.exists, let data = document.data(), let users = data["users"] as? [[String: Any]] else {
                print("No global leaderboard found or there was an error.")
                return
            }
            
            self?.users = users.map { user in
                var userData = user
                if let uid = user["uid"] as? String {
                    userData["uid"] = uid
                }
                return userData
            }

        }
        // Add the listener to your listeners array so you can remove it later if needed.
        listeners.append(listener)
    }

    
    func sortedFriendsByLocationCount() -> [[String: Any]] {
        var friendsAndMe = friends
        
        // Convert your [Location] to [[String: Any]]
        let myLocations: [[String: Any]] = locations.map { location in
            do {
                let encodedData = try JSONEncoder().encode(location)
                let dictionary = try JSONSerialization.jsonObject(with: encodedData, options: .allowFragments) as! [String: Any]
                return dictionary
            } catch {
                print("Error encoding location: \(error)")
                return [:]
            }
        }
        
        friendsAndMe.append(["username": self.username, "locations": myLocations])
        return friendsAndMe.sorted { friendA, friendB in
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
                guard var data = snapshot?.data() else {
                    print("Failed to fetch data for friend: \(friendUID)")
                    return
                }
                
                // Manually add the UID to the document data
                data["uid"] = friendUID
                
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
        username = ""
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

    func ensureUserHasUIDAttribute() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }
        // Reference to the user's document in Firestore
        let userRef = db.collection("users").document(userID)

        // Fetch the user document to check for the uid attribute
        userRef.getDocument { [weak self] (documentSnapshot, error) in
            guard let strongSelf = self else { return }

            if let error = error {
                print("Error fetching user document: \(error)")
                return
            }
            
            guard let documentSnapshot else { return }

            // If the document doesn't exist or doesn't have a uid attribute, add one
            if documentSnapshot.data()?["uid"] == nil {
                strongSelf.addUIDAttributeToUserDocument(userRef: userRef, userID: userID)
            }
        }
    }

    func addUIDAttributeToUserDocument(userRef: DocumentReference, userID: String) {
        userRef.updateData(["uid": userID]) { (error) in
            if let error = error {
                print("Error adding uid attribute: \(error)")
                return
            }
            print("uid attribute added successfully!")
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
    
    func determineUIState() {
        Auth.auth().addStateDidChangeListener() { auth, user in
            if self.authViewModel.isAuthenticated && self.authViewModel.isSignedIn && user != nil {
                if self.username != "" {
                    self.appState = "authenticated"
                } else {
                    self.appState = "createUser"
                }
            } else {
                self.appState = "notAuthenticated"
            }
        }
    }
    
//    func showFriendRequestNotification(from username: String) {
//        let content = UNMutableNotificationContent()
//        content.title = "New Friend Request"
//        content.body = "\(username) has sent you a friend request."
//        content.sound = .default
//        
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
//        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
//        
//        UNUserNotificationCenter.current().add(request) { error in
//            if let error = error {
//                print("Error: \(error)")
//            }
//        }
//    }


    
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
            
            self?.username = data["username"] as? String ?? ""
            self?.lowercaseUsername = data["lowercaseUsername"] as? String ?? ""
            self?.friends = data["friends"] as? [[String: Any]] ?? []
            self?.uid = userID
            self?.sentFriendRequests = data["sentFriendRequests"] as? [String] ?? []
            self?.receivedFriendRequests = data["receivedFriendRequests"] as? [String] ?? []
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
            
//            if let newRequests = data["receivedFriendRequests"] as? [[String: Any]], !newRequests.isEmpty {
//                for request in newRequests {
//                    if let username = request["uid"] as? String {
//                        self?.showFriendRequestNotification(from: username)
//                    }
//                }
//            }

        }
        listenForGlobalLeaderboardUpdates()
    }
}
