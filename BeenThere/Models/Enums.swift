//
//  Enums.swift
//  BeenThere
//
//  Created by Jared Jones on 11/26/23.
//

import Foundation

enum AppUIState {
    case opening, authenticated, notAuthenticated, createUser
}

enum Tab {
    case feed, map, leaderboards, profile
}

//enum MapType: String, CaseIterable, Identifiable {
//    case mine, global
//
//    var id: String { self.rawValue }
//}

enum MapSelection: Hashable {
    case personal
    case global
    case friend(String) // Using friend's UID as unique identifier
}
