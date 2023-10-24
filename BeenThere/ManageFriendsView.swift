//
//  ManageFriendsView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/22/23.
//

import SwiftUI
import AlertToast

struct ManageFriendsView: View {
    @ObservedObject var viewModel = ManageFriendsViewModel.shared
    @ObservedObject var accountViewModel = AccountViewModel.shared
    
    @State private var newFriendUsername = ""
    
    var body: some View {
        List {
           Section {
               HStack {
                   TextField("Add Friend", text: $newFriendUsername)
                       .autocapitalization(.none)
                       .disableAutocorrection(true)
                       .foregroundColor(.gray)
                   Button("Add") {
                       viewModel.sendFriendRequest(friendUsername: newFriendUsername)
                       newFriendUsername = ""
                       print(accountViewModel.sentFriendRequests)
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
                    ForEach(accountViewModel.sentFriendRequests.indices, id: \.self) { index in
                        HStack {
                            // Safely extract the username from the dictionary.
                            if let username = accountViewModel.sentFriendRequests[index]["username"] as? String {
                                Text(username)
                                    .foregroundColor(.gray)
                                Spacer()
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.red)
                                    .onTapGesture {
                                        // Handle friend request cancellation here.
                                        // If you need to pass the entire friend request dictionary:
    //                                    viewModel.cancelFriendRequest(friend: accountViewModel.sentFriendRequests[index])
                                        viewModel.cancelFriendRequest(friendUsername: username)
                                    }
                            }
                        }
                    }
                }
            }

            if !accountViewModel.receivedFriendRequests.isEmpty {
                Section("Received") {
                    ForEach(accountViewModel.receivedFriendRequests.indices, id: \.self) { index in
                        HStack {
                            if let username = accountViewModel.sentFriendRequests[index]["username"] as? String {
                                Text(username)
                                    .foregroundColor(.gray)
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
//                                    viewModel.cancelFriendRequest(friendUsername: friend)
                                }
                        }
                    }
                }
            }
       }
        .toast(isPresenting: $viewModel.showRequestSent) {
            AlertToast(displayMode: .alert, type: .complete(.green), title: "Friend Request Sent!")
        }
        .toast(isPresenting: $viewModel.showRequestAlreadySent) {
            AlertToast(displayMode: .alert, type: .complete(.orange), title: "Friend Request Already Sent")
        }
        .toast(isPresenting: $viewModel.showRequestError) {
            AlertToast(displayMode: .alert, type: .error(.red), title: "Something Went Wrong")
        }
    }
}

#Preview {
    ManageFriendsView(accountViewModel: AccountViewModel())
}
