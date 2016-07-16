/**
* Copyright (c) Sahil Jain

 
 */

import UIKit
import Parse

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!

    @IBOutlet weak var riderLabel: UILabel!
    @IBOutlet weak var driverLabel: UILabel!
    @IBOutlet weak var driverSwitch: UISwitch!

    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!


    var signupMode = true
    var indicator  = UIActivityIndicatorView()


    override func viewDidLoad() {
        super.viewDidLoad()

        self.username.delegate = self
        self.password.delegate = self
    }


    @IBAction func leftPressed(sender: AnyObject) {
        if username.text != "" && password.text != "" {
            showActivityIndicator()

            var errorMessage = "Please try again later"

            if signupMode {
                let user = PFUser()

                user.username = username.text
                user.password = password.text
                user["driver"] = driverSwitch.on

                user.signUpInBackgroundWithBlock({
                    (success, error) -> Void in

                    self.endActivity()

                    if success {
//                        print("Successfully signed up")
                        if user["driver"] as! Bool {
                            self.performSegueWithIdentifier("loginDriver", sender: self)
                        }
                        else {
                            self.performSegueWithIdentifier("loginRider", sender: self)
                        }
                    }
                    else {
                        if let errorString = error!.userInfo["error"] as? String {
                            errorMessage = errorString
                        }

                        self.showAlert("Error signing up", message: errorMessage)
                    }
                })
            }
            else {
                PFUser.logInWithUsernameInBackground(username.text!, password: password.text!, block: {
                    (user, error) -> Void in

                    self.endActivity()

                    if let user = user {
//                        print("Successfully logged in")

                        if user["driver"] as! Bool {
                            self.performSegueWithIdentifier("loginDriver", sender: self)
                        }
                        else {
                            self.performSegueWithIdentifier("loginRider", sender: self)
                        }
                    }
                    else {
                        if let errorString = error!.userInfo["error"] as? String {
                            errorMessage = errorString
                        }

                        self.showAlert("Error logging in", message: errorMessage)
                    }
                })
            }

        }
        else {
           showAlert("Error in Form", message: "You must enter both a username and password.")
        }
    }


    @IBAction func rightPressed(sender: AnyObject) {
        if signupMode {     // Swap to log in
            leftButton.setTitle("Log In", forState: .Normal)
            rightButton.setTitle("New User?", forState: .Normal)

            riderLabel.hidden = true
            driverLabel.hidden = true
            driverSwitch.hidden = true

            signupMode = false
        }
        else {
            leftButton.setTitle("Sign Up", forState: .Normal)
            rightButton.setTitle("Existing User?", forState: .Normal)

            riderLabel.hidden = false
            driverLabel.hidden = false
            driverSwitch.hidden = false

            signupMode = true
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: {
            (action) -> Void in

            self.dismissViewControllerAnimated(true, completion: nil)
        }))

        self.presentViewController(alert, animated: true, completion: nil)
    }

    func showActivityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 50, 50))

        indicator.center = self.view.center
        indicator.hidesWhenStopped = true
        indicator.activityIndicatorViewStyle = .Gray

        self.view.addSubview(indicator)

        indicator.startAnimating()

        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    }

    func endActivity() {
        self.indicator.stopAnimating()
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
    }

    // The following two functions take care of clicking outside of and pressing return on
    // the keyboard to dismiss it.

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)  // Close the keyboard
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return true
    }

    // Segue to Rider controller if logged in at entry

    override func viewDidAppear(animated: Bool) {
        if PFUser.currentUser()?.objectId != nil {
            if PFUser.currentUser()!["driver"] as! Bool {
                self.performSegueWithIdentifier("loginDriver", sender: self)
            }
            else {
                self.performSegueWithIdentifier("loginRider", sender: self)
            }
        }
    }



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
