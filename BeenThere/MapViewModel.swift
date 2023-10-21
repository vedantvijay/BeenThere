//
//  MapViewModel.swift
//  BeenThere
//
//  Created by Jared Jones on 10/16/23.
//

import Foundation
import CoreLocation
import Mapbox
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate, MGLMapViewDelegate {
    private var locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var mapView = MGLMapView(frame: .zero, styleURL: URL(string: "https://api.maptiler.com/maps/backdrop/style.json?key=s9gJbpLafAf5TyI9DyDr")!)
    @Published var tappedLocation: CLLocationCoordinate2D?
    @Published var showTappedLocation: Bool = false
    @Published var tappedAnnotation: MGLPointAnnotation?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var db = Firestore.firestore()
    private var locationsListener: ListenerRegistration?
    @Published var locations: [Location] = [] {
        didSet {
            addSquaresToMap(locations: locations)
        }
    }


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
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.distanceFilter = 500
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        self.setUpFirestoreListener()
        mapView.delegate = self
    }
    deinit {
        locationsListener?.remove()
    }
    
    func setUpFirestoreListener() {
        locationsListener = db.collection("users").document(Auth.auth().currentUser!.uid).addSnapshotListener { (documentSnapshot, error) in
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
        
        let userDocumentRef = db.collection("users").document(Auth.auth().currentUser!.uid)
        
        userDocumentRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // If document exists, update the locations array
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
                // If document doesn't exist, create a new one with the locations array
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



    func handleLongPress(coordinate: CLLocationCoordinate2D) {
        tappedLocation = coordinate
        print("Tapped Location Set: \(tappedLocation!)")
        showTappedLocation = true
        print("Should show confirmation: \(showTappedLocation)")
        
        // Center the map on the annotation
        mapView.setCenter(coordinate, animated: true)
    }

    
    func addSquaresToMap(locations: [Location]) {
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
            
            // Check if the source already exists to avoid adding duplicates
            if mapView.style?.source(withIdentifier: sourceIdentifier) == nil {
                let source = MGLShapeSource(identifier: sourceIdentifier, shape: shape, options: nil)
                mapView.style?.addSource(source)

                let layer = MGLFillStyleLayer(identifier: "square-layer-\(lowLat)-\(lowLong)", source: source)
                layer.fillColor = NSExpression(forConstantValue: UIColor.green)
                layer.fillOpacity = NSExpression(forConstantValue: 0.25)
                
                mapView.style?.addLayer(layer)
            }
        }
    }

    
    func beginBackgroundUpdateTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            self.endBackgroundUpdateTask()
        }
    }
    
    func endBackgroundUpdateTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        addSquaresToMap(locations: locations)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = locations.last {
            checkBeenThere(location: newLocation)
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
    
    
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: gesture.view)
            if let mapView = gesture.view as? MGLMapView {
                let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

                // Create a new annotation
                let annotation = MGLPointAnnotation()
                annotation.coordinate = coordinate
                tappedAnnotation = annotation
                handleLongPress(coordinate: coordinate)
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

struct Location: Codable {
    var lowLatitude: Double
    var highLatitude: Double
    var lowLongitude: Double
    var highLongitude: Double
}

