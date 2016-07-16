//
//  RiderViewController.swift
//  iFood

import UIKit
import Parse
import MapKit
import CoreLocation

class RiderViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    var locationManager = CLLocationManager()

    var userLat:  CLLocationDegrees = 0.0
    var userLong: CLLocationDegrees = 0.0

    var requestActive = false
    var driverComing  = false

    @IBOutlet weak var map: MKMapView!

    @IBOutlet weak var callButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

//        print("Setting up locationManager")

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

//        print("Called startUpdating")
    }


    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        print("Updated")
        
        let location = locations[0].coordinate

        userLat     = location.latitude
        userLong    = location.longitude

        showDriverDetails()
   }

    func showDriverDetails() {
        if PFUser.currentUser()?.objectId == nil {
            locationManager.stopUpdatingLocation()
            return
        }

        var query = PFQuery(className: "RiderRequest")

        query.whereKey("username", equalTo: (PFUser.currentUser()?.username)!)

        query.findObjectsInBackgroundWithBlock {
            (objects, error) -> Void in

            if error != nil {
                print(error?.localizedDescription)
            }
            else {
//                print("RiderRequest Found")

                let request = objects![0]
                let driverName = request["driverResponded"]

                if driverName != nil {
                    self.driverComing = true
                    query = PFQuery(className: "DriverLocation")

                    query.whereKey("username", equalTo: driverName)

                    query.getFirstObjectInBackgroundWithBlock({
                        (dlRecord, error) -> Void in

                        if error != nil {
                            print(error!.localizedDescription)
                        }
                        else {
                            let driverLoc   = dlRecord!["location"] as! PFGeoPoint
                            let driverCLL   = CLLocation(latitude: driverLoc.latitude, longitude: driverLoc.longitude)
                            let riderCLL    = CLLocation(latitude: self.userLat, longitude: self.userLong)
                            let distance    = driverCLL.distanceFromLocation(riderCLL)
                            
//                            print("Driver Location: \(driverLoc), (\(self.distanceString(distance)))")

                            self.callButton.setTitle((driverName as! String) + " is coming\n(\(self.distanceString(distance)) away)", forState: .Normal)

                            let latDelta    = abs(driverLoc.latitude - self.userLat) * 2 + 0.01
                            let longDelta   = abs(driverLoc.longitude - self.userLong) * 2 + 0.01

                            self.setMapCentre(self.userLat, long: self.userLong, size: max(latDelta, longDelta))
                            self.map.removeAnnotations(self.map.annotations)
                            self.addPin(self.userLat, long: self.userLong, text: "Your Location")
                            self.addPin(driverLoc.latitude, long: driverLoc.longitude, text: "\(driverName) Location")
                        }
                    })
                }
            }
        }

        if !driverComing {
            self.setMapCentre(userLat, long: userLong)
            map.removeAnnotations(map.annotations)
            addPin(userLat, long: userLong, text: "Your Location")
        }
    }

    func setMapCentre(lat: Double, long: Double, size: Double = 0.01) {
        let centre = CLLocationCoordinate2DMake(lat, long)

        let dLat:  CLLocationDegrees = size
        let dLong: CLLocationDegrees = size
        let span:  MKCoordinateSpan  = MKCoordinateSpanMake(dLat, dLong)

        let region: MKCoordinateRegion = MKCoordinateRegionMake(centre, span)

        map.setRegion(region, animated: true)
    }

    func addPin(lat: Double, long: Double, text: String) {
        let position = CLLocationCoordinate2DMake(lat, long)

        let pin = MKPointAnnotation()
        pin.coordinate = position
        pin.title = text
        map.addAnnotation(pin)
    }

    func distanceString(valueInM: Double) -> String {
        if valueInM > 20000.0 {     // 20Km
            return String(round(valueInM / 1000.0)) + "Km"
        }
        else if valueInM > 600.0 {  // 0.6Km
            return String(round(valueInM / 100.0) / 10.0) + "Km"
        }

        return String(round(valueInM)) + "m"
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "logoutRider" {
            PFUser.logOut()
        }
    }

    @IBAction func callPressed(sender: AnyObject) {
        if requestActive {
            let query = PFQuery(className: "RiderRequest")

            query.whereKey("username", equalTo: PFUser.currentUser()!.username!)

            query.findObjectsInBackgroundWithBlock({
                (objects, error) -> Void in

                if error == nil {
                    for object in objects! {
                        object.deleteInBackground()
                    }
                }
                else {
                    print(error!.localizedDescription)
                }
            })

            callButton.setTitle("Request a Homemade Cook", forState: .Normal)
            requestActive = false
        }
        else {
            let request = PFObject(className: "RiderRequest")
            request["username"] = PFUser.currentUser()!.username
            request["location"] = PFGeoPoint(latitude: userLat, longitude: userLong)

            request.saveInBackgroundWithBlock {
                (success: Bool, error: NSError?) -> Void in

                if success {
                    self.callButton.setTitle("Cancel Cook Request", forState: .Normal)
                    self.requestActive = true
                } else {
                    let errorMessage = error?.localizedDescription

                    let alert = UIAlertController(title: "Could not call Cook", message: errorMessage! + "\nPlease try again", preferredStyle: .Alert)

                    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: {
                        (action) -> Void in

                        self.dismissViewControllerAnimated(true, completion: nil)
                    }))

                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
    }





    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
