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
import CoreData

class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate, MGLMapViewDelegate {
    private var locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var mapView = MGLMapView(frame: .zero, styleURL: URL(string: "https://api.maptiler.com/maps/backdrop/style.json?key=s9gJbpLafAf5TyI9DyDr")!)
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    let moc = PersistenceController.shared.container.viewContext
    
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
        mapView.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: .NSManagedObjectContextObjectsDidChange, object: nil)
    }
    
    @objc func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }

        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, !inserts.isEmpty {
            let newLocations = inserts.compactMap { $0 as? Location }
            addSquaresToMap(locations: newLocations)
        }
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
        let squares: [Location] = PersistenceController.shared.fetchLocations()
        addSquaresToMap(locations: squares)
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

        // Create a predicate to check if the location is within any of the stored squares
        let predicate = NSPredicate(format: "lowLatitude <= %lf AND highLatitude > %lf AND lowLongitude <= %lf AND highLongitude > %lf", latitude, latitude, longitude, longitude)

        // Use the fetch function from PersistenceController to retrieve the filtered results
        let results: [Location] = PersistenceController.shared.fetchLocations(predicate: predicate)

        if results.isEmpty {
            // If the location is not within any existing square, create a new Location entity and save the context
            let context = PersistenceController.shared.container.viewContext
            if let locationEntity = NSEntityDescription.insertNewObject(forEntityName: "Location", into: context) as? Location {
                locationEntity.lowLatitude = lowLatitude
                locationEntity.highLatitude = highLatitude
                locationEntity.lowLongitude = lowLongitude
                locationEntity.highLongitude = highLongitude
                PersistenceController.shared.saveContext()
            }
        }
    }

}
