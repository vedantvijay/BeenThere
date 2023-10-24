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
    static let shared = ManageFriendsViewModel()
    @ObservedObject var accountViewModel = AccountViewModel()
    
    @Published var showRequestSent = false
    @Published var showRequestAlreadySent = false
    @Published var showRequestError = false

    
    func sendFriendRequest(friendUsername: String) {
        print("LOG: sending friend request")
        print("LOG: \(friendUsername)")
        
        let sentUsernames = accountViewModel.sentFriendRequests.compactMap { $0["username"] as? String }.map { $0.lowercased() }
        let receivedUsernames = accountViewModel.receivedFriendRequests.compactMap { $0["username"] as? String }.map { $0.lowercased() }
        
        if !accountViewModel.friends.contains(friendUsername.lowercased())
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
                return
            }

            guard var sentFriendRequests = snapshot?.data()?["sentFriendRequests"] as? [[String: Any]] else {
                print("Error getting sentFriendRequests.")
                return
            }

            sentFriendRequests.removeAll { ($0["username"] as? String)?.lowercased() == friendUsername.lowercased() }
            selfRef.updateData(["sentFriendRequests": sentFriendRequests])
        }

        // Step 2: Remove the friend request from the target friend's receivedFriendRequests
        let friendRef = db.collection("users").whereField("username", isEqualTo: friendUsername.lowercased())
        friendRef.getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error fetching friend's document:", err.localizedDescription)
                return
            }

            guard let document = querySnapshot?.documents.first else {
                print("No document found for friend.")
                return
            }

            guard var receivedFriendRequests = document.data()["receivedFriendRequests"] as? [[String: Any]] else {
                print("Error getting receivedFriendRequests for friend.")
                return
            }

            receivedFriendRequests.removeAll { ($0["uid"] as? String) == self.accountViewModel.uid }
            document.reference.updateData(["receivedFriendRequests": receivedFriendRequests])
        }
    }


}
