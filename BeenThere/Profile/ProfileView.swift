//
//  ProfileView.swift
//  BeenThere
//
//  Created by Jared Jones on 11/6/23.
//

import SwiftUI
import Kingfisher

struct ProfileView: View {
    @EnvironmentObject var viewModel: SettingsViewModel
    let numberOfFriends: Int = 120

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                if let imageUrl = viewModel.profileImageUrl {
                    KFImage(imageUrl)
                        .resizable()
                        .placeholder {
                            ProgressView()
                        }
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                        .padding(.top, 20)
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                        .padding(.top, 20)
                }

                Text("\(viewModel.firstName) \(viewModel.lastName)")
                    .font(.title)
                    .fontWeight(.bold)

                Text("@\(viewModel.username)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text("\(viewModel.locations.count) chunks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                NavigationLink {
                    EditProfileView()
                } label: {
                    Text("Edit Profile")
                }
                Spacer()
            }
        }
    }
}



//#Preview {
//    ProfileView()
//}
