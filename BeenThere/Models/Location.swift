import Foundation

struct Location: Codable, Hashable {
    var lowLatitude: Double
    var highLatitude: Double
    var lowLongitude: Double
    var highLongitude: Double
    var timestamp: Double?
}

extension Location {
    static let preview = Location(lowLatitude: 50, highLatitude: 50.25, lowLongitude: 50, highLongitude: 50.25)
}
