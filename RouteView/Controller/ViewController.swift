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
    
    @IBOutlet weak var shadowView: ShadowView!
    @IBOutlet weak var roundedView: RoundedView!
    @IBOutlet weak var informationView: RoundedView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var startRunButton: UIButton!
    @IBOutlet weak var endRunButton: UIButton!
    @IBOutlet weak var centerOnLocationButton: UIButton!
    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeByDistanceLabel: UILabel!
     @IBOutlet weak var perMinuteLabel: UILabel!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    var routeDistance = 0.0
    var locationsPassed = [CLLocation]()
    let locationManager = CLLocationManager()
    var isRunning = false
    var isMiles = true
    var route: MKPolyline?
    var startTime = Date()
    var endTIme = Date()
    
    fileprivate var timer: Timer?
    var seconds: Int = 0
    
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
    }
        
    func stopLocationUpdates() {
        isRunning = false
        startRunButton.isHidden = false
        endRunButton.isHidden = true
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.stopUpdatingLocation()
        calculateDistance()
        timeLabel.text = seconds.convertTime()
        calculateTimePerDistance()
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
    }
    
    func runTimer() {
         timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(ViewController.updateTimer)), userInfo: nil, repeats: true)
    }

    @objc func updateTimer() {
        seconds += 1
    }
    
    func calculateTimePerDistance() {
        let minutes = seconds / 60
        let miles = routeDistance * 0.000621371
        let pace = Double(minutes) / miles
        if pace > 0.00 {
            timeByDistanceLabel.text = String(format: "%.2f", pace)
        } else {
            timeByDistanceLabel.text = "N/A"
        }
    }

    // MARK: IBActions
    @IBAction func startRunTapped(sender: RoundedView) {
        initiateRun()
        runTimer()
    }
    
    @IBAction func endRunButtonPressed(_ sender: RoundedView) {
        stopLocationUpdates()
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
            perMinuteLabel.text = "Minute Mile"
        } else {
            isMiles = false
            distanceLabel.text = String(format: "%.2f Km", routeDistance / 1000)
            perMinuteLabel.text = "Minute Km"
        }
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        //saves image to photo library
        var image :UIImage?
        let currentLayer = UIApplication.shared.windows.first!.layer
        let currentScale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(currentLayer.frame.size, false, currentScale);
        guard let currentContext = UIGraphicsGetCurrentContext() else {return}
        currentLayer.render(in: currentContext)
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let img = image else { return }
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
        
        let activityVC = UIActivityViewController(activityItems: ["Check out my route!", image as Any], applicationActivities: nil)
        
        activityVC.excludedActivityTypes = [
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.print,
            UIActivity.ActivityType.copyToPasteboard,
            UIActivity.ActivityType.addToReadingList,
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.openInIBooks,
            UIActivity.ActivityType(rawValue: "com.apple.reminders.RemindersEditorExtension"),
            UIActivity.ActivityType(rawValue: "com.apple.mobilenotes.SharingExtension"),
            UIActivity.ActivityType(rawValue: "com.apple.mobileslideshow.StreamShareService")
        ]
        
        activityVC.popoverPresentationController?.sourceView = self.view
        self.present(activityVC, animated: true, completion: nil)
    }
}

//MARK: CLLocation Manager Delegate
extension ViewController: CLLocationManagerDelegate {
    func checkLocationAuthStatus() {
        
        let status = CLLocationManager.authorizationStatus()

        if status == .denied || status == .restricted || !CLLocationManager.locationServicesEnabled() {
            locationAlertMessage()
            return
        }

        if status == .notDetermined {
            locationManager.requestAlwaysAuthorization()
            return
        }
        locationManager.requestLocation()
        centerMapOnUserLocation()
    }
    
    func locationAlertMessage() {
        let alertController = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in privacy settings.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default,
        handler: nil)
        
        
        let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: ""), style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        
        OperationQueue.main.addOperation {
            self.present(alertController, animated: true,
            completion:nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint("Error getting location: \(error.localizedDescription)")
        locationAlertMessage()
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
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: 500, longitudinalMeters: 500)
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
        informationView.isHidden = false
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
