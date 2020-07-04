//
//  ViewController.swift
//  RouteView
//
//  Created by Kelly O'Brien on 6/25/20.
//  Copyright © 2020 Kismet Development. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var startRunButton: RoundButton!
    @IBOutlet weak var endRunButton: RoundButton!
    @IBOutlet weak var centerOnLocationButton: UIButton!
    @IBOutlet weak var distanceLabel: UILabel!
    
    var routeAnnotation: Route?
    var locationsPassed = [CLLocation]()
    let locationManager = CLLocationManager()
    var isRunning = false
    var route: MKPolyline?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        checkLocationAuthStatus()
    }

    func initiateRun() {
        startRunButton.isHidden = true
        endRunButton.isHidden = false
        // distance = Measurement(value: 0, unit: UnitLength.meters)
        //distanceTraveled = 0
        locationsPassed.removeAll()
        route = nil
        removeOverlays()
        startLocationUpdates()
    }
    
    func startLocationUpdates() {
        isRunning = true
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
    }
    
    func addLocationsToRouteArray(_ locations: [CLLocation]) {
        for location in locations {
            if !locationsPassed.contains(location) {
                locationsPassed.append(location)
            }
        }
    }
    
    func stop() {
        isRunning = false
        startRunButton.isHidden = false
        endRunButton.isHidden = true
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: IBActions
    @IBAction func startRunTapped(sender: RoundButton) {
        initiateRun()
    }
    
    @IBAction func endRunButtonPressed(_ sender: RoundButton) {
        stop()
        displayRoute()
    }
    
    @IBAction func resetMapCenter(_ sender: RoundButton) {
        centerMapOnUserLocation()
    }
}

// MARK: Setup MapKit
extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
//        renderer.strokeColor = .systemBlue
//        renderer.lineWidth = 5
//        renderer.alpha = 0.5
//
//        return renderer
        
        if let mapPolyline = overlay as? MKPolyline {
            let polyLineRenderer = MKPolylineRenderer(polyline: mapPolyline)
            polyLineRenderer.strokeColor = .darkGray
            polyLineRenderer.lineWidth = 4.0
            polyLineRenderer.alpha = 0.5
            return polyLineRenderer
        }
        fatalError("Polyline Renderer could not be initialized")
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Route {
            let id = "pin"
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.animatesDrop = true
            view.pinTintColor = annotation.coordinateType == .start ? .green : .red
            return view
        }
        return nil
    }
    
    func displayRoute() {
        var routeCoordinates = [CLLocationCoordinate2D]()
        for location in locationsPassed {
            routeCoordinates.append(location.coordinate)
        }
        route = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
        guard let route = route else { return }
        mapView.addOverlay(route)
        mapView.setVisibleMapRect(route.boundingMapRect, edgePadding: UIEdgeInsets(top: 200, left: 50, bottom: 50, right: 50), animated: true)
        
        //calculateAndDisplayDistance()
        setupAnnotations()
    }
    
    func setupAnnotations() {
        guard let startLocation = locationsPassed.first?.coordinate, let endLocation = locationsPassed.last?.coordinate, locationsPassed.count > 1 else {
            return
        }
        let startAnnotation = Route(coordinateType: .start, coordinate: startLocation)
        let endAnnotation = Route(coordinateType: .end, coordinate: endLocation)
        
        mapView.addAnnotation(startAnnotation)
        mapView.addAnnotation(endAnnotation)
    }
    
    func removeOverlays() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
    }
}

//MARK: CLLocation Manager Delegate
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else {
            return
        }
        if isRunning {
            addLocationsToRouteArray(locations)
        }
        
        let region = MKCoordinateRegion.init(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint("Error getting location: \(error.localizedDescription)")
    }
    
    func centerMapOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
            mapView.showsUserLocation = true
     
        } else {
            print("3-else. FROM: centerMapOnUserLocation()  -- calls locationManager.stopUpdatingLocation() -- WHY?????????")
            // ********** NEED TO ADD ERROR MESSAGE FOR USER ****************
            locationManager.stopUpdatingLocation()
            //errorView.isHidden = false
            //errorView.setErrorMessage("Location not found")
        }
    }
    
    func checkLocationAuthStatus() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            // CONFIRM THIS IS OK ?????????
            mapView.showsUserLocation = true
            
            locationManager.requestLocation()
            centerMapOnUserLocation()
        } else {
            locationManager.requestLocation()
        //LocationService.instance.locationManager.requestWhenInUseAuthorization()
        }
    }
}
