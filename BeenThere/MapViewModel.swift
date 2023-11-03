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
//    static let shared = MapViewModel()
    
    @Environment(\.colorScheme) var colorScheme
    private var locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var mapView: MGLMapView!
    @Published var tappedLocation: CLLocationCoordinate2D?
    var lastAddedSquareLayerIdentifier: String?

    @Published var showTappedLocation: Bool = false {
        didSet {
            if !showTappedLocation {
                tappedAnnotation = nil
            }
        }
    }

    @Published var tappedAnnotation: MGLPointAnnotation?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var db = Firestore.firestore()
    private var locationsListener: ListenerRegistration?
    @Published var locations: [Location] = [] {
        didSet {
            addSquaresToMap(locations: locations)
        }
    }
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
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.distanceFilter = 100
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
    
    func updateMapStyleURL() {
        if UITraitCollection.current.userInterfaceStyle == .dark {
            self.mapView.styleURL = URL(string: "https://api.maptiler.com/maps/d60cc1d4-e18c-4dfa-81d6-55214c71c53a/style.json?key=s9gJbpLafAf5TyI9DyDr")
        } else {
            self.mapView.styleURL = URL(string: "https://api.maptiler.com/maps/9175ed1e-70ec-4433-9bc5-b4609df28fcd/style.json?key=s9gJbpLafAf5TyI9DyDr")
        }
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
        if let tappedLocation = tappedLocation {
            print("Tapped Location Set: \(tappedLocation)")
        }
        showTappedLocation = true
        print("Should show confirmation: \(showTappedLocation)")
        
        // Center the map on the annotation
        mapView.setCenter(coordinate, animated: true)
    }

    func addSquaresToMap(locations: [Location]) {
        var squaresToKeep = Set<String>() // This will hold the squares that are still valid after this update.

        let adjustmentValue: CLLocationDegrees = 0.000001 // Tiny adjustment value
        
        for square in locations {
            let lowLat = square.lowLatitude + adjustmentValue
            let highLat = square.highLatitude - adjustmentValue
            let lowLong = square.lowLongitude + adjustmentValue
            let highLong = square.highLongitude - adjustmentValue

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
        if let lastSquare = locations.last {
            lastAddedSquareLayerIdentifier = "square-layer-\(lastSquare.lowLatitude)-\(lastSquare.lowLongitude)"
        }
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

    func adjustMapViewToLocations(retryCount: Int = 0) {
        if let boundingBox = self.boundingBox(for: self.locations) {
            let padding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            let region = MGLCoordinateBounds(sw: boundingBox.southWest, ne: boundingBox.northEast)
            
            mapView.setVisibleCoordinateBounds(region, edgePadding: padding, animated: true) {
                if !self.coordinateBoundsEqual(lhs: self.mapView.visibleCoordinateBounds, rhs: region) && retryCount < 3 {
                    // Delay of 1 second before retrying
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        self.adjustMapViewToLocations(retryCount: retryCount + 1)
                    }
                } else if retryCount >= 3 {
                    print("Failed to adjust map view after 3 attempts!")
                }
            }
        }
    }
    
    func coordinateBoundsEqual(lhs: MGLCoordinateBounds, rhs: MGLCoordinateBounds) -> Bool {
        return lhs.sw.latitude == rhs.sw.latitude &&
               lhs.sw.longitude == rhs.sw.longitude &&
               lhs.ne.latitude == rhs.ne.latitude &&
               lhs.ne.longitude == rhs.ne.longitude
    }

    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        addSquaresToMap(locations: locations)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.addGridLinesToMap(aboveLayer: self.lastAddedSquareLayerIdentifier)
        }
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
    
    func addGridLinesToMap(aboveLayer layerIdentifier: String? = nil) {
        // Define the grid interval (1/4 degree)
        let interval: Double = 0.25

        // Define the bounds of the grid (e.g., global)
        let minLat: Double = -90.0
        let maxLat: Double = 90.0
        let minLong: Double = -180.0
        let maxLong: Double = 180.0

        var lines: [MGLPolyline] = []

        // Create the grid lines
        for lat in stride(from: minLat, through: maxLat, by: interval) {
            let line = MGLPolyline(coordinates: [CLLocationCoordinate2D(latitude: lat, longitude: minLong),
                                                 CLLocationCoordinate2D(latitude: lat, longitude: maxLong)], count: 2)
            lines.append(line)
        }

        for long in stride(from: minLong, through: maxLong, by: interval) {
            let line = MGLPolyline(coordinates: [CLLocationCoordinate2D(latitude: minLat, longitude: long),
                                                 CLLocationCoordinate2D(latitude: maxLat, longitude: long)], count: 2)
            lines.append(line)
        }

        // Create a shape source with the grid lines
        let shapeCollection = MGLShapeCollection(shapes: lines)
        let source = MGLShapeSource(identifier: "gridLines", shape: shapeCollection)
        mapView.style?.addSource(source)

        // Create a line style layer with the source
        // Create a line style layer with the source
        let layer = MGLLineStyleLayer(identifier: "gridLinesLayer", source: source)
        layer.lineColor = NSExpression(forConstantValue: UIColor.lightGray)
        
        // Interpolate line width based on zoom level
        layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
                                       [0: 0, 4: 0.25, 6: 0.5, 10: 1, 11: 1])
        
        // Interpolate line opacity based on zoom level. This will make the lines fade out as you zoom out.
        layer.lineOpacity = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
                                         [3: 0.01, 11: 0.25, 13: 0.5, 16: 1])
        
        
        // Add the line style layer to the map style
        if let aboveLayerId = layerIdentifier, let aboveLayer = mapView.style?.layer(withIdentifier: aboveLayerId) {
            mapView.style?.insertLayer(layer, above: aboveLayer)
        } else {
            mapView.style?.addLayer(layer)
        }

    }


    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        if annotation.title == "gridLine" {
            return UIColor.lightGray.withAlphaComponent(0.5)
        }
        return mapView.tintColor // default color
    }
}

struct Location: Codable, Hashable {
    var lowLatitude: Double
    var highLatitude: Double
    var lowLongitude: Double
    var highLongitude: Double
}

