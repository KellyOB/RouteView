//
//  ViewController.swift
//  RouteView
//
//  Created by Kelly O'Brien on 6/25/20.
//  Copyright © 2020 Kismet Development. All rights reserved.
//

import UIKit
import MapKit
//import CoreLocation

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var startRunButton: RoundButton!
    @IBOutlet weak var endRunButton: RoundButton!
    @IBOutlet weak var centerOnLocationButton: UIButton!
    
    var routeAnnotation: RouteTaken?
    var locationsPassed = [CLLocation]()
    let locationManager = CLLocationManager()
    var isRunning = false
    var route: MKPolyline?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("1. FROM: viewDidLoad() -- calls checkLocationAuthStatus()")
        mapView.delegate = self
        checkLocationAuthStatus()
    }
        

    
    func initiateRun() {
        startRunButton.isHidden = true
        endRunButton.isHidden = false
        // distance = Measurement(value: 0, unit: UnitLength.meters)
        //distanceTraveled = 0
        print("5. FROM: initiateRun() -- calls locationsPassed.removeAll()")
        locationsPassed.removeAll()
        route = nil
        print("5. FROM: initiateRun() -- calls removeOverlays()")
        removeOverlays()
        print("5. FROM: initiateRun() -- calls startLocationUpdates()")
        startLocationUpdates()
    }
    
    func startLocationUpdates() {
        print("6. FROM: startLocationUpdates() -- sets isRunning to true \n sets allowsBackgroundLocationUpdates = true \n calls startUpdatingLocation()")
        isRunning = true
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
    }
    
    func addLocationsToRouteArray(_ locations: [CLLocation]) {
        for location in locations {
            if !locationsPassed.contains(location) {
                locationsPassed.append(location)
                print("8. FROM: addLocationToRouteArray()")
            }
        }
    }
    
    func stop() {
        print("9.  FROM: stop() -- sets isRunning to false, hides End Button, revaeals start button")
        isRunning = false
        startRunButton.isHidden = false
        endRunButton.isHidden = true
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: IBActions
    @IBAction func startRunTapped(sender: RoundButton) {
        print("4. FROM: startRunTapped() -- calls initiateRun()")
        initiateRun()
    }
    
    @IBAction func endRunButtonPressed(_ sender: RoundButton) {
        print("8: FROM: endRunBottonTapped() - call stop() and displayRoute()")
        stop()
        displayRoute()
    }
    
    @IBAction func resetMapCenter(_ sender: RoundButton) {
        print("FROM: resetMapCenter() button -- calls centerMapOnUserLocation())")
        centerMapOnUserLocation()
    }
}

// MARK: Setup MapKit
extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = .systemBlue
        renderer.lineWidth = 5
        renderer.alpha = 0.5
        
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? RouteTaken {
            let id = "pin"
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.canShowCallout = true
            view.animatesDrop = true
            view.pinTintColor = annotation.coordinateType == .start ? .green : .red
            view.calloutOffset = CGPoint(x: -8, y: -3)
            return view
        }
        return nil
    }
    
    func displayRoute() {
        print("10.  FROM: displayRoute()")
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
    
    // from running app
    func setupAnnotations() {
        guard let startLocation = locationsPassed.first?.coordinate, let endLocation = locationsPassed.last?.coordinate, locationsPassed.count > 1 else {
            return
        }
        let startAnnotation = RouteTaken(coordinateType: .start, coordinate: startLocation)
        let endAnnotation = RouteTaken(coordinateType: .end, coordinate: endLocation)
        
        mapView.addAnnotation(startAnnotation)
        mapView.addAnnotation(endAnnotation)
    }
    
    func removeOverlays() {
        print("6. FROM: removeOverlays()")
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
    }
    
    
    
    //    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    //        if let annotation = annotation as? RouteTaken {
    //            let id = "pin"
    //            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
    //            view.canShowCallout = true
    //            view.animatesDrop = true
    //            view.pinTintColor = .green
    //            view.calloutOffset = CGPoint(x: -8, y: -3)
    //            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
    //            return view
    //        } else {
    //            return nil
    //        }
    //    }
    
    //    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    //        guard let coordinates = LocationService.instance.currentLocation, let parkedCarCoordinates = routeAnnotation?.coordinate else { return }
    //        getRouteRan(startingCoordinates: parkedCarCoordinates, endingCoordinates: coordinates)
    //        view.setSelected(false, animated: true)
    //    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else {
            return
        }
        if isRunning {
            print("7. FROM: didUpdateLocations() -- if isRunning then calls addLocationsToRouteArray(locations)")
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
            print("3. FROM: centerMapOnUserLocation()")
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
            print("2. FROM: checkLocationAuthStatus() -- is Authorized - calls requestLocation() and centerMapOnUserLocation()")
            //self.mapView.showsUserLocation = true
            
            locationManager.requestLocation()
            centerMapOnUserLocation()
            
            //LocationService.instance.customUserLocDelegate = self
            
        } else {
            locationManager.requestLocation()
            //LocationService.instance.locationManager.requestWhenInUseAuthorization()
            print("2-else. FROM: checkLocationAuthStatus() -- calls requestWhenInUseAuthorization()")
        }
    }
}

//MARK: CustomUserLocDelegate
//extension ViewController: CustomUserLocDelegate {
//
//    func userLocationUpdated(location: CLLocation) {
//        print("5.  from userLocationUpdated() -- called from locationManager.didUpdateLocations -- Calls centerMapOnUserLocation function \(location.coordinate)")
//        centerMapOnUserLocation(coordinates: location.coordinate)
//
//    }
//
//    func addLocationsToRouteArray(_ locations: [CLLocation]) {
//        for location in locations {
//            if !locationsPassed.contains(location) {
//                locationsPassed.append(location)
//                print("7.  from addLocationToRouteArray() - appends locationsPassed array with location in locations \(location)")
//            }
//        }
//    }
//}

// MARK: Add Polyline to Map
//extension ViewController {
//
//    func getRouteRan(startingCoordinates: CLLocationCoordinate2D, endingCoordinates: CLLocationCoordinate2D) {
//
//        print("11.  getRouteRan function- called when endRun Buton Tapped")
//        print("11-1 \(locationsPassed)")
//       // removeOverlays()
//        LocationService.instance.locationManager.allowsBackgroundLocationUpdates = false
//        LocationService.instance.locationManager.stopUpdatingLocation()
//        let request = MKDirections.Request()
//        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startingCoordinates))
//        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endingCoordinates))
//
//
//        print("12.  request source \(request.source)")
//        print("13.  request destination \(request.destination)")
//        // can add different type of transport types
//        request.transportType = .walking
//
//        let directions = MKDirections(request: request)
//
//        directions.calculate { [unowned self] (response, error) in
//            guard let route = response?.routes.first else { return }
//            self.mapView.addOverlay(route.polyline)
//
//            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 200, left: 50, bottom: 50, right: 50), animated: true)
//
//            for step in route.steps {
//                print("15. \(step.distance)")
//                //print("7-4. \(step.instructions)")
//            }
//        }
//    }

//    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//        print("14. mapView renderer for:   ")
//        let directionRenderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
//        directionRenderer.strokeColor = .systemBlue
//        directionRenderer.lineWidth = 5
//        directionRenderer.alpha = 0.85
//
//        return directionRenderer
//    }

//    func removeOverlays() {
//        print("???????.  remover overlays called")
//        self.mapView.removeAnnotations(mapView.annotations)
//        self.mapView.removeOverlays(self.mapView.overlays)
//    }
//}
