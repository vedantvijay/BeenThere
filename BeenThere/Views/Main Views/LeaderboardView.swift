//import Kingfisher
import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var viewModel: AccountViewModel
    @EnvironmentObject var friendMapViewModel: FriendMapViewModel
    @EnvironmentObject var sharedMapViewModel: SharedMapViewModel

    var body: some View {
        NavigationStack {
            VStack {
                Text("Friends Leaderboard")
                    .font(.title)
                    .padding()
                Spacer()
                ScrollViewReader { proxy in
                    List {
                        // MARK: -Friends Only
                        if !viewModel.sortedFriendsByLocationCount().isEmpty {
                            ForEach(viewModel.sortedFriendsByLocationCount().indices, id: \.self) { index in
                                let friend = viewModel.sortedFriendsByLocationCount()[index]
                                NavigationLink(destination: FriendView(username: friend["username"] as? String ?? "",
                                                                       firstName: friend["firstName"] as? String ?? "",
                                                                       friend: friend)) {
                                    HStack {
                                        Text("\(index + 1).")
                                            .bold()
                                            .padding(.trailing, 3)
                                            .font(.title2)
                                            .foregroundStyle(Color.mutedPrimary)

                                        if let friendUsername = friend["username"] as? String {
                                            if let friendFirstName = friend["firstName"] as? String, let friendLastName = friend["lastName"] as? String, !friendFirstName.isEmpty {
                                                Text("\(friendFirstName) \(friendLastName)")
                                                    .fontWeight(friendUsername == viewModel.username ? .black : .regular)
                                                    .padding(.trailing, 4)
                                                    .font(.title2)
                                                    .foregroundStyle(Color.mutedPrimary)
                                            } else {
                                                Text("@\(friendUsername)")
                                                    .italic()
                                                    .foregroundStyle(.secondary)
                                            }
                                        }

                                        Spacer()

                                        if let locations = friend["locations"] as? [[String: Any]] {
                                            Text("\(locations.count)")
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                    .font(.title3)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                }
                            }
                            .listRowBackground(Color.rowBackground)
                        } else {
                            Text("You have no friends added yet.")
                                .foregroundColor(.gray)
                        }
                    }
                    .listStyle(.plain)
                    
                }
            }
//            .onDisappear {
//                viewModel.updateProfileImages()
//            }
            .onAppear {
                if viewModel.users.isEmpty {
                    viewModel.setUpFirestoreListener()
                }
            }
            .background(Color.background)
            .navigationBarTitleDisplayMode(.inline)
        }
        .environmentObject(friendMapViewModel)
        .environmentObject(sharedMapViewModel)
        .environmentObject(viewModel)
    }
}


//#Preview {
//    LeaderboardView()
//}
