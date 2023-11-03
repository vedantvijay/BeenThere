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
    
    func acceptFriendRequest(friendUID: String) {
        let db = Firestore.firestore()
        
        // Step 1: Access friend's document directly with UID and update their sentFriendRequests and friends list
        let friendRef = db.collection("users").document(friendUID)
        friendRef.getDocument { (documentSnapshot, err) in
            if let err = err {
                print("Error fetching friend's document:", err.localizedDescription)
                self.showRequestError = true
                return
            }

            guard let document = documentSnapshot,
                  var sentFriendRequests = document.data()?["sentFriendRequests"] as? [[String: Any]],
                  var friendFriends = document.data()?["friends"] as? [[String: Any]] else {
                print("Error getting data for friend.")
                self.showRequestError = true
                return
            }
            
            // Remove the current user's UID from the friend's sentFriendRequests
            sentFriendRequests.removeAll { ($0["uid"] as? String) == self.accountViewModel.uid }
            friendRef.updateData(["sentFriendRequests": sentFriendRequests])
            
            // Add the current user to the friend's friends list
            let newFriendForThem = ["uid": self.accountViewModel.uid, "username": self.accountViewModel.username]
            friendFriends.append(newFriendForThem)
            friendRef.updateData(["friends": friendFriends])
            self.showRequestAccepted = true

            // Step 2: Access the current user's document and update their receivedFriendRequests and friends list
            let selfRef = db.collection("users").document(self.accountViewModel.uid)
            selfRef.getDocument { (selfSnapshot, error) in
                if let error = error {
                    print("Error fetching user's document:", error.localizedDescription)
                    self.showRequestError = true
                    return
                }

                guard var receivedFriendRequests = selfSnapshot?.data()?["receivedFriendRequests"] as? [[String: Any]],
                      var currentFriends = selfSnapshot?.data()?["friends"] as? [[String: Any]] else {
                    print("Error getting data for current user.")
                    self.showRequestError = true
                    return
                }
                
                // Remove the friend's UID from the current user's receivedFriendRequests
                receivedFriendRequests.removeAll { ($0["uid"] as? String) == friendUID }
                selfRef.updateData(["receivedFriendRequests": receivedFriendRequests])
                
                // Add the friend to the current user's friends list
                let newFriendForSelf = ["uid": friendUID] // Assuming friendUsername is still needed here for some reason.
                currentFriends.append(newFriendForSelf)
                selfRef.updateData(["friends": currentFriends])
            }
        }
    }



    func unfriend(friendUID: String) {
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
            
            friends.removeAll { ($0["uid"] as? String) == friendUID }
            selfRef.updateData(["friends": friends])
        }
        
        // Step 2: Remove the current user from the friend's friends array
        let friendRef = db.collection("users").document(friendUID)
        friendRef.getDocument { (documentSnapshot, err) in
            if let err = err {
                print("Error fetching friend's document:", err.localizedDescription)
                self.showRequestError = true
                return
            }
            
            guard let friendData = documentSnapshot?.data(), let friendsOfFriend = friendData["friends"] as? [[String: Any]] else {
                print("Error getting friends array for friend.")
                self.showRequestError = true
                return
            }
            
            var updatedFriendsOfFriend = friendsOfFriend
            updatedFriendsOfFriend.removeAll { ($0["uid"] as? String) == self.accountViewModel.uid }
            
            // Only update if there was a change.
            if updatedFriendsOfFriend.count != friendsOfFriend.count {
                friendRef.updateData(["friends": updatedFriendsOfFriend])
            }
        }
    }


    func sendFriendRequest(friendUsername: String) {
        print("LOG: sending friend request")
        print("LOG: \(friendUsername)")
        
        // Use the lowercased version of the friendUsername for all checks and queries
        let friendUsernameLowercased = friendUsername.lowercased()
        
        let sentUsernames = accountViewModel.sentFriendRequests.compactMap { $0["lowercaseUsername"] as? String }
        let receivedUsernames = accountViewModel.receivedFriendRequests.compactMap { $0["lowercaseUsername"] as? String }
        
        if !accountViewModel.friends.contains(where: { ($0["lowercaseUsername"] as? String) == friendUsernameLowercased })
            && !(accountViewModel.lowercaseUsername == friendUsernameLowercased)
            && !sentUsernames.contains(friendUsernameLowercased)
            && !receivedUsernames.contains(friendUsernameLowercased) {

            print("LOG: starting send process")
            let db = Firestore.firestore()
            
            // Query for the friend using the lowercaseUsername field
            let friendRef = db.collection("users").whereField("lowercaseUsername", isEqualTo: friendUsernameLowercased)
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
                    "uid": self.accountViewModel.uid
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
                        "uid": friendUID
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


    func cancelFriendRequest(friendUID: String) {
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

            sentFriendRequests.removeAll { ($0["uid"] as? String)?.lowercased() == friendUID.lowercased() }
            selfRef.updateData(["sentFriendRequests": sentFriendRequests])
            self.showRequestCancelled = true
        }

        // Step 2: Remove the friend request from the target friend's receivedFriendRequests
        let friendRef = db.collection("users").document(friendUID)
        friendRef.getDocument { documentSnapshot, err in
            if let err = err {
                print("Error fetching friend's document:", err.localizedDescription)
                self.showRequestError = true
                return
            }

            guard var receivedFriendRequests = documentSnapshot?.data()?["receivedFriendRequests"] as? [[String: Any]] else {
                print("Error getting receivedFriendRequests for friend.")
                self.showRequestError = true
                return
            }

            receivedFriendRequests.removeAll { ($0["uid"] as? String) == self.accountViewModel.uid }
            friendRef.updateData(["receivedFriendRequests": receivedFriendRequests])
            self.showRequestCancelled = true
        }
    }

    
    func rejectFriendRequest(friendUID: String) {
        let db = Firestore.firestore()

        // Step 1: Remove the friend request from the current user's receivedFriendRequests
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

            // Remove the friend request by UID
            receivedFriendRequests.removeAll { ($0["uid"] as? String) == friendUID }
            selfRef.updateData(["receivedFriendRequests": receivedFriendRequests])
        }

        // Step 2: Remove the friend request from the target friend's sentFriendRequests
        let friendRef = db.collection("users").document(friendUID)
        friendRef.getDocument { documentSnapshot, err in
            if let err = err {
                print("Error fetching friend's document:", err.localizedDescription)
                self.showRequestError = true
                return
            }

            guard var sentFriendRequests = documentSnapshot?.data()?["sentFriendRequests"] as? [[String: Any]] else {
                print("Error getting sentFriendRequests.")
                self.showRequestError = true
                return
            }

            // Remove from sent requests by current user's UID
            sentFriendRequests.removeAll { ($0["uid"] as? String) == self.accountViewModel.uid }
            friendRef.updateData(["sentFriendRequests": sentFriendRequests])
            self.showRequestRejected = true
        }
    }

}

