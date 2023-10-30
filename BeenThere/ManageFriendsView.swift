//
//  ManageFriendsView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/22/23.
//

import SwiftUI
import AlertToast

struct ManageFriendsView: View {
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
                            if let username = accountViewModel.sentFriendRequests[index]["username"] as? String {
                                Text(username)
                                    .foregroundColor(.gray)
                                Spacer()
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.red)
                                    .onTapGesture {
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
                            if let username = accountViewModel.receivedFriendRequests[index]["username"] as? String {
                                Text(username)
                                    .foregroundColor(.gray)
                                Spacer()
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.red)
                                    .onTapGesture {
                                        viewModel.rejectFriendRequest(friendUsername: username)
                                    }
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                                    .onTapGesture {
                                        viewModel.acceptFriendRequest(friendUsername: username)
                                    }
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            if !accountViewModel.friends.isEmpty {
                Section("Friends") {
                    ForEach(accountViewModel.friends.indices, id: \.self) { index in
                        HStack {
                            if let username = accountViewModel.friends[index]["username"] as? String {
                                Text(username)
                                Spacer()
                                Text("unfriend")
                                    .foregroundColor(.blue)
                                    .onTapGesture {
                                        viewModel.unfriend(friendUsername: username)
                                    }
                            }
                        }
                    }
                }
            }
       }
        .navigationTitle(accountViewModel.username)

        .toast(isPresenting: $viewModel.showRequestSent) {
            AlertToast(displayMode: .alert, type: .complete(.green), title: "Friend Request Sent!")
        }
        .toast(isPresenting: $viewModel.showRequestAlreadySent) {
            AlertToast(displayMode: .alert, type: .complete(.orange), title: "Friend Request Already Sent")
        }
        .toast(isPresenting: $viewModel.showRequestError) {
            AlertToast(displayMode: .alert, type: .error(.red), title: "Something Went Wrong")
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
