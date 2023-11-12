//
//  FriendMapViewModel.swift
//  BeenThere
//
//  Created by Jared Jones on 10/24/23.
//

import Foundation
import MapboxMaps
import CoreLocation
import FirebaseAuth
import Firebase
import SwiftUI

class FriendMapViewModel: NSObject, ObservableObject {
    @Published var mapView: MapView?
    @Published var annotationManager: PointAnnotationManager?
    var retryCount = 0
    @Published var tappedLocation: CLLocationCoordinate2D?
    @Published var isDarkModeEnabled: Bool = false

    @Published var locations: [Location] = [] {
        didSet {
            addSquaresToMap(locations: locations)
        }
    }
    @Published var showTappedLocation: Bool = false {
        didSet {
            if !showTappedLocation {
                tappedLocation = nil
                annotationManager?.annotations.removeAll()
            }
        }
    }
    var locationManager = CLLocationManager()
    var currentSquares = Set<String>()
    private var db = Firestore.firestore()
    private var locationsListener: ListenerRegistration?
    

    override init() {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.distanceFilter = 5
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.requestWhenInUseAuthorization()
    }
    deinit {
        locationsListener?.remove()
    }
        
    
    func configureMapView(with frame: CGRect, styleURI: StyleURI) {
        let mapInitOptions = MapInitOptions(styleURI: styleURI)
        mapView = MapView(frame: frame, mapInitOptions: mapInitOptions)
//        mapView?.backgroundColor = UIColor.white
        mapView?.isOpaque = false
        mapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView?.location.options.puckType = .puck2D()
        self.annotationManager = mapView?.annotations.makePointAnnotationManager()
//        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
//        mapView?.addGestureRecognizer(longPressGestureRecognizer)
        addGridlinesToMap()
    }
    
    func updateMapStyleURL() {
        if UITraitCollection.current.userInterfaceStyle == .dark {
            self.mapView?.mapboxMap.style.uri = StyleURI(rawValue: "mapbox://styles/jaredjones/clot6czi600kb01qq4arcfy2g")
        } else {
            self.mapView?.mapboxMap.style.uri = StyleURI(rawValue: "mapbox://styles/jaredjones/clot66ah300l501pe2lmbg11p")
        }
    }

    func addSquaresToMap(locations: [Location]) {
        guard let mapView = mapView else { return }

        var features = [Feature]()
        
        locations.forEach { location in
            let coordinates = [
                CLLocationCoordinate2D(latitude: location.lowLatitude, longitude: location.lowLongitude),
                CLLocationCoordinate2D(latitude: location.lowLatitude, longitude: location.highLongitude),
                CLLocationCoordinate2D(latitude: location.highLatitude, longitude: location.highLongitude),
                CLLocationCoordinate2D(latitude: location.highLatitude, longitude: location.lowLongitude),
                CLLocationCoordinate2D(latitude: location.lowLatitude, longitude: location.lowLongitude)
            ]
            
            let polygon = Polygon([coordinates])
            let feature = Feature(geometry: .polygon(polygon))
            features.append(feature)
        }
        
        var source = GeoJSONSource()
        source.data = .featureCollection(FeatureCollection(features: features))
        
        let setupLayers = { [weak self] in
            do {
                try mapView.mapboxMap.style.addSource(source, id: "square-source")
                
                var fillLayer = FillLayer(id: "square-fill-layer")
                fillLayer.source = "square-source"
                fillLayer.fillColor = .constant(StyleColor(self!.isDarkModeEnabled ? UIColor(red: 1/255, green: 50/255, blue: 32/255, alpha: 1) : UIColor(red: 213/255, green: 255/255, blue: 196/255, alpha: 1)))
                fillLayer.fillOpacity = .constant(1)
                
                // Find the ID of the land layer to add your layer above it
                let landLayerId = mapView.mapboxMap.style.allLayerIdentifiers.first(where: { $0.id.contains("land") || $0.id.contains("landcover") })?.id

                if let landLayerId = landLayerId {
                    try mapView.mapboxMap.style.addLayer(fillLayer, layerPosition: .above(landLayerId))
                } else {
                    // If land layer isn't found, add the layer without specifying position
                    try mapView.mapboxMap.style.addLayer(fillLayer)
                }

                // Update currentSquares with new feature IDs
                self?.currentSquares = Set(features.compactMap { feature in
                    if case let .string(id) = feature.identifier {
                        return id
                    }
                    return nil
                })

            } catch {
                print("Failed to add squares to the map: \(error)")
            }
            self?.adjustMapViewToFitSquares()
        }

        
        if mapView.mapboxMap.style.isLoaded {
            setupLayers()
        } else {
            mapView.mapboxMap.onNext(event: .styleLoaded) { _ in
                setupLayers()
            }
        }
    }
    
    func checkAndAddSquaresIfNeeded() {
        if !areSquaresAdded() {
            addSquaresToMap(locations: locations)
        }
    }

    private func areSquaresAdded() -> Bool {
        return locations.count < 1
    }
    
    func boundingBox(for locations: [Location]) -> (southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D)? {
        guard !locations.isEmpty else { return nil }

        var minLat = locations.first!.lowLatitude
        var maxLat = locations.first!.highLatitude
        var minLong = locations.first!.lowLongitude
        var maxLong = locations.first!.highLongitude

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

    func adjustMapViewToFitSquares() {
        guard let mapView = mapView else { return }

        guard let boundingBox = self.boundingBox(for: self.locations) else { return }
        let coordinateBounds = CoordinateBounds(southwest: boundingBox.southWest, northeast: boundingBox.northEast)

        let cameraOptions = mapView.mapboxMap.camera(for: coordinateBounds, padding: UIEdgeInsets(top: 100, left: 50, bottom: 50, right: 50), bearing: .zero, pitch: .zero)

        mapView.camera.fly(to: cameraOptions, duration: 0.5)

        while retryCount < 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.adjustMapViewToFitSquares()
            }
            retryCount += 1
        }
        
    }
    
    func generateGridlines(insetBy inset: Double = 0.25) -> [LineString] {
        var gridlines = [LineString]()

        // Define your map bounds, adjust these values according to your requirement
        let minLat = -90.0
        let maxLat = 90.0
        let minLong = -180.0
        let maxLong = 180.0

        // Generate latitude lines
        for lat in stride(from: minLat, through: maxLat, by: inset) {
            let line = LineString([
                CLLocationCoordinate2D(latitude: lat, longitude: minLong),
                CLLocationCoordinate2D(latitude: lat, longitude: maxLong)
            ])
            gridlines.append(line)
        }

        // Generate longitude lines
        for long in stride(from: minLong, through: maxLong, by: inset) {
            let line = LineString([
                CLLocationCoordinate2D(latitude: minLat, longitude: long),
                CLLocationCoordinate2D(latitude: maxLat, longitude: long)
            ])
            gridlines.append(line)
        }

        return gridlines
    }

    
    func addGridlinesToMap() {
        guard let mapView = mapView else { return }
        
        let gridlines = generateGridlines()
        let features = gridlines.map { Feature(geometry: .lineString($0)) }

        var source = GeoJSONSource()
        source.data = .featureCollection(FeatureCollection(features: features))

        let addLayer = {
            var lineLayer = LineLayer(id: "gridline-layer")
            lineLayer.source = "gridline-source"
            lineLayer.lineColor = .constant(StyleColor(self.isDarkModeEnabled ? .white : .black))
            lineLayer.lineWidth = .constant(1)

            // Define a zoom-dependent expression for line opacity
            let opacityExpression = Exp(.interpolate) {
                Exp(.linear)
                Exp(.zoom)
                0
                0
                6
                0
                22
                1
            }
            lineLayer.lineOpacity = .expression(opacityExpression)

            do {
                // Find the "road-simple" layer to add your layer above it
                if mapView.mapboxMap.style.layerExists(withId: "road-simple") {
                    try mapView.mapboxMap.style.addLayer(lineLayer, layerPosition: .above("road-simple"))
                } else {
                    // If "road-simple" layer isn't found, add the layer without specifying position
                    try mapView.mapboxMap.style.addLayer(lineLayer)
                }
            } catch {
                print("Error adding gridlines to the map: \(error)")
            }
        }

        if mapView.mapboxMap.style.isLoaded {
            do {
                try mapView.mapboxMap.style.addSource(source, id: "gridline-source")
                addLayer()
            } catch {
                print("Error adding gridlines source to the map: \(error)")
            }
        } else {
            mapView.mapboxMap.onNext(event: .styleLoaded) { _ in
                do {
                    try mapView.mapboxMap.style.addSource(source, id: "gridline-source")
                    addLayer()
                } catch {
                    print("Error adding gridlines source to the map: \(error)")
                }
            }
        }
    }

}


//
//class FriendMapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate, MGLMapViewDelegate {
//    var lastAddedSquareLayerIdentifier: String?
////    @AppStorage("darkColor") var darkColorString = ""
////    @AppStorage("lightColor") var lightColorString = ""
//    @Environment(\.colorScheme) var colorScheme
//    private var locationManager = CLLocationManager()
//    @Published var currentLocation: CLLocation?
//    @Published var mapView: MGLMapView!
//    @Published var tappedLocation: CLLocationCoordinate2D?
//    @Published var showTappedLocation: Bool = false
//    @Published var tappedAnnotation: MGLPointAnnotation?
//    private var db = Firestore.firestore()
//    private var locationsListener: ListenerRegistration?
//    @Published var isDarkModeEnabled: Bool = false
//
//    @Published var locations: [Location] = [] {
//        didSet {
//            addSquaresToMap(locations: locations)
//        }
//    }
//    var currentSquares = Set<String>()
//
//
//    var usesMetric: Bool {
//        let locale = Locale.current
//        switch locale.measurementSystem {
//        case .metric:
//            return true
//        case .us, .uk:
//            return false
//        default:
//            return true
//        }
//    }
//
//    
//    override init() {
//        super.init()
//        mapView = MGLMapView(frame: .zero)
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.distanceFilter = 5
//        locationManager.startUpdatingLocation()
//        locationManager.delegate = self
//        locationManager.requestWhenInUseAuthorization()
//        mapView.delegate = self
//    }
//    deinit {
//        locationsListener?.remove()
//    }
//    
//    
//    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
//        addSquaresToMap(locations: locations)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            self.addGridLinesToMap(aboveLayer: self.lastAddedSquareLayerIdentifier)
//        }
//    }
//    
//    
//    func addGridLinesToMap(aboveLayer layerIdentifier: String? = nil) {
//        // Define the grid interval (1/4 degree)
//        let interval: Double = 0.25
//
//        // Define the bounds of the grid (e.g., global)
//        let minLat: Double = -90.0
//        let maxLat: Double = 90.0
//        let minLong: Double = -180.0
//        let maxLong: Double = 180.0
//
//        var lines: [MGLPolyline] = []
//
//        // Create the grid lines
//        for lat in stride(from: minLat, through: maxLat, by: interval) {
//            let line = MGLPolyline(coordinates: [CLLocationCoordinate2D(latitude: lat, longitude: minLong),
//                                                 CLLocationCoordinate2D(latitude: lat, longitude: maxLong)], count: 2)
//            lines.append(line)
//        }
//
//        for long in stride(from: minLong, through: maxLong, by: interval) {
//            let line = MGLPolyline(coordinates: [CLLocationCoordinate2D(latitude: minLat, longitude: long),
//                                                 CLLocationCoordinate2D(latitude: maxLat, longitude: long)], count: 2)
//            lines.append(line)
//        }
//
//        // Create a shape source with the grid lines
//        let shapeCollection = MGLShapeCollection(shapes: lines)
//        let source = MGLShapeSource(identifier: "gridLines", shape: shapeCollection)
//        mapView.style?.addSource(source)
//
//        // Create a line style layer with the source
//        // Create a line style layer with the source
//        let layer = MGLLineStyleLayer(identifier: "gridLinesLayer", source: source)
//        layer.lineColor = NSExpression(forConstantValue: UIColor.systemGray)
//        
//        // Interpolate line width based on zoom level
//        layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
//                                       [0: 0, 5: 0, 6: 0.5, 10: 1, 11: 1])
//        
//        // Interpolate line opacity based on zoom level. This will make the lines fade out as you zoom out.
//        layer.lineOpacity = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
//                                         [0: 0, 5: 0.1, 13: 0.5, 16: 1])
//        
//        
//        // Add the line style layer to the map style
//        if let aboveLayerId = layerIdentifier, let aboveLayer = mapView.style?.layer(withIdentifier: aboveLayerId) {
//            mapView.style?.insertLayer(layer, above: aboveLayer)
//        } else {
//            mapView.style?.addLayer(layer)
//        }
//
//    }
//
//
//    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
//        if annotation.title == "gridLine" {
//            return UIColor.lightGray.withAlphaComponent(0.5)
//        }
//        return mapView.tintColor // default color
//    }
//
//    func updateSquareColors(for colorScheme: ColorScheme) {
//        // This function will be called whenever the color scheme changes.
//        let fillColor: UIColor = isDarkModeEnabled ? UIColor(red: 0/255, green: 128/255, blue: 0/255, alpha: 1) : UIColor(red: 144/255, green: 238/255, blue: 144/255, alpha: 1)
//        updateSquareLayerFillColor(to: fillColor)
//    }
//    
//    private func updateSquareLayerFillColor(to color: UIColor) {
//        guard let style = mapView.style else { return }
//        for squareIdentifier in currentSquares {
//            let layerIdentifier = "square-layer-\(squareIdentifier.replacingOccurrences(of: "square-", with: ""))"
//            if let layer = style.layer(withIdentifier: layerIdentifier) as? MGLFillStyleLayer {
//                layer.fillColor = NSExpression(forConstantValue: color)
//            }
//        }
//    }
//    
//    func addSquaresToMap(locations: [Location]) {
//        var squaresToKeep = Set<String>() // This will hold the squares that are still valid after this update.
//
//        let adjustmentValue: CLLocationDegrees = 0.000001 // Tiny adjustment value
//
//        for square in locations {
//            let lowLat = square.lowLatitude + adjustmentValue
//            let highLat = square.highLatitude - adjustmentValue
//            let lowLong = square.lowLongitude + adjustmentValue
//            let highLong = square.highLongitude - adjustmentValue
//
//            let bottomLeft = CLLocationCoordinate2D(latitude: lowLat, longitude: lowLong)
//            let bottomRight = CLLocationCoordinate2D(latitude: lowLat, longitude: highLong)
//            let topLeft = CLLocationCoordinate2D(latitude: highLat, longitude: lowLong)
//            let topRight = CLLocationCoordinate2D(latitude: highLat, longitude: highLong)
//
//            let shape = MGLPolygon(coordinates: [bottomLeft, bottomRight, topRight, topLeft, bottomLeft], count: 5)
//
//            let sourceIdentifier = "square-\(lowLat)-\(lowLong)"
//            squaresToKeep.insert(sourceIdentifier) // Mark this square as still valid.
//
//            // Check if the source already exists to avoid adding duplicates
//            if mapView.style?.source(withIdentifier: sourceIdentifier) == nil {
//                let source = MGLShapeSource(identifier: sourceIdentifier, shape: shape, options: nil)
//                mapView.style?.addSource(source)
//
//                let layer = MGLFillStyleLayer(identifier: "square-layer-\(lowLat)-\(lowLong)", source: source)
//                layer.fillColor = NSExpression(forConstantValue: isDarkModeEnabled ? UIColor(red: 0/255, green: 128/255, blue: 0/255, alpha: 1) : UIColor(red: 144/255, green: 238/255, blue: 144/255, alpha: 1))
////                layer.fillOpacity = NSExpression(forConstantValue: 0.25)
//
//                // Find the bottom-most layer and insert your layer below it
//                if let bottomLayer = mapView.style?.layers.first {
//                    mapView.style?.insertLayer(layer, below: bottomLayer)
//                } else {
//                    mapView.style?.addLayer(layer)
//                }
//                currentSquares.insert(sourceIdentifier) // Add this square to our set of current squares.
//            }
//        }
//
//        // Remove any squares that are on the map but not in the provided locations
//        for squareIdentifier in currentSquares {
//            if !squaresToKeep.contains(squareIdentifier) {
//                if let sourceToRemove = mapView.style?.source(withIdentifier: squareIdentifier) {
//                    mapView.style?.removeSource(sourceToRemove)
//                }
//                let layerIdentifier = "square-layer-\(squareIdentifier.replacingOccurrences(of: "square-", with: ""))"
//                if let layerToRemove = mapView.style?.layer(withIdentifier: layerIdentifier) {
//                    mapView.style?.removeLayer(layerToRemove)
//                }
//            }
//        }
//        currentSquares = squaresToKeep // Update our currentSquares to reflect the squares that should be displayed.
//    }
//    
//    func updateMapStyleURL() {
//        if UITraitCollection.current.userInterfaceStyle == .dark {
//            self.mapView.styleURL = URL(string: "https://api.maptiler.com/maps/9b28e433-df46-4fd8-9614-f7ec74b8d7ba/style.json?key=s9gJbpLafAf5TyI9DyDr")
//        } else {
//            self.mapView.styleURL = URL(string: "https://api.maptiler.com/maps/01ee4bc1-f791-4809-911f-4016ae0ae929/style.json?key=s9gJbpLafAf5TyI9DyDr")
//        }
//    }
//
//    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
//        if annotation is MGLPointAnnotation {
//            let identifier = "dotAnnotation"
//            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
//
//            if annotationView == nil {
//                annotationView = MGLAnnotationView(reuseIdentifier: identifier)
//                annotationView?.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
//                annotationView?.backgroundColor = UIColor.red
//                annotationView?.layer.cornerRadius = 10
//            }
//
//            return annotationView
//        }
//        
//        // Check if it's one of our grid line annotations
//        if annotation.title == "gridLine" {
//            // Return nil to use the default polyline view, which will respect the line's `strokeColor` property
//            return nil
//        }
//
//        return nil
//    }
//
//    
//    func calculateAreaOfChunk(lowLat: Double, highLat: Double, lowLong: Double, highLong: Double) -> Double {
//        // Earth's circumference in kilometers by default
//        var earthCircumference = 40075.0
//        
//        // If the user's locale is not metric, switch to miles
//        if !usesMetric {
//            earthCircumference = 24901.0
//        }
//        
//        let latDistance = (highLat - lowLat) * earthCircumference / 360.0
//        let longDistanceAtEquator = (highLong - lowLong) * earthCircumference / 360.0
//        
//        // Adjusting the longitude distance based on the latitude (cosine adjustment)
//        let avgLat = (highLat + lowLat) / 2.0
//        let longDistance = longDistanceAtEquator * cos(avgLat * .pi / 180)
//        
//        return latDistance * longDistance
//    }
//
//
//    func totalAreaInChunks() -> Double {
//        return locations.map { calculateAreaOfChunk(lowLat: $0.lowLatitude, highLat: $0.highLatitude, lowLong: $0.lowLongitude, highLong: $0.highLongitude) }.reduce(0, +)
//    }
//    
//    func boundingBox(for locations: [Location]) -> (southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D)? {
//        guard !locations.isEmpty else { return nil }
//        
//        var minLat = locations[0].lowLatitude
//        var maxLat = locations[0].highLatitude
//        var minLong = locations[0].lowLongitude
//        var maxLong = locations[0].highLongitude
//
//        for location in locations {
//            minLat = min(minLat, location.lowLatitude)
//            maxLat = max(maxLat, location.highLatitude)
//            minLong = min(minLong, location.lowLongitude)
//            maxLong = max(maxLong, location.highLongitude)
//        }
//
//        let southWest = CLLocationCoordinate2D(latitude: minLat, longitude: minLong)
//        let northEast = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLong)
//        
//        return (southWest, northEast)
//    }
//    
//    func adjustMapViewToLocations(retryCount: Int = 0) {
//        if let boundingBox = self.boundingBox(for: self.locations) {
//            let padding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
//            let region = MGLCoordinateBounds(sw: boundingBox.southWest, ne: boundingBox.northEast)
//            
//            mapView.setVisibleCoordinateBounds(region, edgePadding: padding, animated: true) {
//                if !self.coordinateBoundsEqual(lhs: self.mapView.visibleCoordinateBounds, rhs: region) && retryCount < 3 {
//                    // Delay of 1 second before retrying
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
//                        self.adjustMapViewToLocations(retryCount: retryCount + 1)
//                    }
//                } else if retryCount >= 3 {
//                    print("Failed to adjust map view after 3 attempts!")
//                }
//            }
//        }
//    }
//    
//    func coordinateBoundsEqual(lhs: MGLCoordinateBounds, rhs: MGLCoordinateBounds) -> Bool {
//        return lhs.sw.latitude == rhs.sw.latitude &&
//               lhs.sw.longitude == rhs.sw.longitude &&
//               lhs.ne.latitude == rhs.ne.latitude &&
//               lhs.ne.longitude == rhs.ne.longitude
//    }
//}
