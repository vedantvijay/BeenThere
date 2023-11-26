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

extension Person {
    static let preview = Person(id: "123abc", profileImage: Image(systemName: "person"), firstName: "John", lastName: "Doe", username: "JohnDoe", locations: [Location.preview], posts: [Post.preview], friends: [], sentFriendRequests: ["person1", "person2"], receivedFriendRequests: ["person3", "person4"])
}
