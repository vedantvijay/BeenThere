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

class FriendMapViewModel: TemplateMapViewModel {
    override func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { }
    
    override func addSquaresToMap(locations: [Location]) {
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
                self?.adjustMapViewToFitSquares()

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
//        self.adjustMapViewToFitSquares()

    }
    
    override func configureMapView(with frame: CGRect, styleURI: StyleURI) {
        let mapInitOptions = MapInitOptions(styleURI: styleURI)
        mapView?.mapboxMap.onEvery(event: .cameraChanged) { [weak self] _ in
            guard let cameraState = self?.mapView?.cameraState else { return }
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
//        mapView?.location.options.puckType = .puck2D(.makeDefault(showBearing: true))
        self.annotationManager = mapView?.annotations.makePointAnnotationManager()
        
        mapView?.ornaments.logoView.alpha = 0.1
        mapView?.ornaments.attributionButton.alpha = 0.1

        mapView?.ornaments.options.logo.position = .bottomLeft
        mapView?.ornaments.options.attributionButton.position = .bottomRight
        mapView?.ornaments.options.logo.margins = CGPoint(x: 10, y: 10)
        mapView?.ornaments.options.attributionButton.margins = CGPoint(x: 0, y: 10)
        mapView?.ornaments.scaleBarView.isHidden = true
    }
}
