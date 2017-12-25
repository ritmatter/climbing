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

class ViewController: UIViewController {
  //MARK: Properties
  @IBOutlet weak var recordButton: UIButton!
  @IBOutlet weak var metersLabel: UILabel!
  @IBOutlet weak var metersReading: UILabel!
  lazy var altimeter = CMAltimeter()
  lazy var sessionId = ""

  override func viewDidLoad() {
    super.viewDidLoad()

    metersLabel.isHidden = false
    metersReading.isHidden = false
    
    if (!CMAltimeter.isRelativeAltitudeAvailable()) {
      let alert = UIAlertController(title: "Barometer Unavilable", message: "Barometer is not available.", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Dismiss"), style: .`default`, handler: { _ in
        NSLog("Barameter unavailable alert.")
      }))
    }
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
      return
    }

    // Start a new session.
    self.sessionId = UUID().uuidString
    let serverTimeStamp = ServerValue.timestamp() as! [String:Any]
    Database.database().reference()
      .child("sessions")
      .child(Auth.auth().currentUser!.uid)
      .child(self.sessionId)
      .setValue([
        "start_time": serverTimeStamp
        ])
    
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
        
        let serverTimeStamp = ServerValue.timestamp() as! [String:Any]
        Database.database().reference()
          .child("telemetry")
          .child(Auth.auth().currentUser!.uid)
          .child(UUID().uuidString)
          .setValue([
            "session": self.sessionId,
            "altitude": altitude,
            "timestamp": serverTimeStamp
            ])
      }
    })
  }
  
  func stopSession() {
    altimeter.stopRelativeAltitudeUpdates()
    
    let serverTimeStamp = ServerValue.timestamp() as! [String:Any]
    Database.database().reference()
      .child("sessions")
      .child(Auth.auth().currentUser!.uid)
      .child(self.sessionId)
      .updateChildValues(["end_time": serverTimeStamp])
    self.sessionId = ""
  }

  //MARK: Actions
  @IBAction func changeRecordStatus(_ sender: UIButton) {
    if (recordButton.currentTitle == "RECORD") {
      metersLabel.isHidden = false
      metersReading.isHidden = false
      recordButton.setTitle("STOP", for: UIControlState.normal)
      startAltimeter()
    } else {
      stopSession()
      metersLabel.isHidden = true
      metersReading.isHidden = true
      recordButton.setTitle("RECORD", for: UIControlState.normal)
    }
  }
}

