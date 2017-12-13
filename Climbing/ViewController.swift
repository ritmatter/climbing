//
//  ViewController.swift
//  Climbing
//
//  Created by Matthew Ritter on 12/3/17.
//  Copyright © 2017 Matthew Ritter. All rights reserved.
//

import UIKit
import CoreMotion
import Firebase
import GoogleSignIn
import FirebaseAuthUI

class ViewController: UIViewController, GIDSignInUIDelegate {
  //MARK: Properties
  @IBOutlet weak var recordButton: UIButton!
  @IBOutlet weak var metersLabel: UILabel!
  @IBOutlet weak var metersReading: UILabel!
  @IBOutlet weak var signInButton: GIDSignInButton!

  lazy var altimeter = CMAltimeter()
  var db: DatabaseReference!
  var delegate: AppDelegate!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    metersLabel.isHidden = true
    metersReading.isHidden = true
      
    GIDSignIn.sharedInstance().uiDelegate = self
    GIDSignIn.sharedInstance().signIn()
    db = Database.database().reference()
    
    delegate = UIApplication.shared.delegate as! AppDelegate
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func startAltimeter() {
    if (!CMAltimeter.isRelativeAltitudeAvailable()) {
      let alert = UIAlertController(title: "Barometer Unavilable", message: "Barometer is not available.", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Dismiss"), style: .`default`, handler: { _ in
        NSLog("Barameter unavailable alert.")
      }))
      self.present(alert, animated: true, completion: nil)
    }

    self.altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main, withHandler: { (altitudeData:CMAltitudeData?, error:Error?) in
      if (error != nil) {
        self.altimeter.stopRelativeAltitudeUpdates()
        let alert = UIAlertController(title: "Altitude Error", message: "Error reading altitude.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Dismiss"), style: .`default`, handler: { _ in
          NSLog("Altitude reading error alert.")
        }))
        self.present(alert, animated: true, completion: nil)
      } else {
        let altitude = altitudeData!.relativeAltitude.floatValue    // Relative altitude in meters
        // Update labels, truncate float to two decimal points
        self.metersReading.text = String(format: "%.02f", altitude)
        
        let user = self.delegate.user!
        print(user.uid)
        print(String(Int(NSDate().timeIntervalSince1970)))
        self.db.child("altitudes")
          .child(user.uid)
          .child(String(Int(NSDate().timeIntervalSince1970)))
          .setValue(altitude)
      }
    })
  }
  
  //MARK: Actions
  @IBAction func changeRecordStatus(_ sender: UIButton) {
    if (recordButton.currentTitle == "RECORD") {
      metersLabel.isHidden = false
      metersReading.isHidden = false
      recordButton.setTitle("STOP", for: UIControlState.normal)
      startAltimeter()
    } else {
      altimeter.stopRelativeAltitudeUpdates()
      metersLabel.isHidden = true
      metersReading.isHidden = true
      recordButton.setTitle("RECORD", for: UIControlState.normal)
    }
  }
}

