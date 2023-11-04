//
//  ManageFriendsView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/22/23.
//

import SwiftUI
import AlertToast

struct ManageFriendsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel = ManageFriendsViewModel()
    @EnvironmentObject var accountViewModel: AccountViewModel
    
    @State private var newFriendUsername = ""
    
    var body: some View {
        List {
           Section {
               HStack {
                   TextField("Add Friend", text: $newFriendUsername)
                       .autocapitalization(.none)
                       .disableAutocorrection(true)
                       .foregroundColor(.gray)
                       .fontWeight(.black)
                       .onChange(of: accountViewModel.receivedFriendRequests.count) {
                           print("LOG: Changed")
                       }
                   Button("Add") {
                       viewModel.sendFriendRequest(friendUsername: newFriendUsername)
                       newFriendUsername = ""
                   }
                   .buttonStyle(.bordered)
                   .fontWeight(.black)
                   .disabled(newFriendUsername.count < 4 || newFriendUsername.count > 15 || newFriendUsername.contains(" "))
               }
               .onTapGesture {
                   newFriendUsername = ""
               }
           }
            if !accountViewModel.sentFriendRequests.isEmpty {
                Section("Sent") {
                    ForEach(accountViewModel.sentFriendRequests.indices, id: \.self) { index in
                        HStack {
                            if let uid = accountViewModel.sentFriendRequests[index]["uid"] as? String {
                                if let username = accountViewModel.usernameForUID[uid] {
                                    Text(username)
                                        .foregroundColor(.gray)
                                        .fontWeight(.black)

                                    Spacer()
                                    Button("Cancel") {
                                        viewModel.cancelFriendRequest(friendUID: uid)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.red)
                                    
                                }
                                
                            }
                        }
                    }
                }
            }

            if !accountViewModel.receivedFriendRequests.isEmpty {
                Section("Received") {
                    if accountViewModel.isFetchingUsernames {
                        Text("Loading...")
                    } else {
                        ForEach(accountViewModel.receivedFriendRequests.indices, id: \.self) { index in
                            HStack {
                                if let uid = accountViewModel.receivedFriendRequests[index]["uid"] as? String {
                                    if let username = accountViewModel.usernameForUID[uid] {
                                        Text(username)
                                            .foregroundColor(.gray)
                                            .fontWeight(.black)

                                        Spacer()
                                        
                                        Button("Accept") {
                                            viewModel.acceptFriendRequest(friendUID: uid)
                                        }
                                        .tint(.green)
                                        .buttonStyle(.bordered)
                                        Button("Reject") {
                                            viewModel.rejectFriendRequest(friendUID: uid)
                                        }
                                        .tint(.red)
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                        }
                    }
                    
                }
            }
            if !accountViewModel.friends.isEmpty {
                Section("Friends") {
                    ForEach(accountViewModel.friends.indices, id: \.self) { index in
                        HStack {
                            if let uid = accountViewModel.friends[index]["uid"] as? String {
                                if let username = accountViewModel.friends[index]["username"] as? String {
                                    Text(username)
                                        .fontWeight(.black)
                                    Spacer()
                                    Button("Unfriend") {
                                        viewModel.unfriend(friendUID: uid)
                                    }
                                    .tint(.red)
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }
            }
       }
        .navigationTitle(accountViewModel.username)
        .onAppear {
            accountViewModel.updateUsernames()
        }
        .onChange(of: accountViewModel.receivedFriendRequests.count) {
            accountViewModel.updateUsernames()
        }
        .onChange(of: accountViewModel.sentFriendRequests.count) {
            accountViewModel.updateUsernames()
        }
        .onChange(of: accountViewModel.friends.count) {
            accountViewModel.updateUsernames()
        }
        .onDisappear {
            dismiss()
        }
        .toast(isPresenting: $viewModel.showRequestSent) {
            AlertToast(displayMode: .alert, type: .complete(.green), title: "Friend Request Sent!")
        }
        .toast(isPresenting: $viewModel.showRequestAlreadySent) {
            AlertToast(displayMode: .alert, type: .complete(.orange), title: "Friend Request Already Sent")
        }
        .toast(isPresenting: $viewModel.showRequestError) {
            AlertToast(displayMode: .alert, type: .error(.red), title: "Please Try Again", subTitle: "Double check the username is correct")
        }
        .toast(isPresenting: $viewModel.showRequestRejected) {
            AlertToast(displayMode: .alert, type: .error(.red), title: "Friend Request Rejected")
        }
        .toast(isPresenting: $viewModel.showRequestCancelled) {
            AlertToast(displayMode: .alert, type: .error(.red), title: "Friend Request Cancelled")
        }
        .toast(isPresenting: $viewModel.showRequestAccepted) {
            AlertToast(displayMode: .alert, type: .complete(.green), title: "Friend Request Accepted!")
        }
    }
}

//#Preview {
//    ManageFriendsView(accountViewModel: AccountViewModel())
//}
