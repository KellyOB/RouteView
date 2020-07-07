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
    
    @IBOutlet weak var roundedView: RoundedView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var startRunButton: UIButton!
    @IBOutlet weak var endRunButton: UIButton!
    @IBOutlet weak var centerOnLocationButton: UIButton!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeByDistanceLabel: UILabel!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var informationView: RoundedView!
    @IBOutlet weak var perMinuteLabel: UILabel!
    
    var routeDistance = 0.0
    var routeAnnotation: Route?
    var locationsPassed = [CLLocation]()
    let locationManager = CLLocationManager()
    var isRunning = false
    var isMiles = true
    var route: MKPolyline?
    var startTime = Date()
    var endTIme = Date()
    
    fileprivate var timer: Timer?
    var seconds: Int = 0

    func runTimer() {
         timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(ViewController.updateTimer)), userInfo: nil, repeats: true)
        
        
        
    }

    @objc func updateTimer() {
        seconds += 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        checkLocationAuthStatus()
        
        informationView.isHidden = true
    }
    
    func initiateRun() {
        startRunButton.isHidden = true
        endRunButton.isHidden = false
        // distance = Measurement(value: 0, unit: UnitLength.meters)
        //distanceTraveled = 0
        distanceLabel.text = ""
        locationsPassed.removeAll()
        route = nil
        removeOverlays()
        startLocationUpdates()
        isMiles = true
        informationView.isHidden = true
        seconds = 0
    }
    
    func startLocationUpdates() {
        isRunning = true
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        locationManager.pausesLocationUpdatesAutomatically = false
        
        //mapView.showsUserLocation = true
    }
    
    func stopLocationUpdates() {
        isRunning = false
        startRunButton.isHidden = false
        endRunButton.isHidden = true
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.stopUpdatingLocation()
        calculateDistance()
    }
    
    func addLocationsToRouteArray(_ locations: [CLLocation]) {
        for location in locations {
            if !locationsPassed.contains(location) {
                locationsPassed.append(location)
            }
        }
    }
    
    func calculateDistance() {
        var total = 0.0
        for i in 1..<locationsPassed.count {
            let previousDistance = locationsPassed[i-1]
            let currentDistance = locationsPassed[i]
            total += currentDistance.distance(from: previousDistance)
        }
        routeDistance = total
        
        distanceLabel.text = String(format: "%.2f Mi", routeDistance * 0.000621371)
        stepsLabel.text = String(format: "%.0f", routeDistance)
        timeLabel.text = convertTime()
        calculateTime()
        
    }
    
    func calculateTime() {
        let hour = seconds / 3600
        let pace = (routeDistance * 0.000621371) / Double(hour)
        print("**************************\(pace)")
//        var paceInMinutes = Double(seconds) / 60.0
//        var roundedMinutes = Double(floor(paceInMinutes))
//        var decimalSeconds = paceInMinutes - roundedMinutes
//        var intPace = Int(floor(roundedMinutes))
//        var seconds = Int(floor(decimalSeconds * 60))
        timeByDistanceLabel.text = String(format: "%.0f", pace)
    }
    
    func convertTime() -> String{
        let duration: TimeInterval = TimeInterval(seconds)

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional // Use the appropriate positioning for the current locale
        formatter.allowedUnits = [ .hour, .minute, .second ] // Units to display in the formatted string
        formatter.zeroFormattingBehavior = [ .pad ] // Pad with zeroes where appropriate for the locale

        let formattedDuration = formatter.string(from: duration)
        return formattedDuration!
    }
    
    
    
    // MARK: IBActions
    @IBAction func startRunTapped(sender: RoundedView) {
        initiateRun()
        runTimer()
    }
    
    @IBAction func endRunButtonPressed(_ sender: RoundedView) {
        stopLocationUpdates()
        informationView.isHidden = false
        displayRoute()
        timer?.invalidate()
    }
    
    @IBAction func resetMapCenter(_ sender: RoundedView) {
        centerMapOnUserLocation()
    }
    
    @IBAction func segmentControlTapped(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            isMiles = true
            distanceLabel.text = String(format: "%.2f Mi", routeDistance * 0.000621371)
            perMinuteLabel.text = "Mile/Min"
        } else {
            isMiles = false
            distanceLabel.text = String(format: "%.2f Km", routeDistance / 1000)
            perMinuteLabel.text = "Km/Min"
        }
    }
}

//MARK: CLLocation Manager Delegate
extension ViewController: CLLocationManagerDelegate {
    func checkLocationAuthStatus() {
        
        let status = CLLocationManager.authorizationStatus()
        
        if status == .denied || status == .restricted || !CLLocationManager.locationServicesEnabled() {
            openSettingApp(message:NSLocalizedString("Please enable location services to continue using the app", comment: ""))
            return
        }
        
        if status == .notDetermined {
            locationManager.requestAlwaysAuthorization()
            return
        }
        
        locationManager.requestLocation()
        centerMapOnUserLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint("Error getting location: \(error.localizedDescription)")
        
    }
    
    // Open location settings for app
    func openSettingApp(message: String) {
        let alertController = UIAlertController (title: "RouteView", message:message , preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: ""), style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            }
        }
        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else { return }
        
        let region = MKCoordinateRegion.init(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        
        mapView.setRegion(region, animated: true)
        
        if isRunning {
            addLocationsToRouteArray(locations)
        } else {
            locationManager.stopUpdatingLocation()
        }
    }
    
    func centerMapOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: 800, longitudinalMeters: 800)
            mapView.setRegion(region, animated: true)
            mapView.showsUserLocation = true
        }
    }
}

// MARK: Setup MapKit
extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = .systemGreen
        renderer.lineWidth = 5
        renderer.alpha = 0.8
        
        return renderer
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


