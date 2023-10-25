//
//  AccountView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/22/23.
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices

struct AccountView: View {
    @ObservedObject var viewModel: AccountViewModel
    
    @State private var showDeleteAccount = false

    @Environment(\.dismiss) var dismiss
    
    @State private var userPhoto: Image = Image("background1")
    @State private var isUsernameTaken: Bool = false
    
    @State private var showFriendView = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Chunks: \(viewModel.locations.count)")
                }
                Section {
                    NavigationLink("Manage Friends") {
                        ManageFriendsView(accountViewModel: viewModel)
                    }
                }
                Section(header: Text("Friends")) {
                    let sortedFriends = viewModel.sortedFriendsByLocationCount()
                    if !sortedFriends.isEmpty {
                        ForEach(sortedFriends.indices, id: \.self) { index in
                            let friend = sortedFriends[index]
                            NavigationLink(destination: FriendView(friend: friend)) {
                                    HStack {
                                        if let friendName = friend["username"] as? String {
                                            Text(friendName)
                                        }
                                        
                                        Spacer()
                                        
                                        if let locations = friend["locations"] as? [[String: Any]] {
                                            Text("\(locations.count)")
                                        }
                                    }
                                }
                            

                        }
                    } else {
                        Text("You have no friends added yet.")
                            .foregroundColor(.gray)
                    }
                }

            }
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    AccountView(viewModel: AccountViewModel())
}
