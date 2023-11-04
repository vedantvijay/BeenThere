//
//  SharedMapViewModel.swift
//  BeenThere
//
//  Created by Jared Jones on 11/1/23.
//

import Foundation
import CoreLocation
import Mapbox
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class SharedMapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate, MGLMapViewDelegate {
    var lastAddedSquareLayerIdentifier: String?

    private var locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var mapView: MGLMapView!
    @Published var tappedLocation: CLLocationCoordinate2D?
    @Published var showTappedLocation: Bool = false
    @Published var tappedAnnotation: MGLPointAnnotation?
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
        locationManager.distanceFilter = 250
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        currentLocation = locationManager.location
        mapView.delegate = self
    }
    deinit {
        locationsListener?.remove()
        print("LOG: shared map view deinitialized")
    }
    
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        addSquaresToMap(locations: locations)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.addGridLinesToMap(aboveLayer: self.lastAddedSquareLayerIdentifier)
        }
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
                                       [10: 1, 15: 2, 20: 3])
        
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
        if let lastSquare = locations.last {
            lastAddedSquareLayerIdentifier = "square-layer-\(lastSquare.lowLatitude)-\(lastSquare.lowLongitude)"
        }
    }
    
    func updateMapStyleURL() {
        if UITraitCollection.current.userInterfaceStyle == .dark {
            self.mapView.styleURL = URL(string: "https://api.maptiler.com/maps/d60cc1d4-e18c-4dfa-81d6-55214c71c53a/style.json?key=s9gJbpLafAf5TyI9DyDr")
        } else {
            self.mapView.styleURL = URL(string: "https://api.maptiler.com/maps/9175ed1e-70ec-4433-9bc5-b4609df28fcd/style.json?key=s9gJbpLafAf5TyI9DyDr")
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
        
        // Check if it's one of our grid line annotations
        if annotation.title == "gridLine" {
            // Return nil to use the default polyline view, which will respect the line's `strokeColor` property
            return nil
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
    
    // Helper method to center the map on a given location
    func centerMapOnLocation(location: CLLocation) {
        let coordinate = location.coordinate
        let zoomLevel = 1.5 // Adjust the zoom level as needed
        mapView.setCenter(coordinate, zoomLevel: zoomLevel, animated: true)
    }

}
