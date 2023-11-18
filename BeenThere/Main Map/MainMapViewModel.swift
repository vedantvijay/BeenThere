//
//  MapViewModel(MapBox).swift
//  BeenThere
//
//  Created by Jared Jones on 11/6/23.
//

import Foundation
import MapboxMaps
import CoreLocation
import FirebaseAuth
import Firebase
import SwiftUI

class MainMapViewModel: TemplateMapViewModel {
    
    init() {
        super.init(accountViewModel: SettingsViewModel.sharedMain)
        setUpFirestoreListener()
    }
    
    func setUpFirestoreListener() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }
        
        locationsListener = db.collection("users").document(userID).addSnapshotListener { (documentSnapshot, error) in
            guard let data = documentSnapshot?.data() else {
                print("No data in document")
                return
            }
            
            if let locationData = data["locations"] as? [[String: Any]] {
                self.locations = locationData.compactMap { locationDict in
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: locationDict, options: [])
                        let location = try JSONDecoder().decode(Location.self, from: jsonData)
                        return location
                    } catch {
                        print("Error decoding location: \(error)")
                        return nil
                    }
                }
            }

        }
    }

}



struct Location: Codable, Hashable {
    var lowLatitude: Double
    var highLatitude: Double
    var lowLongitude: Double
    var highLongitude: Double
}
