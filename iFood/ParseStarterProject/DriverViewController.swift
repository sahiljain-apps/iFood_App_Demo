//
//  DriverViewController.swift
//  iFood

import UIKit
import Parse
import MapKit

class DriverViewController: UITableViewController, CLLocationManagerDelegate {

    var usernames = [String()]
    var locations = [CLLocationCoordinate2D()]
    var distances = [CLLocationDistance()]

    var locationManager = CLLocationManager()
    
    var userLat:  CLLocationDegrees = 0.0
    var userLong: CLLocationDegrees = 0.0

    var adding = false

    override func viewDidLoad() {
        super.viewDidLoad()

//        print("Setting up locationManager")

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()

//        print("Called startUpdating")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        print("Updated")

        let location = locations[0].coordinate

        userLat     = location.latitude
        userLong    = location.longitude

        loadNearRequests()
        updateMyLocationInParse()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "logoutDriver" {
            PFUser.logOut()
            navigationController?.setNavigationBarHidden(navigationController?.navigationBarHidden == false, animated: false)
        }
        else if segue.identifier == "showViewRequest" {
            if let destination = segue.destinationViewController as? RequestViewController {
                let row = tableView.indexPathForSelectedRow!.row
                
                destination.requestLocation = locations[row]
                destination.requestUsername = usernames[row]
            }
        }
    }

    func loadNearRequests() {
        let query = PFQuery(className: "RiderRequest")

        query.whereKey("location", nearGeoPoint: PFGeoPoint(latitude: userLat, longitude: userLong), withinKilometers: 50.0)
        query.limit = 10

        query.findObjectsInBackgroundWithBlock({
            (objects, error) -> Void in

            if error == nil {
                self.usernames.removeAll()
                self.locations.removeAll()
                self.distances.removeAll()

                for object in objects! {
                    if object["driverResponded"] == nil {
                        if let username = object["username"] as? String {
                            self.usernames.append(username)
                        }

                        if let location = object["location"] as? PFGeoPoint {
                            let reqLocation = CLLocationCoordinate2DMake(location.latitude, location.longitude)

                            self.locations.append(reqLocation)

                            let requestCLL  = CLLocation(latitude: reqLocation.latitude, longitude: reqLocation.longitude)
                            let driverCLL   = CLLocation(latitude: self.userLat, longitude: self.userLong)

                            self.distances.append(driverCLL.distanceFromLocation(requestCLL))
                        }
                    }
                }

                self.tableView.reloadData()
            }
            else {
                print(error!.localizedDescription)
            }
        })
    }

    func updateMyLocationInParse() {
        var query = PFQuery(className: "DriverLocation")

        if PFUser.currentUser()?.objectId == nil {
            locationManager.stopUpdatingLocation()
            return
        }
        
        query.whereKey("username", equalTo: (PFUser.currentUser()?.username)!)

        query.findObjectsInBackgroundWithBlock {
            (objects, error) -> Void in

            if error != nil {
                print(error?.localizedDescription)
            }
            else {
                if objects?.count == 0 {
                    if !self.adding {
                        // New record
                        print("New Location Record")
                        self.adding = true

                        let driverLoc = PFObject(className: "DriverLocation")
                        driverLoc["username"] = PFUser.currentUser()?.username
                        driverLoc["location"] = PFGeoPoint(latitude: self.userLat, longitude: self.userLong)
                        driverLoc.saveInBackground()
                    }
                }
                else {
                    self.adding = false

                    for object in objects! {
                        query = PFQuery(className: "DriverLocation")

                        query.getObjectInBackgroundWithId(object.objectId!, block: {
                            (object, error) -> Void in

                            if error != nil {
                                print(error!.localizedDescription)
                            }
                            else if let driverLoc = object {
                                print("Updating Location Record")
                                driverLoc["location"] = PFGeoPoint(latitude: self.userLat, longitude: self.userLong)
                                driverLoc.saveInBackground()
                            }
                        })
                    }
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return locations.count
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        cell.textLabel!.text = usernames[indexPath.row] + " " + distanceString(distances[indexPath.row])
        
        return cell
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

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */








    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
