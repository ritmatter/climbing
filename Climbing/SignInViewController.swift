//
//  SignInViewController.swift
//  Climbing
//
//  Created by Matthew Ritter on 12/24/17.
//  Copyright © 2017 Matthew Ritter. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI
import GoogleSignIn

class SignInViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate {
  //MARK: Properties
  @IBOutlet weak var signInButton: GIDSignInButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
    GIDSignIn.sharedInstance().delegate = self
    GIDSignIn.sharedInstance().uiDelegate = self
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
    print("GIDSignInDelegate sign in...")
    if let error = error {
      print("Handling error...")
      self.handleError(error: error)
      return
    }
    
    guard let authentication = user.authentication else { return }
    let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                   accessToken: authentication.accessToken)
    Auth.auth().signIn(with: credential) { (user, error) in
      if let error = error {
        self.handleError(error: error)
        return
      }
      
      // TODO: Stop overwriting the username on every time the app view loads.
      let ref = Database.database().reference()
      ref.child("users").child(user!.uid).setValue(["email": user!.email])
      self.performSegue(withIdentifier: "GoToMainScreen", sender: self)
    }
  }
  
  func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
    // Perform any operations when the user disconnects from app here.
    // ...
  }
  
  func handleError(error: Error?) {
    print("An error happened")
  }
}
