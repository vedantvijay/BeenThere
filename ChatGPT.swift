//
//  ChatGPT.swift
//  BeenThere
//
//  Created by Jared Jones on 11/5/23.
//

//class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate, MGLMapViewDelegate {
//    private var locationManager = CLLocationManager()
//    @Published var currentLocation: CLLocation?
//    @Published var mapView: MGLMapView!
//    @Published var tappedLocation: CLLocationCoordinate2D?
//    var lastAddedSquareLayerIdentifier: String?
//
//    @Published var showTappedLocation: Bool = false {
//        didSet {
//            if !showTappedLocation {
//                tappedAnnotation = nil
//            }
//        }
//    }
//
//    @Published var tappedAnnotation: MGLPointAnnotation?
//    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
//    private var db = Firestore.firestore()
//    private var locationsListener: ListenerRegistration?
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
//        locationManager.pausesLocationUpdatesAutomatically = false
//        locationManager.distanceFilter = 100
//        locationManager.startUpdatingLocation()
//        locationManager.startMonitoringSignificantLocationChanges()
//        locationManager.delegate = self
//        locationManager.requestWhenInUseAuthorization()
//        self.setUpFirestoreListener()
//        mapView.delegate = self
//    }
//    deinit {
//        locationsListener?.remove()
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
//                layer.fillColor = NSExpression(forConstantValue: UIColor.blue)
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
//    func coordinateBoundsEqual(lhs: MGLCoordinateBounds, rhs: MGLCoordinateBounds) -> Bool {
//        return lhs.sw.latitude == rhs.sw.latitude &&
//               lhs.sw.longitude == rhs.sw.longitude &&
//               lhs.ne.latitude == rhs.ne.latitude &&
//               lhs.ne.longitude == rhs.ne.longitude
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
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        if let newLocation = locations.last {
//            checkBeenThere(location: newLocation)
//        }
//    }
//    
//    
//    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
//        return nil
//    }
//
//    func totalAreaInChunks() -> Double {
//        return locations.map { calculateAreaOfChunk(lowLat: $0.lowLatitude, highLat: $0.highLatitude, lowLong: $0.lowLongitude, highLong: $0.highLongitude) }.reduce(0, +)
//    }
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
//        layer.lineColor = NSExpression(forConstantValue: UIColor.lightGray)
//        
//        // Interpolate line width based on zoom level
//        layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
//                                       [0: 0, 4: 0.25, 6: 0.5, 10: 1, 11: 1])
//        
//        // Interpolate line opacity based on zoom level. This will make the lines fade out as you zoom out.
//        layer.lineOpacity = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
//                                         [3: 0.01, 11: 0.25, 13: 0.5, 16: 1])
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
//}
//struct MapView: UIViewRepresentable {
//    @ObservedObject var viewModel = MapViewModel()
//
//    func makeCoordinator() -> MapViewModel {
//        return viewModel
//    }
//
//    func makeUIView(context: Context) -> MGLMapView {
//        viewModel.mapView.delegate = viewModel
//        viewModel.mapView.showsUserLocation = true
//        viewModel.mapView.attributionButtonPosition = .topRight
//        viewModel.mapView.logoViewPosition = .topLeft
//        viewModel.mapView.setUserTrackingMode(.none, animated: true, completionHandler: nil)
//        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
////        longPress.minimumPressDuration = 1.0
//        viewModel.mapView.addGestureRecognizer(longPress)
//        
//        // Disable autoresizing mask translation
//        viewModel.mapView.logoView.translatesAutoresizingMaskIntoConstraints = false
//        viewModel.mapView.attributionButton.translatesAutoresizingMaskIntoConstraints = false
//
//        // Set constraints for the logoView to ignore safe areas
//        NSLayoutConstraint.activate([
//            viewModel.mapView.logoView.topAnchor.constraint(equalTo: viewModel.mapView.topAnchor, constant: 20), // 8 points from the top
//            viewModel.mapView.logoView.leftAnchor.constraint(equalTo: viewModel.mapView.leftAnchor, constant: 20) // 8 points from the left
//        ])
//
//        // Set constraints for the attributionButton to ignore safe areas
//        NSLayoutConstraint.activate([
//            viewModel.mapView.attributionButton.topAnchor.constraint(equalTo: viewModel.mapView.topAnchor, constant: 20), // 8 points from the top
//            viewModel.mapView.attributionButton.rightAnchor.constraint(equalTo: viewModel.mapView.rightAnchor, constant: -20) // 8 points from the right
//        ])
//        
//        return viewModel.mapView
//    }
//
//    
//    func updateUIView(_ uiView: MGLMapView, context: Context) {
//        // Code to update the UIView, if necessary.
//        if let annotations = uiView.annotations {
//            uiView.removeAnnotations(annotations)
//        }
//        
//        // If there's a tappedAnnotation in the ViewModel, add it to the map
//        if let annotation = viewModel.tappedAnnotation {
//            uiView.addAnnotation(annotation)
//        }
//    }
//}
