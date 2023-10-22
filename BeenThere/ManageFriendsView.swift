//
//  ManageFriendsView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/22/23.
//

import SwiftUI

struct ManageFriendsView: View {
    @ObservedObject var viewModel = ManageFriendsViewModel.shared
    @ObservedObject var accountViewModel = AccountViewModel.shared
    
    @State private var newFriendUsername = ""
    
    var body: some View {
        Form {
           Section {
               HStack {
                   TextField("Add Friend", text: $newFriendUsername)
                       .autocapitalization(.none)
                       .disableAutocorrection(true)
                       .foregroundColor(.gray)
                   Button("Add") {
//                       sendFriendRequest(friendUsername: newFriendUsername)
                       newFriendUsername = ""
                   }
                   .buttonStyle(.bordered)
                   .tint(.green)
                   .disabled(newFriendUsername.count < 3 || newFriendUsername.contains(" "))
               }
               .onTapGesture {
                   newFriendUsername = ""
               }
           }
            if !accountViewModel.sentFriendRequests.isEmpty {
                Section("Sent") {
                    ForEach(accountViewModel.sentFriendRequests, id: \.self) { friend in
                        HStack {
                            Text(friend)
                                .foregroundColor(.gray)
                            Spacer()
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.red)
                                .onTapGesture {
//                                    cancelFriendRequest(friend: friend)
                                }
                        }
                    }
                }
            }
            if !accountViewModel.receivedFriendRequests.isEmpty {
                Section("Received") {
                    ForEach(accountViewModel.receivedFriendRequests, id: \.self) { friend in
                        HStack {
                            Text(friend)
                                .foregroundColor(.gray)
                                .onAppear {
                                    print("friend \(friend)")
                                }
                            Spacer()
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.red)
                                .onTapGesture {
//                                    rejectFriendRequest(friend: friend)
                                }
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                                .onTapGesture {
//                                    acceptFriendRequest(friend: friend)
                                }
                                .padding(.horizontal)
                        }
                    }
                }
            }
            if !accountViewModel.friends.isEmpty {
                Section("Friends") {
                    ForEach(accountViewModel.friends, id: \.self) { friend in
                        HStack {
                            Text(friend)
                            Spacer()
                            Text("unfriend")
                                .foregroundColor(.blue)
                                .onTapGesture {
//                                    removeFriend(friend: friend)
                                }
                        }
                    }
                }
            }
       }
    }
}

#Preview {
    ManageFriendsView(accountViewModel: AccountViewModel())
}
