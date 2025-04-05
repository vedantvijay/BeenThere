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
import Combine
import SwiftUI

class TemplateMapViewModel: NSObject, ObservableObject {
    private let speedReadingsKey = "speedReadings"

    
    @Published var mapSelection: MapSelection = .personal {
        didSet {
            observeLocations()
        }
    }
    @Published var friendLocations: [Location] = []
    @Published var mapView: MapView?
    @Published var annotationManager: PointAnnotationManager?
    @Published var tappedLocation: CLLocationCoordinate2D?
    @Published var isDarkModeEnabled: Bool = false
    @Published var locations: [Location] = []
    
    @Published var posts: [Post] = []
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
    var lastCameraPitch: CGFloat?
    var locationManager = CLLocationManager()
    var currentSquares = Set<String>()
    var db = Firestore.firestore()
    var locationsListener: ListenerRegistration?
    var spinTimer: Timer?
    
    var accountViewModel: AccountViewModel?
    var cancellable: AnyCancellable?
    

    init(accountViewModel: AccountViewModel) {
        super.init()
        self.accountViewModel = accountViewModel
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        observeLocations()
        accountViewModel.setUpFirestoreListener()
    }
    deinit {
        locationsListener?.remove()
    }
    
    func observeLocations() {
        switch mapSelection {
        case .personal:
            friendLocations = []
            cancellable = accountViewModel?.$locations.sink { [weak self] newLocations in
                self?.locations = newLocations
                print("LOG: Personal locations updated")
                self?.addSquaresToMap(locations: newLocations)
                self?.adjustMapViewToFitSquares()
            }
        case .global:
            friendLocations = []
            guard let globalLocations = accountViewModel?.userLocations else { return }
            addSquaresToMap(locations: globalLocations)
            print("LOG: Global locations updated")
            centerMapOnLocation(location: locationManager.location ?? CLLocation(latitude: 50, longitude: 50))
        case .friends:
            // Gather all friends' locations and show them
            friendLocations = []
            guard let accountViewModel = accountViewModel else { return }
            
            friendLocations = gatherAllFriendsLocations(from: accountViewModel.friends)
            if !friendLocations.isEmpty {
                addSquaresToMap(locations: friendLocations)
                adjustMapViewToFitSquares()
                print("LOG: Friends' locations updated")
            } else {
                print("No friends' locations found")
            }
        case .friend(let friendID):
            fetchFriendLocations(id: friendID)
            addSquaresToMap(locations: friendLocations)
            adjustMapViewToFitSquares()
            print("adjusted")
        }
    }

    func gatherAllFriendsLocations(from friends: [[String: Any]]) -> [Location] {
        var allFriendLocations: [Location] = []
        for friend in friends {
            if let friendLocationsData = friend["locations"] as? [[String: Any]] {
                for dict in friendLocationsData {
                    if let lowLatitude = dict["lowLatitude"] as? Double,
                       let highLatitude = dict["highLatitude"] as? Double,
                       let lowLongitude = dict["lowLongitude"] as? Double,
                       let highLongitude = dict["highLongitude"] as? Double {
                        let location = Location(lowLatitude: lowLatitude, highLatitude: highLatitude, lowLongitude: lowLongitude, highLongitude: highLongitude)
                        allFriendLocations.append(location)
                    }
                }
            }
        }
        return allFriendLocations
    }
    func fetchFriendLocations(id: String) {
        guard let accountViewModel = accountViewModel else { return }
        print("UID: \(id)")

        if let friend = accountViewModel.friends.first(where: { $0["uid"] as? String == id }),
           let tempFriendLocations = friend["locations"] as? [[String: Any]] {
            
            // Convert each dictionary into a Location object
            friendLocations = tempFriendLocations.compactMap { dict in
                guard let lowLatitude = dict["lowLatitude"] as? Double,
                      let highLatitude = dict["highLatitude"] as? Double,
                      let lowLongitude = dict["lowLongitude"] as? Double,
                      let highLongitude = dict["highLongitude"] as? Double else {
                          return nil
                      }
                return Location(lowLatitude: lowLatitude, highLatitude: highLatitude, lowLongitude: lowLongitude, highLongitude: highLongitude)
            }
        } else {
            print("friend has no locations")
            friendLocations = []
        }
    }




    func configureMapView(with frame: CGRect, styleURI: StyleURI) {
        let mapInitOptions = MapInitOptions(styleURI: styleURI)
        mapView?.mapboxMap.onEvery(event: .cameraChanged) { [weak self] _ in
            guard let cameraState = self?.mapView?.mapboxMap.cameraState else { return }
            self?.lastCameraCenter = cameraState.center
            self?.lastCameraZoom = cameraState.zoom
            self?.lastCameraPitch = cameraState.pitch
        }
        if let center = lastCameraCenter, let zoom = lastCameraZoom, let pitch = lastCameraPitch {
            let lastState = CameraOptions(center: center, zoom: zoom, pitch: pitch)
            mapView?.camera.ease(to: lastState, duration: 0.5)
        } else {
            mapView = MapView(frame: frame, mapInitOptions: mapInitOptions)
        }
        mapView?.ornaments.scaleBarView.isHidden = true
        mapView?.isOpaque = false
        mapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView?.gestures.options.doubleTapToZoomInEnabled = true

        
        let scaleExpression = Exp(.interpolate) {
            Exp(.linear)
            Exp(.zoom)
            0
            0.2
            8
            1
            22
            1
        }

        
        var puck = Puck2DConfiguration.makeDefault(showBearing: true)
        mapView?.location.options.puckBearingEnabled = true
        puck.scale = .expression(scaleExpression)
        puck.pulsing = .default
        mapView?.location.options.puckType = .puck2D(puck)

        
        self.annotationManager = mapView?.annotations.makePointAnnotationManager()
        
        mapView?.ornaments.logoView.alpha = 1
        mapView?.ornaments.attributionButton.alpha = 1

        mapView?.ornaments.options.logo.position = .bottomLeft
        mapView?.ornaments.options.attributionButton.position = .bottomRight
        mapView?.ornaments.options.logo.margins = CGPoint(x: 10, y: 20)
        mapView?.ornaments.options.attributionButton.margins = CGPoint(x: 0, y: 20)
        mapView?.ornaments.scaleBarView.isHidden = true
        
        if spinTimer == nil && !areSquaresAdded() {
            startGlobeSpin()
        }
    }

    func centerMapOnLocation(location: CLLocation) {
        guard let mapView = mapView else { return }
        let coordinate = location.coordinate
        let zoomLevel = 2
        let cameraOptions = CameraOptions(center: coordinate, zoom: Double(zoomLevel), bearing: .zero, pitch: .zero)
        mapView.camera.fly(to: cameraOptions, duration: 0.5)
        if self.lastCameraCenter != CLLocationCoordinate2D(latitude: 0, longitude: 0) {
            self.lastCameraCenter = cameraOptions.center
            self.lastCameraZoom = cameraOptions.zoom
            self.lastCameraPitch = cameraOptions.pitch
        }
    }
    
    func centerMapOnLocationWithoutZoom(location: CLLocation) {
        guard let mapView = mapView else { return }
        let coordinate = location.coordinate
//        let zoomLevel = 2
        let cameraOptions = CameraOptions(center: coordinate, bearing: .zero, pitch: .zero)
        mapView.camera.fly(to: cameraOptions, duration: 0.5)
        if self.lastCameraCenter != CLLocationCoordinate2D(latitude: 0, longitude: 0) {
            self.lastCameraCenter = cameraOptions.center
            self.lastCameraZoom = cameraOptions.zoom
            self.lastCameraPitch = cameraOptions.pitch
        }
    }
    
    func splashDefault() {
        guard let mapView = mapView else { return }
        
        let cameraOptions = CameraOptions(center: CLLocationCoordinate2D(latitude: 50, longitude: 50), zoom: 0)
        mapView.mapboxMap.setCamera(to: cameraOptions)
    }
    
    
    
    func adjustMapViewToFitSquares(duration: Double = 0.5) {
        guard let mapView = mapView else { return }

        let locationsToUse = (mapSelection == .personal) ? self.locations : self.friendLocations
        guard let boundingBox = self.boundingBox(for: locationsToUse) else { return }

        // Create a Polygon that represents the bounding box
        let coordinates = [
            boundingBox.southWest,
            CLLocationCoordinate2D(latitude: boundingBox.southWest.latitude, longitude: boundingBox.northEast.longitude),
            boundingBox.northEast,
            CLLocationCoordinate2D(latitude: boundingBox.northEast.latitude, longitude: boundingBox.southWest.longitude),
            boundingBox.southWest
        ]
        
        let polygon = Polygon([coordinates])
        let geometry = Geometry.polygon(polygon)

        let cameraOptions = mapView.mapboxMap.camera(
            for: geometry,
            padding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
            bearing: 0,
            pitch: 0
        )
        
        mapView.camera.fly(to: cameraOptions, duration: duration)

        if self.lastCameraCenter != CLLocationCoordinate2D(latitude: 0, longitude: 0) {
            self.lastCameraCenter = cameraOptions.center
            self.lastCameraZoom = cameraOptions.zoom
            self.lastCameraPitch = cameraOptions.pitch
        }
    }

    func addAnnotationAndCenterMap(at coordinate: CLLocationCoordinate2D) {
        guard let mapView = mapView, let annotationManager = annotationManager else { return }

        annotationManager.annotations.removeAll()

        var annotation = PointAnnotation(coordinate: coordinate)
        annotation.image = PointAnnotation.Image(image: UIImage(systemName: "pin")!, name: "Pin")
        
        annotationManager.annotations = [annotation]
        
        tappedLocation = coordinate
        showTappedLocation = true
        
        // Calculate the offset based on the zoom level
        let zoomLevel = mapView.cameraState.zoom
        let latitudeOffset = calculateOffset(zoomLevel: zoomLevel, mapViewHeight: mapView.bounds.height)

        // Adjust the center position
        let adjustedCenter = CLLocationCoordinate2D(
            latitude: coordinate.latitude - latitudeOffset,
            longitude: coordinate.longitude
        )

        let cameraOptions = CameraOptions(center: showTappedLocation ? adjustedCenter : coordinate)
        mapView.camera.ease(to: cameraOptions, duration: 0.5)

        lastCameraCenter = coordinate
    }


    private func calculateOffset(zoomLevel: CGFloat, mapViewHeight: CGFloat) -> CLLocationDegrees {
        let degreesPerScreenHeightAtZoom0: CLLocationDegrees = 360
        let screenHeightPercentage: CGFloat = 0.10

        let scale = pow(2, zoomLevel)
        return degreesPerScreenHeightAtZoom0 * screenHeightPercentage / scale
    }
    
    func updateMapStyleURL() {
        if UITraitCollection.current.userInterfaceStyle == .dark {
            self.mapView?.mapboxMap.style.uri = StyleURI(rawValue: "mapbox://styles/jaredjones/clot6czi600kb01qq4arcfy2g")
        } else {
            self.mapView?.mapboxMap.style.uri = StyleURI(rawValue: "mapbox://styles/jaredjones/clot66ah300l501pe2lmbg11p")
        }
    }
    
    func startGlobeSpin() {
        spinTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self, let mapView = self.mapView else { return }
            if self.areSquaresAdded() {
                timer.invalidate()
                self.spinTimer = nil
                self.adjustMapViewToFitSquares(duration: 1.5)
            } else {
                var newBearing = mapView.cameraState.bearing + 0.5
                if newBearing >= 360 {
                    newBearing -= 360
                }
                let currentCamera = mapView.cameraState
                let cameraOptions = CameraOptions(
                    center: currentCamera.center,
                    zoom: currentCamera.zoom,
                    bearing: newBearing,
                    pitch: currentCamera.pitch
                )
                mapView.camera.ease(to: cameraOptions, duration: 0.05)
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
        
        let sourceId = "square-source"
        let layerId = "square-fill-layer"
        var source = GeoJSONSource(id: sourceId)
        let featureCollection = FeatureCollection(features: features)

        source.data = .featureCollection(FeatureCollection(features: features))
        
        let setupLayers = { [weak self] in
            do {
                if mapView.mapboxMap.style.sourceExists(withId: sourceId) {
                            try mapView.mapboxMap.style.updateGeoJSONSource(withId: sourceId, geoJSON: .featureCollection(featureCollection))
                        } else {
                            var source = GeoJSONSource(id: sourceId)
                            source.data = .featureCollection(featureCollection)
                            try mapView.mapboxMap.style.addSource(source)
                        }
                var fillLayer = FillLayer(id: layerId, source: sourceId)
                fillLayer.source = sourceId

                let fillColorExpression = Exp(.interpolate) {
                    Exp(.linear)
                    Exp(.zoom)
                    0
                    UIColor.green
                    1
                    UIColor.green
                    6
                    self!.isDarkModeEnabled ? UIColor(red: 0/255, green: 100/255, blue: 0/255, alpha: 1) : UIColor(red: 144/255, green: 238/255, blue: 144/255, alpha: 1)
                }
                fillLayer.fillColor = .expression(fillColorExpression)
                fillLayer.fillOpacity = .constant(1)

                if mapView.mapboxMap.style.layerExists(withId: layerId) {
                    try mapView.mapboxMap.style.updateLayer(withId: layerId, type: FillLayer.self) { layer in
                        layer.fillColor = fillLayer.fillColor
                        layer.fillOpacity = fillLayer.fillOpacity
                    }
                } else {
                    let landLayerId = mapView.mapboxMap.style.allLayerIdentifiers.first(where: { $0.id.contains("land") || $0.id.contains("landcover") })?.id
                    if let landLayerId = landLayerId {
                        try mapView.mapboxMap.style.addLayer(fillLayer, layerPosition: .above(landLayerId))
                    } else {
                        try mapView.mapboxMap.style.addLayer(fillLayer)
                    }
                }

                self?.currentSquares = Set(features.compactMap { feature in
                    if case let .string(id) = feature.identifier {
                        return id
                    }
                    return nil
                })
            } catch {
                print("Failed to add or update squares on the map: \(error)")
            }
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
        if areSquaresAdded() {
            clearExistingSquares()
            addSquaresToMap(locations: locations)
        }
    }

    func clearExistingSquares() {
        guard let mapView = mapView else { return }
        let sourceId = "square-source"
        let layerId = "square-fill-layer"

        if mapView.mapboxMap.style.sourceExists(withId: sourceId) {
            try? mapView.mapboxMap.style.removeSource(withId: sourceId)
        }

        if mapView.mapboxMap.style.layerExists(withId: layerId) {
            try? mapView.mapboxMap.style.removeLayer(withId: layerId)
        }
    }




    private func areSquaresAdded() -> Bool {
        return locations.count >= 1
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

        var source = GeoJSONSource(id: "gridline-source")
        source.data = .featureCollection(FeatureCollection(features: features))

        let addLayer = {
            var lineLayer = LineLayer(id: "gridline-layer", source: "gridline-source")
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
                try mapView.mapboxMap.style.addSource(source)
                addLayer()
            } catch {
                print("Error adding gridlines source to the map: \(error)")
            }
        } else {
            mapView.mapboxMap.onNext(event: .styleLoaded) { _ in
                do {
                    try mapView.mapboxMap.style.addSource(source)
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

        let increment: Double = 0.25
        
        let lowLatitude = floor(latitude / increment) * increment
        let highLatitude = lowLatitude + increment
        let lowLongitude = floor(longitude / increment) * increment
        let highLongitude = lowLongitude + increment

        let locationExists = locations.contains { existingLocation in
            existingLocation.lowLatitude == lowLatitude &&
            existingLocation.highLatitude == highLatitude &&
            existingLocation.lowLongitude == lowLongitude &&
            existingLocation.highLongitude == highLongitude
        }

        if !locationExists {
            print("LOG: Saving to firestore")
            saveLocationToFirestore(lowLat: lowLatitude, highLat: highLatitude, lowLong: lowLongitude, highLong: highLongitude)
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
    
    func layerExists(withId id: String) -> Bool {
            return mapView?.mapboxMap.style.layerExists(withId: id) ?? false
        }
    
}

extension TemplateMapViewModel: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = locations.last {
//            print("Speed Accuracy: \(newLocation.speedAccuracy.description)")
//            print("Speed: \(newLocation.speed.description)")
            if newLocation.speedAccuracy.magnitude < 10 * 0.44704 && newLocation.speedAccuracy != -1 {
                if newLocation.speed <= 100 * 0.44704 && newLocation.speed.magnitude != -1 {
                    checkBeenThere(location: newLocation)
                } else {
                    print("Average speed is over 100 mph. Location not updated.")
                }
            }
        }
    }
}



