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
