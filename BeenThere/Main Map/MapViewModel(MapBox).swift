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

class TestMapViewModel: NSObject, ObservableObject {
    @Published var mapView: MapView?
    @Published var locations: [Location] = [] {
        didSet {
            addSquaresToMap(locations: locations)
        }
    }
    var locationManager = CLLocationManager()
    var currentSquares = Set<String>()
    private var db = Firestore.firestore()
    private var locationsListener: ListenerRegistration?
    

    override init() {
        super.init()
        locationManager.delegate = self
        setUpFirestoreListener()
    }
    deinit {
        locationsListener?.remove()
    }
    
    func configureMapView(with frame: CGRect, styleURI: StyleURI) {
        let mapInitOptions = MapInitOptions(styleURI: styleURI)
        mapView = MapView(frame: frame, mapInitOptions: mapInitOptions)
        mapView?.backgroundColor = UIColor.white
        mapView?.isOpaque = false
        mapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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
                
                // Find the ID of the first symbol layer to add your layer beneath it
                if let firstSymbolLayerId = mapView.mapboxMap.style.allLayerIdentifiers.first(where: { $0.type == .background })?.id {
                    try mapView.mapboxMap.style.addLayer(fillLayer, layerPosition: .below(firstSymbolLayerId))
                } else {
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


}

extension TestMapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
}
