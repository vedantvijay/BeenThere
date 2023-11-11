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

class TestMapViewModel: NSObject, ObservableObject {    
    @Published var mapView: MapView?
    @Published var annotationManager: PointAnnotationManager?
    var retryCount = 0
    @Published var tappedLocation: CLLocationCoordinate2D?
    
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
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        self.setUpFirestoreListener()
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
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView?.addGestureRecognizer(longPressGestureRecognizer)

    }
    
    func updateMapStyleURL() {
        if UITraitCollection.current.userInterfaceStyle == .dark {
            self.mapView?.mapboxMap.style.uri = StyleURI(rawValue: "mapbox://styles/jaredjones/clot6czi600kb01qq4arcfy2g")
        } else {
            self.mapView?.mapboxMap.style.uri = StyleURI(rawValue: "mapbox://styles/jaredjones/clot66ah300l501pe2lmbg11p")
        }
    }


    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: gesture.view)
            if let mapView = gesture.view as? MapView {
                let coordinate = mapView.mapboxMap.coordinate(for: point)

                // Create a new annotation
                var annotation = PointAnnotation(coordinate: coordinate)
                annotation.image = PointAnnotation.Image.init(image: UIImage(systemName: "pin")!, name: "pin")
                // Add annotation to the map
                annotationManager?.annotations = [annotation]
                tappedLocation = coordinate
                showTappedLocation = true

                // Center the map on the annotation
                let cameraOptions = CameraOptions(center: coordinate, zoom: mapView.cameraState.zoom)
                mapView.mapboxMap.setCamera(to: cameraOptions)
            }
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
                fillLayer.fillColor = .constant(StyleColor(UIColor(red: 144/255, green: 238/255, blue: 144/255, alpha: 1)))
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
//            // After adding layers, check if camera state should be restored
//            if let self = self, let savedState = self.savedCameraState {
//                let cameraOptions = CameraOptions(center: CLLocationCoordinate2D(latitude: savedState.latitude, longitude: savedState.longitude), zoom: savedState.zoom, bearing: 0)
//                mapView.mapboxMap.setCamera(to: cameraOptions) // Directly set camera without animation
//            } else {
//                self?.adjustMapViewToFitSquares()
//            }
        }

        
        // Check if the style is loaded before trying to add sources and layers
        if mapView.mapboxMap.style.isLoaded {
            // Style is already loaded, add layers immediately
            setupLayers()
        } else {
            // Style not loaded, wait for the event
            mapView.mapboxMap.onNext(event: .styleLoaded) { _ in
                setupLayers()
            }
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

        // Get camera options to fit the bounding box
        let cameraOptions = mapView.mapboxMap.camera(for: coordinateBounds, padding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), bearing: .zero, pitch: .zero)

        // Animate the camera movement to the new position using fly
        mapView.camera.fly(to: cameraOptions, duration: 0.5)

//        mapView.camera.fly(to: cameraOptions, duration: 1.5)
        while retryCount < 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.adjustMapViewToFitSquares()
            }
            retryCount += 1
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

extension TestMapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("LOG: Test")
        if let newLocation = locations.last {
            checkBeenThere(location: newLocation)
        }
    }
}
