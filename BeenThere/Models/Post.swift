import SwiftUI
import Foundation

struct Post: Identifiable {
    var title: String
    var content: String
    var image: Image
    var location: Location
    var authorName: String
    var timestamp = Date()
    var id = UUID()
}

extension Post {
    static let preview = Post(title: "Example Post", content: "This is some text that acts as the main text content for this post. I'll write one more sentence right here.", image: Image(systemName: "person"), location: Location.preview, authorName: "Jane Doe")
}
