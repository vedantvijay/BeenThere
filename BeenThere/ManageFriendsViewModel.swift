//
//  ManageFriendsViewModel.swift
//  BeenThere
//
//  Created by Jared Jones on 10/22/23.
//

import Foundation
import Firebase
import SwiftUI

class ManageFriendsViewModel: ObservableObject {
    @ObservedObject var accountViewModel = AccountViewModel()
    
    @Published var showRequestSent = false
    @Published var showRequestAlreadySent = false
    @Published var showRequestError = false
    
    @Published var showRequestCancelled = false
    @Published var showRequestRejected = false
    
    @Published var showRequestAccepted = false
    
    func acceptFriendRequest(friendUsername: String) {
        let db = Firestore.firestore()
        
        // Step 1: Fetch friend's UID based on username and remove the friend request from the other user's sentFriendRequests and add to their friends list
        let friendRef = db.collection("users").whereField("username", isEqualTo: friendUsername.lowercased())
        friendRef.getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error fetching friend's document:", err.localizedDescription)
                self.showRequestError = true
                return
            }

            guard let document = querySnapshot?.documents.first,
                  var sentFriendRequests = document.data()["sentFriendRequests"] as? [[String: Any]] else {
                print("Error getting sentFriendRequests for friend.")
                self.showRequestError = true
                return
            }
            
            let friendUID = document.documentID
            var friendFriends = document.data()["friends"] as? [[String: Any]] ?? [] // Default to empty array if nil

            // Remove from sent requests
            sentFriendRequests.removeAll { ($0["uid"] as? String) == self.accountViewModel.uid }
            document.reference.updateData(["sentFriendRequests": sentFriendRequests])

            // Add to friend's friends list
            let newFriendForThem = ["uid": self.accountViewModel.uid, "username": self.accountViewModel.username.lowercased()]
            friendFriends.append(newFriendForThem)
            document.reference.updateData(["friends": friendFriends])
            self.showRequestAccepted = true

            // Step 2: Now, use the fetched UID to remove the friend request from the current user's receivedFriendRequests and add to their friends
            let selfRef = db.collection("users").document(self.accountViewModel.uid)
            selfRef.getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching user's document:", error.localizedDescription)
                    self.showRequestError = true
                    return
                }

                guard var receivedFriendRequests = snapshot?.data()?["receivedFriendRequests"] as? [[String: Any]] else {
                    print("Error getting receivedFriendRequests.")
                    self.showRequestError = true
                    return
                }

                var currentFriends = snapshot?.data()?["friends"] as? [[String: Any]] ?? [] // Default to empty array if nil

                // Remove from received requests
                receivedFriendRequests.removeAll { ($0["username"] as? String)?.lowercased() == friendUsername.lowercased() }
                selfRef.updateData(["receivedFriendRequests": receivedFriendRequests])

                // Add to current user's friends
                let newFriend = ["uid": friendUID, "username": friendUsername.lowercased()]
                currentFriends.append(newFriend)
                selfRef.updateData(["friends": currentFriends])
            }
        }
    }


    func unfriend(friendUsername: String) {
        let db = Firestore.firestore()
        
        // Step 1: Remove the friend from the current user's friends array
        let selfRef = db.collection("users").document(self.accountViewModel.uid)
        selfRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user's document:", error.localizedDescription)
                self.showRequestError = true
                return
            }
            
            guard var friends = snapshot?.data()?["friends"] as? [[String: Any]] else {
                print("Error getting friends array.")
                self.showRequestError = true
                return
            }
            
            friends.removeAll { ($0["username"] as? String)?.lowercased() == friendUsername.lowercased() }
            selfRef.updateData(["friends": friends])
        }
        
        // Step 2: Remove the current user from the friend's friends array
        let friendRef = db.collection("users").whereField("username", isEqualTo: friendUsername.lowercased())
        friendRef.getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error fetching friend's document:", err.localizedDescription)
                self.showRequestError = true
                return
            }
            
            guard let document = querySnapshot?.documents.first else {
                print("No document found for friend.")
                self.showRequestError = true
                return
            }
            
            guard var friendsOfFriend = document.data()["friends"] as? [[String: Any]] else {
                print("Error getting friends array for friend.")
                self.showRequestError = true
                return
            }
            
            friendsOfFriend.removeAll { ($0["uid"] as? String) == self.accountViewModel.uid }
            document.reference.updateData(["friends": friendsOfFriend])
        }
    }



    func sendFriendRequest(friendUsername: String) {
        print("LOG: sending friend request")
        print("LOG: \(friendUsername)")
        
        let sentUsernames = accountViewModel.sentFriendRequests.compactMap { $0["username"] as? String }.map { $0.lowercased() }
        let receivedUsernames = accountViewModel.receivedFriendRequests.compactMap { $0["username"] as? String }.map { $0.lowercased() }
        
        if !accountViewModel.friends.contains(where: { ($0["username"] as? String)?.lowercased() == friendUsername.lowercased() })
            && !(accountViewModel.username == friendUsername.lowercased())
            && !sentUsernames.contains(friendUsername.lowercased())
            && !receivedUsernames.contains(friendUsername.lowercased()) {

            print("LOG: starting send process")
            let db = Firestore.firestore()
            
            let friendRef = db.collection("users").whereField("username", isEqualTo: friendUsername.lowercased())
            friendRef.getDocuments { (querySnapshot, err) in
                
                if let err = err {
                    print("Error fetching friend's document:", err.localizedDescription)
                    self.showRequestError = true
                    return
                }
                
                guard let document = querySnapshot?.documents.first else {
                    self.showRequestError = true
                    return
                }
                
                let friendUID = document.documentID
                var receivedFriendRequests = document.data()["receivedFriendRequests"] as? [[String: Any]] ?? []

                let newFriendRequest = [
                    "uid": self.accountViewModel.uid,
                    "username": self.accountViewModel.username
                ]
                
                if !receivedFriendRequests.contains(where: { ($0["uid"] as? String) == self.accountViewModel.uid }) {
                    receivedFriendRequests.append(newFriendRequest)
                    document.reference.updateData([
                        "receivedFriendRequests": receivedFriendRequests
                    ])
                    self.showRequestSent = true
                } else {
                    print("LOG: Friend request already sent to this user.")
                    self.showRequestAlreadySent = true
                    return
                }
                
                let selfRef = db.collection("users").document(self.accountViewModel.uid)
                selfRef.getDocument { snapshot, error in
                    if let error = error {
                        print("Error fetching user's document:", error.localizedDescription)
                        self.showRequestError = true
                        return
                    }
                    
                    guard let data = snapshot?.data() else {
                        self.showRequestError = true
                        return
                    }
                    
                    var sentFriendRequests = data["sentFriendRequests"] as? [[String: Any]] ?? []
                    
                    let newSentRequest = [
                        "uid": friendUID,
                        "username": friendUsername.lowercased()
                    ]
                    
                    if !sentFriendRequests.contains(where: { ($0["uid"] as? String) == friendUID }) {
                        sentFriendRequests.append(newSentRequest)
                        selfRef.updateData([
                            "sentFriendRequests": sentFriendRequests
                        ])
                        self.showRequestSent = true
                    } else {
                        print("LOG: Already sent a friend request to this user.")
                        self.showRequestAlreadySent = true
                    }
                }
            }

        } else {
            self.showRequestError = true
        }
    }

    func cancelFriendRequest(friendUsername: String) {
        let db = Firestore.firestore()

        // Step 1: Remove the friend request from the current user's sentFriendRequests
        let selfRef = db.collection("users").document(self.accountViewModel.uid)
        selfRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user's document:", error.localizedDescription)
                self.showRequestError = true
                return
            }

            guard var sentFriendRequests = snapshot?.data()?["sentFriendRequests"] as? [[String: Any]] else {
                print("Error getting sentFriendRequests.")
                self.showRequestError = true
                return
            }

            sentFriendRequests.removeAll { ($0["username"] as? String)?.lowercased() == friendUsername.lowercased() }
            selfRef.updateData(["sentFriendRequests": sentFriendRequests])
            self.showRequestCancelled = true
        }

        // Step 2: Remove the friend request from the target friend's receivedFriendRequests
        let friendRef = db.collection("users").whereField("username", isEqualTo: friendUsername.lowercased())
        friendRef.getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error fetching friend's document:", err.localizedDescription)
                self.showRequestError = true
                return
            }

            guard let document = querySnapshot?.documents.first else {
                print("No document found for friend.")
                self.showRequestError = true
                return
            }

            guard var receivedFriendRequests = document.data()["receivedFriendRequests"] as? [[String: Any]] else {
                print("Error getting receivedFriendRequests for friend.")
                self.showRequestError = true
                return
            }

            receivedFriendRequests.removeAll { ($0["uid"] as? String) == self.accountViewModel.uid }
            document.reference.updateData(["receivedFriendRequests": receivedFriendRequests])
            self.showRequestCancelled = true
        }
    }
    
    func rejectFriendRequest(friendUsername: String) {
        let db = Firestore.firestore()

        // Step 1: Remove the friend request from the current user's sentFriendRequests
        let selfRef = db.collection("users").document(self.accountViewModel.uid)
        selfRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user's document:", error.localizedDescription)
                self.showRequestError = true
                return
            }

            guard var receivedFriendRequests = snapshot?.data()?["receivedFriendRequests"] as? [[String: Any]] else {
                print("Error getting receivedFriendRequests.")
                self.showRequestError = true
                return
            }

            receivedFriendRequests.removeAll { ($0["username"] as? String)?.lowercased() == friendUsername.lowercased() }
            selfRef.updateData(["receivedFriendRequests": receivedFriendRequests])
        }

        // Step 2: Remove the friend request from the target friend's receivedFriendRequests
        let friendRef = db.collection("users").whereField("username", isEqualTo: friendUsername.lowercased())
        friendRef.getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error fetching friend's document:", err.localizedDescription)
                self.showRequestError = true
                return
            }

            guard let document = querySnapshot?.documents.first else {
                print("No document found for friend.")
                self.showRequestError = true
                return
            }

            guard var sentFriendRequests = document.data()["sentFriendRequests"] as? [[String: Any]] else {
                print("Error getting sentFriendRequests for friend.")
                self.showRequestError = true
                return
            }

            sentFriendRequests.removeAll { ($0["uid"] as? String) == self.accountViewModel.uid }
            document.reference.updateData(["sentFriendRequests": sentFriendRequests])
            self.showRequestRejected = true
        }
    }
}
