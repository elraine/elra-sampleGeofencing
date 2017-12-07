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
            guard !distanceToAllRegions.isEmpty else{return}
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
            CLCircularRegion(center: CLLocationCoordinate2D(latitude:44.8399503,longitude:-0.5706387), radius: shortRadius, identifier: "Lieu dit Vin"),
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
        checkLocationAuthorizationStatus()
    }
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            mapView.showsUserLocation = true
        } else {
            showLocationSettingsAlert()
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0  // In meters.
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    func showLocationSettingsAlert() {
        let alertController = UIAlertController(title: "😢",
                                                message: "The location permission was not authorized. Please enable it in Settings to continue.",
                                                preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (alertAction) in
            if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(appSettings)
            }
        }
        alertController.addAction(settingsAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
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
        resetButton.setTitle("get Location", for: .normal)
        checkLocationAuthorizationStatus()
        checkMotionAuthorizationStatus()
        guard let lll = locationManager.location else{
            return
        }
        addRadiusCircle(location:lll)
        monitorRegionAtLocation()
        
        self.view.bringSubview(toFront: resetButton)
        
        let initialLocation = CLLocation(latitude: 21.282778, longitude: -157.829444)
        centerMapOnLocation(location: initialLocation)
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
//        mapView.setUserTrackingMode(MKUserTrackingMode.follow, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
    }
    
    func addRadiusCircle(location: CLLocation){
        //not working
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

