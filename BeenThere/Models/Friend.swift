//
//  Friend.swift
//  BeenThere
//
//  Created by Jared Jones on 1/11/24.
//

import Foundation

struct Friend: Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let username: String
    let locations: [Location]
    // Add other properties if needed
    
    init?(from dictionary: [String: Any]) {
        guard let id = dictionary["uid"] as? String,
            let firstName = dictionary["firstName"] as? String,
            let lastName = dictionary["lastName"] as? String,
            let username = dictionary["username"] as? String,
            let locations = dictionary["locations"] as? [Location] else { return nil }
        
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.locations = locations
    }
}
