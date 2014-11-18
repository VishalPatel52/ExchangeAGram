//
//  FeedViewController.swift
//  ExchangeAGram
//
//  Created by Vishal Patel on 29/10/14.
//  Copyright (c) 2014 Vishal Patel. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreData
import MapKit

class FeedViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    
    
    //manually request fetchResultsController and CoreData
    var feedArray:[AnyObject] = []
    
    //Location manager property
    var locationManager :CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 100.0
        locationManager.startUpdatingLocation()

    }

    override func viewDidAppear(animated: Bool) {
        
        let request = NSFetchRequest(entityName: "FeedItem")
        let appDelegate = ((UIApplication.sharedApplication().delegate as AppDelegate))
        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
        feedArray = context.executeFetchRequest(request, error: nil)!
        self.collectionView.reloadData()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func profileButtonPressed(sender: UIBarButtonItem) {
        
        self.performSegueWithIdentifier("profileSegue", sender: nil)
    }
    
    //cameraController, UIImagePickerController to access the media files (image, video) from our device
    @IBAction func snapBarButtonItemPressed(sender: UIBarButtonItem) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            var cameraController: UIImagePickerController = UIImagePickerController()
            cameraController.delegate = self //conform to imagepickerDelegate and UINavigationControllerDelegate
            cameraController.sourceType = UIImagePickerControllerSourceType.Camera
            
            let mediaType:[AnyObject] = [kUTTypeImage]
            cameraController.mediaTypes = mediaType
            cameraController.allowsEditing = false
            self.presentViewController(cameraController, animated: true, completion: nil)
            
        }
        
        else if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary){
            
            var photoLibraryController = UIImagePickerController()
            photoLibraryController.delegate = self
            photoLibraryController.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            
            let mediaType:[AnyObject] = [kUTTypeImage]
            photoLibraryController.mediaTypes = mediaType
            photoLibraryController.allowsEditing = false
            self.presentViewController(photoLibraryController, animated: true, completion: nil)
            
        }
        else {
            var alertController = UIAlertController(title: "Alert", message: "your device does not support camera and Photo Library!", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }

    //UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        
        let image:UIImage = info[UIImagePickerControllerOriginalImage] as UIImage
        
        //convert image instance in to JPEG image instance to store
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        let thumbNailData = UIImageJPEGRepresentation(image, 0.1)
        
        //save image in CoreData
        let managedObjectContext = ((UIApplication.sharedApplication().delegate) as AppDelegate).managedObjectContext
        let entityDescription = NSEntityDescription.entityForName("FeedItem", inManagedObjectContext: managedObjectContext!)
        let feedItem = FeedItem(entity: entityDescription!, insertIntoManagedObjectContext: managedObjectContext!)
        feedItem.image = imageData
        feedItem.caption = "Test Caption!"
        feedItem.thumbNail = thumbNailData
        
        //Store logitude and latitude in CoreData
        feedItem.latitude = locationManager.location.coordinate.latitude
        feedItem.longitude = locationManager.location.coordinate.longitude
        
        
        //Add uuid and store to DataModel
        let UUID = NSUUID().UUIDString
        feedItem.uniqueID = UUID
        
        feedItem.filtered = false
        
        (UIApplication.sharedApplication().delegate as AppDelegate).saveContext()
        
        feedArray.append(feedItem)
        self.dismissViewControllerAnimated(true, completion: nil)
        collectionView.reloadData()
    }
    
    //UICollectionViewDelegate
    //transition to FilterViewController via segua
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let thisItem = feedArray[indexPath.row] as FeedItem
        
        
        //Initialize a viewController in Code 
        var filterVC = FilterViewController()
        filterVC.thisFeedItem = thisItem
        
        //Push filterViewController
        self.navigationController?.pushViewController(filterVC, animated: false)
    }
    
    
    //UICollectionView DataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return feedArray.count
    }
    
    //this method is required for UICollectionView DataSource
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var cell:FeedCell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as FeedCell
        let thisItem = feedArray[indexPath.row] as FeedItem
        if thisItem.filtered == true {
            
            let returnedImage =  UIImage(data: thisItem.image)!
            let image = UIImage(CGImage: returnedImage.CGImage, scale: 1.0, orientation: UIImageOrientation.Right)!
        }
        else {
            cell.imageView.image = UIImage(data: thisItem.image) //cause FeedItem image is a form of NSdata, binary image
        }
        
        cell.captionLabel.text = thisItem.caption
        return cell
        
    }
    
    //CLLocationManager Delegate
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        
        println("Locations : \(locations)")
        println("Location will be determined")

    }
    
    
}
