//
//  NavigatingView.swift
//  BeenThere
//
//  Created by Jared Jones on 12/10/23.
//

import SwiftUI
import MapboxMaps
import MapboxDirections
import MapboxNavigation
import MapboxCoreNavigation

struct NavigatingView: View {
    @StateObject var navigationManager = NavigationManager()
    let startPoint: CLLocationCoordinate2D
    let endPoint: CLLocationCoordinate2D
    
    var body: some View {
        MapboxMapView()
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                navigationManager.startNavigation(from: startPoint, to: endPoint)
            }
            .sheet(isPresented: $navigationManager.showNavigationView) {
                NavigationViewWrapper(navigationViewController: navigationManager.navigationViewController!)
            }
    }
}




struct MapboxMapView: UIViewRepresentable {
    func makeUIView(context: Context) -> MapView {
        let mapView = MapView(frame: .zero)
        _ = CameraOptions(center: CLLocationCoordinate2D(latitude: 40.730610, longitude: -73.935242), zoom: 10)
        return mapView
    }

    func updateUIView(_ uiView: MapView, context: Context) {}

    func startNavigation(from startPoint: CLLocationCoordinate2D, to endPoint: CLLocationCoordinate2D) {
        let origin = Waypoint(coordinate: startPoint, coordinateAccuracy: -1, name: "Start")
        let destination = Waypoint(coordinate: endPoint, coordinateAccuracy: -1, name: "End")
        let options = RouteOptions(waypoints: [origin, destination])

        Directions.shared.calculate(options) { (_, result) in
            switch result {
            case .failure(let error):
                print("Error calculating directions: \(error)")
            case .success(let response):
                guard (response.routes?.first) != nil else { return }
                let indexedRouteResponse = IndexedRouteResponse(routeResponse: response, routeIndex: 0)

                DispatchQueue.main.async {
                    _ = NavigationViewController(for: indexedRouteResponse)
                    // Present the NavigationViewController
                    // Note: You need to implement this part based on your navigation stack.
                }
            }
        }

    }
}

class NavigationManager: ObservableObject {
    @Published var showNavigationView = false
    var navigationViewController: NavigationViewController?
    
    func startNavigation(from startPoint: CLLocationCoordinate2D, to endPoint: CLLocationCoordinate2D) {
        let origin = Waypoint(coordinate: startPoint, coordinateAccuracy: -1, name: "Start")
        let destination = Waypoint(coordinate: endPoint, coordinateAccuracy: -1, name: "End")
        let options = RouteOptions(waypoints: [origin, destination])

        Directions.shared.calculate(options) { [weak self] (_, result) in
            switch result {
            case .failure(let error):
                print("Error calculating directions: \(error)")
            case .success(let response):
                guard (response.routes?.first) != nil else { return }
                let indexedRouteResponse = IndexedRouteResponse(routeResponse: response, routeIndex: 0)
                
                DispatchQueue.main.async {
                        self?.navigationViewController = NavigationViewController(for: indexedRouteResponse)
                        self?.showNavigationView = true
                    }
            }
        }
    }
}

struct NavigationViewWrapper: UIViewControllerRepresentable {
    var navigationViewController: NavigationViewController

    func makeUIViewController(context: Context) -> NavigationViewController {
        return navigationViewController
    }

    func updateUIViewController(_ uiViewController: NavigationViewController, context: Context) {}
}


//#Preview {
//    NavigatingView()
//}
