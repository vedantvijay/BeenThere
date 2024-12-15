//
//  ManageFriendsView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/22/23.
//

import SwiftUI
import AlertToast
//import Kingfisher


struct ManageFriendsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel = ManageFriendsViewModel()
    @EnvironmentObject var accountViewModel: AccountViewModel

    @State private var newFriendUsername = ""
    
    // State for unfriend confirmation
    @State private var showUnfriendAlert = false
    @State private var unfriendUID: String? = nil

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Add Friend", text: $newFriendUsername)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(.gray)
                        .fontWeight(.regular)
                        .onChange(of: accountViewModel.receivedFriendRequests.count) {
                            print("LOG: Changed")
                        }
                        .font(.title2)
                    Button("Add") {
                        viewModel.sendFriendRequest(friendUsername: newFriendUsername)
                        newFriendUsername = ""
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .fontWeight(.black)
                    .disabled(newFriendUsername.count < 4 || newFriendUsername.count > 15 || newFriendUsername.contains(" "))
                }
                .onTapGesture {
                    newFriendUsername = ""
                }
            }
            .listRowBackground(Color.rowBackground)

            if !accountViewModel.sentFriendRequests.isEmpty {
                Section("Sent") {
                    ForEach(accountViewModel.sentFriendRequests.indices, id: \.self) { index in
                        HStack {
                            let uid = accountViewModel.sentFriendRequests[index]
                            if let username = accountViewModel.usernameForUID[uid] {
                                Text("@\(username)")
                                    .foregroundColor(.gray)
                                    .font(.title2)
                                Spacer()
                                Button("Cancel") {
                                    viewModel.cancelFriendRequest(friendUID: uid)
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }
                        }
                    }
                    .listRowBackground(Color.rowBackground)
                }
            }
            
            if !accountViewModel.receivedFriendRequests.isEmpty {
                Section("Received") {
                    if accountViewModel.isFetchingUsernames {
                        Text("Loading...")
                    } else {
                        ForEach(accountViewModel.receivedFriendRequests.indices, id: \.self) { index in
                            HStack {
                                let uid = accountViewModel.receivedFriendRequests[index]
                                if let username = accountViewModel.usernameForUID[uid] {
                                    Text("@\(username)")
                                        .foregroundColor(.gray)
                                        .font(.title2)

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
                        .listRowBackground(Color.rowBackground)
                    }
                }
            }
            
            if !accountViewModel.friends.isEmpty {
                Section("Friends") {
                    ForEach(accountViewModel.friends.indices, id: \.self) { index in
                        HStack {
                            if let uid = accountViewModel.friends[index]["uid"] as? String {
                                if let username = accountViewModel.friends[index]["username"] as? String {
                                    if let firstName = accountViewModel.friends[index]["firstName"] as? String {
                                        VStack(alignment: .leading) {
                                            Text(firstName)
                                                .font(.title2)
                                                .foregroundStyle(Color.mutedPrimary)
                                            Text("@\(username)")
                                                .foregroundStyle(.secondary)
                                                .italic()
                                        }
                                    } else {
                                        Text("@\(username)")
                                            .italic()
                                            .foregroundStyle(.secondary)
                                            .font(.title2)
                                    }
                                }

                                Spacer()
                                Button("Unfriend") {
                                    // Set the UID and trigger the confirmation alert
                                    unfriendUID = uid
                                    showUnfriendAlert = true
                                }
                                .tint(.red)
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .listRowBackground(Color.rowBackground)
                }
            }
        }
        .listStyle(.plain)
        .background(Color.background)
        .navigationTitle("Manage Friends")
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
        // Confirmation Alert for Unfriend
        .alert("Unfriend?", isPresented: $showUnfriendAlert, actions: {
            Button("Cancel", role: .cancel) {}
            Button("Unfriend", role: .destructive) {
                if let uid = unfriendUID {
                    viewModel.unfriend(friendUID: uid)
                }
            }
        }, message: {
            Text("Are you sure you want to remove this friend?")
        })
    }
}

//#Preview {
//    ManageFriendsView(accountViewModel: AccountViewModel())
//}
