//
//  ProfileViewController.swift
//  ExchangeAGram
//
//  Created by Vishal Patel on 03/11/14.
//  Copyright (c) 2014 Vishal Patel. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController, FBLoginViewDelegate {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileNameLabel: UILabel!
    
    //login view for facebook
    @IBOutlet weak var fbLoginView: FBLoginView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //Facebook delegate to self. It allows our login view delegate to send messages to the ProfileViewController.
        self.fbLoginView.delegate = self
        self.fbLoginView.readPermissions = ["public_profile", "publish_actions"]    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //segue to mapview viewController
    @IBAction func mapViewButtonPressed(sender: UIButton) {
        performSegueWithIdentifier("mapSegue", sender: nil)
        
    }

    //Map view controller button
   
    //Facebook loginViewDelagate methods
    func loginViewShowingLoggedInUser(loginView: FBLoginView!) {
        
        self.profileImageView.hidden = false
        self.profileNameLabel.hidden = false
    }
    
    func loginViewFetchedUserInfo(loginView: FBLoginView!, user: FBGraphUser!) {
        
        //get the Facebook information of users on our UIViewControleller image and nameLabel
        
        println("User Profile: \(user)")
        self.profileNameLabel.text = user.name
        
        //get the user's facebook profile image on ouer imageView. Create URL and get the image data as binary and put this onto our ImageView
        
        let userImageURL = "https://graph.facebook.com/\(user.objectID)/picture?type=small"
        let url = NSURL(string: userImageURL)
        let imageData = NSData(contentsOfURL: url!)
        let userImage = UIImage(data: imageData!)
        self.profileImageView.image = userImage
        
        
    }
    
    func loginViewShowingLoggedOutUser(loginView: FBLoginView!) {
        
        self.profileImageView.hidden = true
        self.profileNameLabel.hidden = true
    }
    
    func loginView(loginView: FBLoginView!, handleError error: NSError!) {
        println("Error: \(error.localizedDescription)")
        
        //Create a alertView for users to notify
        let alertViewController = UIAlertController(title: "Login Error", message: "You are not logged in on Facebook, please try again", preferredStyle: UIAlertControllerStyle.Alert)
        alertViewController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertViewController, animated: true, completion: nil)
    }
}
