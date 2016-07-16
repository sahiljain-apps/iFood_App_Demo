//
//  MapViewController.swift
//  UberAlles
//
//  Created by Julian Nicholls on 18/09/2015.
//  Copyright © 2015 Parse. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class RiderViewController: UIViewController {

    var locationManager = CLLocationManager()

    override func viewDidLoad() {
        print("Rider View Controller")
        
        super.viewDidLoad()

//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest

//        locationManager.requestWhenInUseAuthorization()

//        locationManager.startUpdatingLocation()
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations[0]

        let lat     = location.coordinate.latitude
        let long    = location.coordinate.longitude

        self.setMapCentre(lat, long: long)
    }

    func setMapCentre(lat: Double, long: Double) -> Void {
        let centre = CLLocationCoordinate2DMake(lat, long)

        let dLat:  CLLocationDegrees = 0.01
        let dLong: CLLocationDegrees = 0.01
        let span:  MKCoordinateSpan  = MKCoordinateSpanMake(dLat, dLong)

        let region: MKCoordinateRegion = MKCoordinateRegionMake(centre, span)

//        mapView.setRegion(region, animated: true)
    }




    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
