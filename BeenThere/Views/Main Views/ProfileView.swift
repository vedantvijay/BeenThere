//
//  ProfileView.swift
//  BeenThere
//
//  Created by Jared Jones on 11/6/23.
//

import SwiftUI
import Kingfisher

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AccountViewModel
    @AppStorage("appState") var appState = "authenticated"
    @State private var navigationPath = NavigationPath()


    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                if let imageUrl = viewModel.profileImageUrl {
                    KFImage(imageUrl)
                        .resizable()
                        .placeholder {
                            ProgressView()
                        }
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                } else {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                }
                VStack(spacing: 10) {
                    Text("@\(viewModel.username)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(viewModel.locations.count == 1 ? "\(viewModel.locations.count) Chunk Explored" : "\(viewModel.locations.count) Chunks Explored")
                        .fontWeight(.regular)
                        .foregroundStyle(.secondary)
                    SettingsView(navigationPath: $navigationPath)
                        .padding()
                    
                    Button {
                        viewModel.signOut()
                        dismiss()
                        appState = "notAuthenticated"
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.forward")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding(.bottom, 30)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(uiColor: UIColor(red: 0.08, green: 0.1, blue: 0.15, alpha: 1)))
            .navigationDestination(for: DestinationID.self) { id in
                            switch id {
                            case editProfileID:
                                EditProfileView()
                            case manageFriendsID:
                                ManageFriendsView()
                            case sharingID:
                                EmptyView()
                            case deleteAccountID:
                                ConfirmDeleteAccountView()
                            default:
                                EmptyView()
                            }
                        }
        }
        
    }
}

struct DestinationID: Hashable {
    let id: String
}

let editProfileID = DestinationID(id: "Edit Profile")
let manageFriendsID = DestinationID(id: "Manage Friends")
let sharingID = DestinationID(id: "Sharing")
let deleteAccountID = DestinationID(id: "Delete Account")

//#Preview {
//    ProfileView()
//}



//                List {
//                    Section {
//                        NavigationLink {
//                            EditProfileView()
//                        } label: {
//                            Text("Edit Profile")
//                        }
//                        NavigationLink {
//                            ManageFriendsView()
//                        } label: {
//                            HStack {
//                                Text("Manage Friends")
//                                Spacer()
//                                if viewModel.receivedFriendRequests.count > 0 {
//                                    Image(systemName: "bell.badge.circle.fill")
//                                        .foregroundStyle(.red)
//                                        .font(.title3)
//                                        .fontWeight(.black)
//                                }
//                            }
//                        }
//                        NavigationLink {
//                            SettingsView()
//                                .environmentObject(viewModel)
//                        } label: {
//                            Text("Settings")
//                        }
//                    }
//                    Section {
//
//                        Button("Sign Out") {
//                            viewModel.signOut()
//                            dismiss()
//                            appState = "notAuthenticated"
//                        }
//                        NavigationLink("Delete Account") {
//                            ConfirmDeleteAccountView()
//                                .environmentObject(viewModel)
//                        }
//                    }
//
//                }
