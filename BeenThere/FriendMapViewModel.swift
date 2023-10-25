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
//        adjustMapViewToLocations()
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
    
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        addSquaresToMap(locations: locations)
    }
    
    func addSquaresToMap(locations: [Location]) {
        var squaresToKeep = Set<String>() // This will hold the squares that are still valid after this update.

        for square in locations {
            let lowLat = square.lowLatitude
            let highLat = square.highLatitude
            let lowLong = square.lowLongitude
            let highLong = square.highLongitude

            let bottomLeft = CLLocationCoordinate2D(latitude: lowLat, longitude: lowLong)
            let bottomRight = CLLocationCoordinate2D(latitude: lowLat, longitude: highLong)
            let topLeft = CLLocationCoordinate2D(latitude: highLat, longitude: lowLong)
            let topRight = CLLocationCoordinate2D(latitude: highLat, longitude: highLong)
                
            let shape = MGLPolygon(coordinates: [bottomLeft, bottomRight, topRight, topLeft, bottomLeft], count: 5)
                
            let sourceIdentifier = "square-\(lowLat)-\(lowLong)"
            squaresToKeep.insert(sourceIdentifier) // Mark this square as still valid.

            // Check if the source already exists to avoid adding duplicates
            if mapView.style?.source(withIdentifier: sourceIdentifier) == nil {
                let source = MGLShapeSource(identifier: sourceIdentifier, shape: shape, options: nil)
                mapView.style?.addSource(source)

                let layer = MGLFillStyleLayer(identifier: "square-layer-\(lowLat)-\(lowLong)", source: source)
                layer.fillColor = NSExpression(forConstantValue: UIColor.green)
                layer.fillOpacity = NSExpression(forConstantValue: 0.25)
                
                mapView.style?.addLayer(layer)
                currentSquares.insert(sourceIdentifier) // Add this square to our set of current squares.
            }
        }

        // Remove any squares that are on the map but not in the provided locations
        for squareIdentifier in currentSquares {
            if !squaresToKeep.contains(squareIdentifier) {
                if let sourceToRemove = mapView.style?.source(withIdentifier: squareIdentifier) {
                    mapView.style?.removeSource(sourceToRemove)
                }
                let layerIdentifier = "square-layer-\(squareIdentifier.replacingOccurrences(of: "square-", with: ""))"
                if let layerToRemove = mapView.style?.layer(withIdentifier: layerIdentifier) {
                    mapView.style?.removeLayer(layerToRemove)
                }
            }
        }
        currentSquares = squaresToKeep
    }
    
    func updateMapStyleURL() {
        if UITraitCollection.current.userInterfaceStyle == .dark {
            self.mapView.styleURL = URL(string: "https://api.maptiler.com/maps/d60cc1d4-e18c-4dfa-81d6-55214c71c53a/style.json?key=s9gJbpLafAf5TyI9DyDr")
        } else {
            self.mapView.styleURL = URL(string: "https://api.maptiler.com/maps/9175ed1e-70ec-4433-9bc5-b4609df28fcd/style.json?key=s9gJbpLafAf5TyI9DyDr")
        }
    }

    
//    func setUpFirestoreListener(friendUID: String) {
//        print("Setting up Firestore listener for UID: \(friendUID)")
//        
//        guard let userID = Auth.auth().currentUser?.uid else {
//            print("Error: No authenticated user found")
//            return
//        }
//        
//        locationsListener = db.collection("users").document(friendUID).addSnapshotListener { (documentSnapshot, error) in
//            if let error = error {
//                print("Firestore error: \(error.localizedDescription)")
//                return
//            }
//            
//            guard let data = documentSnapshot?.data() else {
//                print("No data in document")
//                return
//            }
//
//            // Printing the raw data for inspection
//            print("Raw data from Firestore: \(data)")
//            
//            if let locationData = data["locations"] as? [[String: Any]] {
//                self.locations = locationData.compactMap { locationDict in
//                    do {
//                        let jsonData = try JSONSerialization.data(withJSONObject: locationDict, options: [])
//                        let location = try JSONDecoder().decode(Location.self, from: jsonData)
//                        return location
//                    } catch {
//                        print("Error decoding location: \(error)")
//                        return nil
//                    }
//                }
//
//                // Printing the decoded locations for inspection
//                print("Decoded locations: \(self.locations)")
//            }
//        }
//    }


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
    
    func boundingBox(for locations: [Location]) -> (southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D)? {
        guard !locations.isEmpty else { return nil }
        
        var minLat = locations[0].lowLatitude
        var maxLat = locations[0].highLatitude
        var minLong = locations[0].lowLongitude
        var maxLong = locations[0].highLongitude

        for location in locations {
            minLat = min(minLat, location.lowLatitude)
            maxLat = max(maxLat, location.highLatitude)
            minLong = min(minLong, location.lowLongitude)
            maxLong = max(maxLong, location.highLongitude)
        }

        let southWest = CLLocationCoordinate2D(latitude: minLat, longitude: minLong)
        let northEast = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLong)
        
        return (southWest, northEast)
    }

    func adjustMapViewToLocations() {
        if let boundingBox = self.boundingBox(for: self.locations) {
            let padding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            let region = MGLCoordinateBounds(sw: boundingBox.southWest, ne: boundingBox.northEast)
            mapView.setVisibleCoordinateBounds(region, edgePadding: padding, animated: true)
        }
    }
}
