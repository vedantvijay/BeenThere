//
//  TemplateMapViewModel.swift
//  BeenThere
//
//  Created by Jared Jones on 11/12/23.
//

import Foundation
import MapboxMaps
import CoreLocation
import FirebaseAuth
import Firebase
import SwiftUI

class TemplateMapViewModel: NSObject, ObservableObject {
    @Published var mapView: MapView?
    @Published var annotationManager: PointAnnotationManager?
    @Published var tappedLocation: CLLocationCoordinate2D?
    @Published var isDarkModeEnabled: Bool = false
    @Published var locations: [Location] = [] {
        didSet {
            checkAndAddSquaresIfNeeded()
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
    var retryCount = 0
    var lastCameraCenter: CLLocationCoordinate2D?
    var lastCameraZoom: CGFloat?
    var lastCameraBearing: CLLocationDirection?
    var lastCameraPitch: CGFloat?
    var locationManager = CLLocationManager()
    var currentSquares = Set<String>()
    var db = Firestore.firestore()
    var locationsListener: ListenerRegistration?
    

    override init() {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.distanceFilter = 5
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
    }
    deinit {
        locationsListener?.remove()
    }
        
    func configureMapView(with frame: CGRect, styleURI: StyleURI) {
        let mapInitOptions = MapInitOptions(styleURI: styleURI)
        mapView?.mapboxMap.onEvery(event: .cameraChanged) { [weak self] _ in
            guard let cameraState = self?.mapView?.cameraState else { return }
            self?.lastCameraCenter = cameraState.center
            self?.lastCameraZoom = cameraState.zoom
            self?.lastCameraBearing = cameraState.bearing
            self?.lastCameraPitch = cameraState.pitch
        }
        if let center = lastCameraCenter, let zoom = lastCameraZoom, let bearing = lastCameraBearing, let pitch = lastCameraPitch {
            let lastState = CameraOptions(center: center, zoom: zoom, bearing: bearing, pitch: pitch)
            mapView?.camera.ease(to: lastState, duration: 0.5)
        } else {
            mapView = MapView(frame: frame, mapInitOptions: mapInitOptions)
        }
        mapView?.isOpaque = false
        mapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView?.location.options.puckType = .puck2D(.makeDefault(showBearing: true))
        self.annotationManager = mapView?.annotations.makePointAnnotationManager()
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

                let fillColorExpression = Exp(.interpolate) {
                    Exp(.linear)
                    Exp(.zoom)
                    0
                    UIColor.green
                    1
                    UIColor.green
                    6
                    self!.isDarkModeEnabled ? UIColor(red: 1/255, green: 50/255, blue: 32/255, alpha: 1) : UIColor(red: 213/255, green: 255/255, blue: 196/255, alpha: 1)
                }
                fillLayer.fillColor = .expression(fillColorExpression)
                fillLayer.fillOpacity = .constant(1)
                
                let landLayerId = mapView.mapboxMap.style.allLayerIdentifiers.first(where: { $0.id.contains("land") || $0.id.contains("landcover") })?.id

                if let landLayerId = landLayerId {
                    try mapView.mapboxMap.style.addLayer(fillLayer, layerPosition: .above(landLayerId))
                } else {
                    try mapView.mapboxMap.style.addLayer(fillLayer)
                }

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
        
        self.lastCameraCenter = cameraOptions.center
        self.lastCameraZoom = cameraOptions.zoom
        self.lastCameraBearing = cameraOptions.bearing
        self.lastCameraPitch = cameraOptions.pitch
    }
    
    func generateGridlines(insetBy inset: Double = 0.25) -> [LineString] {
        var gridlines = [LineString]()

        let minLat = -90.0
        let maxLat = 90.0
        let minLong = -180.0
        let maxLong = 180.0

        for lat in stride(from: minLat, through: maxLat, by: inset) {
            let line = LineString([
                CLLocationCoordinate2D(latitude: lat, longitude: minLong),
                CLLocationCoordinate2D(latitude: lat, longitude: maxLong)
            ])
            gridlines.append(line)
        }

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
                if mapView.mapboxMap.style.layerExists(withId: "road-simple") {
                    try mapView.mapboxMap.style.addLayer(lineLayer, layerPosition: .above("road-simple"))
                } else {
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
    
}

extension TemplateMapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("LOG: Test")
        if let newLocation = locations.last {
            checkBeenThere(location: newLocation)
        }
    }
}
