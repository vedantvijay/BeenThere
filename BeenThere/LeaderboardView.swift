//
//  LeaderboardView.swift
//  BeenThere
//
//  Created by Jared Jones on 10/28/23.
//

import SwiftUI

struct LeaderboardView: View {
    @StateObject var viewModel = AccountViewModel()
    @EnvironmentObject var friendMapViewModel: FriendMapViewModel
    @EnvironmentObject var sharedMapViewModel: SharedMapViewModel
    @State private var leaderboardScope = "friends"
    let scopeOptions = ["friends", "global"]
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Scope", selection: $leaderboardScope) {
                    ForEach(scopeOptions, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                Spacer()
                ScrollViewReader { proxy in
                    Form {
                        if leaderboardScope == "friends" {
                            if !viewModel.sortedFriendsByLocationCount().isEmpty {
                                ForEach(viewModel.sortedFriendsByLocationCount().indices, id: \.self) { index in
                                    let friend = viewModel.sortedFriendsByLocationCount()[index]
                                    NavigationLink(destination: FriendView(friend: friend)) {
                                        
                                        HStack {
                                            Text("\(index + 1).")
                                                .bold()
                                                .padding(.trailing, 8) // Add some padding to separate the rank from the name
                                            
                                            if let friendName = friend["username"] as? String {
                                                Text(friendName)
                                                    .fontWeight(friendName == viewModel.username ? .black : .regular)
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
                        } else if leaderboardScope == "global" {
                            Section {
                                NavigationLink("Shared Map") {
                                    SharedView()
                                }
                            }
                            
                            ForEach(viewModel.sortedUsersByLocationCount().indices, id: \.self) { index in
                                let person = viewModel.sortedUsersByLocationCount()[index]
                                if let personName = person["username"] as? String,
    //                               let personUID = person["uid"] as? String,
                                   let personLocations = person["locations"] as? [[String: Any]] {
                                    HStack {
                                        // Display the rank
                                        Text("\(index + 1).")
                                            .bold()
                                            .padding(.trailing, 8) // Add some padding to separate the rank from the name
                                        
                                        if viewModel.friends.contains(where: { friend in friend["username"] as? String == personName }) || personName == viewModel.username {
                                            Text(personName)
                                                .fontWeight(personName == viewModel.username ? .black : .regular)
                                        } else {
                                            Text("UnknownUser")
                                                .blur(radius: 5)
                                        }
                                        Spacer()
                                        Text("\(personLocations.count)")
                                    }
                                }
                            }
                            .onAppear {
                                // Scroll to the user's position
                                if let userIndex = viewModel.sortedUsersByLocationCount().firstIndex(where: { $0["username"] as? String == viewModel.username }) {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        withAnimation {
                                            proxy.scrollTo(userIndex, anchor: .center)
                                        }
                                    }
                                }
                            }
                        }


                    }
                }
                
                
            }
            .navigationTitle("Leaderboards")
            .navigationBarTitleDisplayMode(.inline)
        }
        .environmentObject(friendMapViewModel)
        .environmentObject(sharedMapViewModel)
        .environmentObject(viewModel)
    }
}
//
//#Preview {
//    LeaderboardView()
//}
