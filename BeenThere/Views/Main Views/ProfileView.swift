//
//  ProfileView.swift
//  BeenThere
//
//  Created by Jared Jones on 11/6/23.
//

import SwiftUI
import Kingfisher

struct ProfileView: View {
    @EnvironmentObject var viewModel: AccountViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack(alignment: .center) {
                    Spacer()
                    if let imageUrl = viewModel.profileImageUrl {
                        KFImage(imageUrl)
                            .resizable()
                            .placeholder {
                                ProgressView()
                            }
                            .scaledToFill()
                            .frame(width: 125, height: 125)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 125, height: 125)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }
                    Spacer()
                    VStack(spacing: 10) {
                        Text("\(viewModel.firstName) \(viewModel.lastName)")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("@\(viewModel.username)")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text(viewModel.locations.count == 1 ? "\(viewModel.locations.count) chunk" : "\(viewModel.locations.count) chunks")
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
                .padding()
                Form {
                    NavigationLink {
                        EditProfileView()
                    } label: {
                        Text("Edit Profile")
                    }
                    NavigationLink {
                        ManageFriendsView()
                    } label: {
                        HStack {
                            Text("Manage Friends")
                            Spacer()
                            if viewModel.receivedFriendRequests.count > 0 {
                                Image(systemName: "bell.badge.circle.fill")
                                    .foregroundStyle(.red)
                                    .font(.title3)
                                    .fontWeight(.black)
                            }
                        }
                    }
                }
            }
        }
    }
}

//#Preview {
//    ProfileView()
//}
