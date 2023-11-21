import SwiftUI
import Foundation

struct Person: Identifiable {
    var id: String
    var profileImage: Image
    var firstName: String
    var lastName: String
    var username: String
    var locations: [Location]
    var posts: [Post]
    var friends: [Person]
    var sentFriendRequests: [String]
    var receivedFriendRequests: [String]
}
