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
import Firebase
import FirebaseAuth
import UIKit

class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate, MGLMapViewDelegate {
    private var locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var mapView = MGLMapView(frame: .zero, styleURL: URL(string: "https://api.maptiler.com/maps/backdrop/style.json?key=s9gJbpLafAf5TyI9DyDr")!)
    @Published var userLocations: [CLLocation] = []
    @Published var isHeatmapActive: Bool = true
    @Published var isFlatStyle: Bool = false
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid


    private var locationListener: ListenerRegistration?


    private let db = Firestore.firestore() // Firebase Firestore instance

    override init() {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        mapView.delegate = self
        initializeUser()
        setupLocationListener()
    }
    
    func beginBackgroundUpdateTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            self.endBackgroundUpdateTask()
        }
        // Also, add code here to start any long-running tasks (like saving to Firestore).
    }

    func endBackgroundUpdateTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    
    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        updateHeatmapRadius()
    }
    
    func toggleHeatmap() {
        isHeatmapActive.toggle()
        updateHeatmapVisibility()
    }

    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        fetchLocationsFromFirestore()
    }
    
    func toggleFlatStyle() {
        isFlatStyle.toggle()
    }


    func updateHeatmapRadius() {
        if let heatmapLayer = mapView.style?.layer(withIdentifier: "locationHeatmap") as? MGLHeatmapStyleLayer {
            // Adjust the radius of the heatmap based on zoom level
            heatmapLayer.heatmapRadius = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
                                                      [10: 10, 100: 100, 1000: 1000, 2000: 1000])
        }
    }
    
    func updateHeatmapVisibility() {
        if let heatmapLayer = mapView.style?.layer(withIdentifier: "locationHeatmap") as? MGLHeatmapStyleLayer {
            heatmapLayer.isVisible = isHeatmapActive
        }
    }
    
    func setupLocationListener() {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }

        let userDocumentRef = db.collection("users").document(userId)

        locationListener = userDocumentRef.addSnapshotListener { (documentSnapshot, error) in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            guard let data = document.data() else {
                print("Document data was empty.")
                return
            }

            self.userLocations = (data["locations"] as? [[String: Any]])?.compactMap { dict in
                if let geoPoint = dict["geoPoint"] as? GeoPoint {
                    return CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                }
                return nil
            } ?? []
            self.updateHeatmap()
        }
    }

    deinit {
        locationListener?.remove()  // Clean up the listener when the view model is deinitialized
    }
    
    func featuresFromLocations(locations: [CLLocation]) -> MGLShapeCollectionFeature {
        let features = locations.map { location -> MGLPointFeature in
            let feature = MGLPointFeature()
            feature.coordinate = location.coordinate
            return feature
        }
        return MGLShapeCollectionFeature(shapes: features)
    }

    func updateHeatmap() {
        let sourceId = "locations"
            
        if let source = mapView.style?.source(withIdentifier: sourceId) as? MGLShapeSource {
            source.shape = self.featuresFromLocations(locations: self.userLocations)
        } else {
            let source = MGLShapeSource(identifier: sourceId, shape: self.featuresFromLocations(locations: self.userLocations))
            mapView.style?.addSource(source)

            if isHeatmapActive {
                let layer = MGLHeatmapStyleLayer(identifier: "locationHeatmap", source: source)
                mapView.style?.addLayer(layer)
            }
        }
    }



    
    func fetchLocationsFromFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        let userDocumentRef = db.collection("users").document(userId)
        userDocumentRef.getDocument { (document, error) in
            if let document = document, let data = document.data() {
                self.userLocations = (data["locations"] as? [[String: Any]])?.compactMap { dict in
                    if let geoPoint = dict["geoPoint"] as? GeoPoint {
                        return CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                    }
                    return nil
                } ?? []
                self.updateHeatmap()
            } else if let error = error {
                print("Error fetching locations: \(error)")
            }
        }
    }

    func initializeUser() {
        if let currentUser = Auth.auth().currentUser {
            setupUserDocumentIfNeeded(userId: currentUser.uid)
        } else {
            authenticateAnonymously()
        }
    }
    
    func authenticateAnonymously() {
        Auth.auth().signInAnonymously { (authResult, error) in
            if let error = error {
                print("Error with anonymous authentication: \(error)")
                return
            }
            
            // Successfully authenticated
            if let user = authResult?.user {
                print("Logged in anonymously with user ID: \(user.uid)")
                self.setupUserDocumentIfNeeded(userId: user.uid)
            }
        }
    }

    func setupUserDocumentIfNeeded(userId: String) {
        // Check if user document already exists
        let userDocumentRef = self.db.collection("users").document(userId)
        userDocumentRef.getDocument { (document, error) in
            if let document = document, !document.exists {
                // If user document doesn't exist, create one with an empty 'locations' array
                userDocumentRef.setData([
                    "locations": []
                ]) { error in
                    if let error = error {
                        print("Error creating user document: \(error)")
                    } else {
                        print("User document created successfully!")
                    }
                }
            } else if let error = error {
                print("Error checking user document: \(error)")
            }
        }
    }


    func saveLocationToFirestore(location: CLLocation) {
        // Declare the backgroundTask outside the closure
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid

        backgroundTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        guard let user = Auth.auth().currentUser else {
            // Handle the error - perhaps prompt the user to sign in
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
            return
        }

        let locationData: [String: Any] = [
            "geoPoint": GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
            "timestamp": Timestamp(date: location.timestamp)
        ]

        let userDocumentRef = db.collection("users").document(user.uid)

        userDocumentRef.updateData([
            "locations": FieldValue.arrayUnion([locationData])
        ]) { error in
            if let error = error {
                print("Error saving location: \(error)")
            } else {
                print("Location saved successfully!")
            }
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = locations.last {
            saveLocationToFirestore(location: newLocation)
        }
    }

}

