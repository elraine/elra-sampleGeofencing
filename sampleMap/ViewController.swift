//
//  ViewController.swift
//  sampleMap
//
//  Created by Alexis Chan on 16/11/2017.
//  Copyright © 2017 achan. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreMotion

class ViewController: UIViewController, CLLocationManagerDelegate,MKMapViewDelegate {
    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var currentRegionLabel: UILabel!
    
    let locationManager = CLLocationManager()
    let motionManager = CMMotionActivityManager()
    
    let regionRadius: CLLocationDistance = 1000
    
    var allRegions:[CLCircularRegion] = []
    
    var distanceToAllRegions:[CLLocationDistance] = []{
        didSet{
            distanceLabel.text = String(describing: distanceToAllRegions.min()!.rounded())
        }
        
    }
    var speed:Double = 0{
        didSet{
            resetButton.titleLabel?.text = String(Int(speed))
        }
    }
    var lastLocation:CLLocation = CLLocation()
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func monitorRegionAtLocation() {
        guard CLLocationManager.authorizationStatus() == .authorizedAlways else{
            print("not authorized")
            return
        }
        
        let shortRadius:CLLocationDistance = 500
        let longRadius:CLLocationDistance = 12000
        let regions: [CLCircularRegion] = [
            CLCircularRegion(center: CLLocationCoordinate2D(latitude:46.0404651,longitude:4.7249787), radius: shortRadius, identifier: "Boitray"),
            CLCircularRegion(center: CLLocationCoordinate2D(latitude:46.1354872,longitude:4.765138), radius: shortRadius, identifier: "Taponas"),
            CLCircularRegion(center: CLLocationCoordinate2D(latitude:46.7524567,longitude:2.41487039), radius: shortRadius, identifier: "Farges Allichamps"),
            CLCircularRegion(center: CLLocationCoordinate2D(latitude:46.0585033, longitude:3.11161905), radius: shortRadius, identifier: "Volcan d'Auvergne"),
            CLCircularRegion(center: CLLocationCoordinate2D(latitude:48.6110603, longitude:2.6344658), radius: shortRadius, identifier: "Aire de Galande la Mare-Laroche"),
// 12km regions
            CLCircularRegion(center: CLLocationCoordinate2D(latitude:47.9732621, longitude:3.19782476), radius: longRadius, identifier: "Aire de la Reserve"),
            CLCircularRegion(center: CLLocationCoordinate2D(latitude:48.1666969, longitude:3.17163347), radius: longRadius, identifier: "Aire de Villeroy")
        ]
        allRegions = regions
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            let _ = regions.map( { (region:CLCircularRegion) in
                region.notifyOnEntry = true
                region.notifyOnExit = true
                print("region \(region.identifier) is monitored" )
                locationManager.startMonitoring(for: region)
            })
        }
        
    }
    @IBAction func resetButtonAction(_ sender: UIButton) {
//        locationManager()
        print("hi")
        
    }
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0  // In meters.
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        
    }
    
    func checkMotionAuthorizationStatus(){
        if CMMotionActivityManager.isActivityAvailable() {
            if CMMotionActivityManager.authorizationStatus() == .authorized{
//                is ok
            }else{
                print("Motion is not ok")
            }
        }else{
            print("there no Mx on this device")
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentRegionLabel.text = "outside"
        monitorRegionAtLocation()
        self.view.bringSubview(toFront: resetButton)
        
        let initialLocation = CLLocation(latitude: 21.282778, longitude: -157.829444)
        centerMapOnLocation(location: initialLocation)
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(MKUserTrackingMode.follow, animated: true)
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkLocationAuthorizationStatus()
        checkMotionAuthorizationStatus()
        guard let lll = locationManager.location else{
            return
        }
        motionManager.
        addRadiusCircle(location:lll)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            let identifier = region.identifier
            currentRegionLabel.text = identifier
            print("did enter \(identifier)")
        }
    }
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            let identifier = region.identifier
            currentRegionLabel.text = "outside"
            print("did exit \(identifier)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        
        distanceToAllRegions =  self.allRegions.map(){
            (regi) -> CLLocationDistance in
            return (locations.last?.distance(from: CLLocation(latitude: regi.center.latitude, longitude: regi.center.longitude)))!
        }
        let lastLocation = self.lastLocation
        if let spd = locations.last?.speed{
            if (spd < 0) {
                // A negative value indicates an invalid speed. Try calculate manually.
                guard let currentLocation = locations.last else{
                    return
                }
                
                let t:TimeInterval = currentLocation.timestamp.timeIntervalSince(lastLocation.timestamp)
//                print("time " + String(t))
                if (Double(t) <= 0) {
                    // If there are several location manager work at the same time, an outdated cache location may returns and should be ignored.
                    return;
                }
                
                let distanceFromLast:CLLocationDistance = lastLocation.distance(from: currentLocation)
                if (distanceFromLast < 1
                    || t < 1) {
                    // Optional, dont calculate if two location are too close. This may avoid gets unreasonable value.
                    return;
                }
//                print("distance " + String(distanceFromLast))
                self.speed = Double(distanceFromLast)/(3.6*t)
//                print("speed " + String(self.speed))
                self.lastLocation = currentLocation
            }
        }
        
    }
    
    func addRadiusCircle(location: CLLocation){
        self.mapView.delegate = self
        let circle = MKCircle(center: location.coordinate, radius: 100 as CLLocationDistance)
        self.mapView.add(circle)
    }
    
    private func mapView(mapView: MKMapView!, rendererFor overlay: MKOverlay!) -> MKOverlayRenderer! {
        if overlay is MKCircle {
            let circle = MKCircleRenderer(overlay: overlay)
            circle.strokeColor = UIColor.red
            circle.fillColor = UIColor(red: 255, green: 0, blue: 0, alpha: 0.1)
            circle.lineWidth = 1
            return circle
        } else {
            return nil
        }
    }
    
    func startActivityUpdates(to: OperationQueue, withHandler: CMMotionActivityHandler){
        print()

    }
}

