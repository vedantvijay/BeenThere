//
//  FriendMapViewModel.swift
//  BeenThere
//
//  Created by Jared Jones on 10/24/23.
//

import Foundation
import CoreLocation
import Mapbox
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class FriendMapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate, MGLMapViewDelegate {
    static let shared = FriendMapViewModel()
    
    @Environment(\.colorScheme) var colorScheme
    private var locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var mapView: MGLMapView!
    @Published var tappedLocation: CLLocationCoordinate2D?
    @Published var showTappedLocation: Bool = false
    @Published var tappedAnnotation: MGLPointAnnotation?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var db = Firestore.firestore()
    private var locationsListener: ListenerRegistration?
    @Published var locations: [Location] = []
    var currentSquares = Set<String>()


    var usesMetric: Bool {
        let locale = Locale.current
        switch locale.measurementSystem {
        case .metric:
            return true
        case .us, .uk:
            return false
        default:
            return true
        }
    }

    
    override init() {
        super.init()
        mapView = MGLMapView(frame: .zero)
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.distanceFilter = 500
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        mapView.delegate = self
    }
    deinit {
        locationsListener?.remove()
    }
    
    func updateMapStyleURL() {
        if UITraitCollection.current.userInterfaceStyle == .dark {
            self.mapView.styleURL = URL(string: "https://api.maptiler.com/maps/backdrop-dark/style.json?key=s9gJbpLafAf5TyI9DyDr")
        } else {
            self.mapView.styleURL = URL(string: "https://api.maptiler.com/maps/backdrop/style.json?key=s9gJbpLafAf5TyI9DyDr")
        }
    }

    
    func setUpFirestoreListener(friendUID: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }
        
        locationsListener = db.collection("users").document(friendUID).addSnapshotListener { (documentSnapshot, error) in
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

    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        if annotation is MGLPointAnnotation {
            let identifier = "dotAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MGLAnnotationView(reuseIdentifier: identifier)
                annotationView?.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
                annotationView?.backgroundColor = UIColor.red
                annotationView?.layer.cornerRadius = 10
            }

            return annotationView
        }

        return nil
    }
    
    func calculateAreaOfChunk(lowLat: Double, highLat: Double, lowLong: Double, highLong: Double) -> Double {
        // Earth's circumference in kilometers by default
        var earthCircumference = 40075.0
        
        // If the user's locale is not metric, switch to miles
        if !usesMetric {
            earthCircumference = 24901.0
        }
        
        let latDistance = (highLat - lowLat) * earthCircumference / 360.0
        let longDistanceAtEquator = (highLong - lowLong) * earthCircumference / 360.0
        
        // Adjusting the longitude distance based on the latitude (cosine adjustment)
        let avgLat = (highLat + lowLat) / 2.0
        let longDistance = longDistanceAtEquator * cos(avgLat * .pi / 180)
        
        return latDistance * longDistance
    }


    func totalAreaInChunks() -> Double {
        return locations.map { calculateAreaOfChunk(lowLat: $0.lowLatitude, highLat: $0.highLatitude, lowLong: $0.lowLongitude, highLong: $0.highLongitude) }.reduce(0, +)
    }

}
