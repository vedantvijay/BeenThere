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
    
    override init() {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.distanceFilter = 5
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.requestWhenInUseAuthorization()
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
    
    func saveLocationToFirestore(lowLat: Double, highLat: Double, lowLong: Double, highLong: Double) {
        let locationData: [String: Any] = [
            "lowLatitude": lowLat,
            "highLatitude": highLat,
            "lowLongitude": lowLong,
            "highLongitude": highLong
        ]
        
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }

        let userDocumentRef = db.collection("users").document(userID)
        
        userDocumentRef.getDocument { (document, error) in
            if let document = document, document.exists {
                userDocumentRef.updateData([
                    "locations": FieldValue.arrayUnion([locationData])
                ]) { error in
                    if let error = error {
                        print("Error adding location: \(error)")
                    } else {
                        print("Location successfully updated!")
                    }
                }
            } else {
                userDocumentRef.setData([
                    "locations": [locationData]
                ]) { error in
                    if let error = error {
                        print("Error creating document with location: \(error)")
                    } else {
                        print("Document successfully created with location!")
                    }
                }
            }
        }
    }
    
    func checkBeenThere(location: CLLocation) {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        // Adjustments for 0.25 degree increments
        let increment: Double = 0.25
        
        let lowLatitude = floor(latitude / increment) * increment
        let highLatitude = lowLatitude + increment
        let lowLongitude = floor(longitude / increment) * increment
        let highLongitude = lowLongitude + increment

        let result = locations.filter {
                $0.lowLatitude <= latitude && $0.highLatitude > latitude &&
                $0.lowLongitude <= longitude && $0.highLongitude > longitude
            }

        if result.isEmpty {
            self.saveLocationToFirestore(lowLat: lowLatitude, highLat: highLatitude, lowLong: lowLongitude, highLong: highLongitude)
        }
    }
}

extension MainMapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("LOG: Test")
        if let newLocation = locations.last {
            checkBeenThere(location: newLocation)
        }
    }
}

struct Location: Codable, Hashable {
    var lowLatitude: Double
    var highLatitude: Double
    var lowLongitude: Double
    var highLongitude: Double
}
