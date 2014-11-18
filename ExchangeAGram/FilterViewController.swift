//
//  FilterViewController.swift
//  ExchangeAGram
//
//  Created by Vishal Patel on 29/10/14.
//  Copyright (c) 2014 Vishal Patel. All rights reserved.
//

import UIKit

class FilterViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    let kIntensity = 0.7
    
    var context: CIContext = CIContext(options: nil)
    
    var filters:[CIFilter] = []
    
    var thisFeedItem: FeedItem!
    
    var collectionView: UICollectionView!
    
    let placeHolderImage = UIImage(named: "Placeholder")
    
    //create temporary directoy for cache and will remove automatically
    let temp = NSTemporaryDirectory()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 100.0, height: 100.0)
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.whiteColor()
        
        collectionView.registerClass(FilterCell.self, forCellWithReuseIdentifier: "MyCell")
        self.view.addSubview(collectionView)
        
        
        //load all filters
        filters = photoFilters()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    
    //UICollectionViewDataSource required methods
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell:FilterCell = collectionView.dequeueReusableCellWithReuseIdentifier("MyCell", forIndexPath: indexPath) as FilterCell
        
        
        cell.imageView.image = placeHolderImage
        
        let filterQueue:dispatch_queue_t = dispatch_queue_create("filter queue", nil)
        
        dispatch_async(filterQueue, { () -> Void in
            let filterImage = self.getCachedImage(indexPath.row)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                cell.imageView.image = filterImage
                //cell.imageView.contentMode = UIViewContentMode.ScaleToFill
            })
        })
        
        
        return cell
    }
    
    
    //UIColletionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        self.createUIAlterController(indexPath)
        
        
    }
    
    
    //Helper function
    
    
    func photoFilters() -> [CIFilter] {
        
        
        //some iOS filters
        let blur = CIFilter(name: "CIGaussianBlur")
        let instant = CIFilter(name: "CIPhotoEffectInstant")
        let noir = CIFilter(name: "CIPhotoEffectNoir")
        let transfer = CIFilter(name: "CIPhotoEffectTransfer")
        let unsharpen = CIFilter(name: "CIUnsharpMask")
        let monochrome = CIFilter(name: "CIColorMonochrome")
        
        //QR-Code
        let qrCode = CIFilter(name: "CIColorInvert")
        
        let colorControls = CIFilter(name: "CIColorControls")
        colorControls.setValue(0.5, forKey: kCIInputSaturationKey)
        
        let sepia = CIFilter(name: "CISepiaTone")
        sepia.setValue(kIntensity, forKey: kCIInputIntensityKey)
        
        let colorClamp = CIFilter(name: "CIColorClamp")
        colorClamp.setValue(CIVector(x: 0.9, y: 0.9, z: 0.9, w: 0.9), forKey: "inputMaxComponents")
        
        colorClamp.setValue(CIVector(x: 0.2, y: 0.2, z: 0.2, w: 0.2), forKey: "inputMinComponents")
        
        
        let composite = CIFilter(name: "CIHardLightBlendMode")
        composite.setValue(sepia.outputImage, forKey: kCIInputImageKey)
        
        let vignette = CIFilter(name: "CIVignette")
        vignette.setValue(composite.outputImage, forKey: kCIInputImageKey)
        
        vignette.setValue(kIntensity * 2, forKey: kCIInputIntensityKey)
        vignette.setValue(kIntensity * 30, forKey: kCIInputRadiusKey)
        
        return [blur, instant, noir, transfer, unsharpen, monochrome, colorControls, sepia, colorClamp, composite, vignette, qrCode]
    }
    
    
    func filteredImageFromImage (imageData : NSData, filter: CIFilter) -> UIImage {
        
        let unfilteredImage = CIImage(data: imageData)
        filter.setValue(unfilteredImage, forKey: kCIInputImageKey)
        
        let filteredImage: CIImage = filter.outputImage
        
        let extent = filteredImage.extent()
        let cgImage:CGImageRef = context.createCGImage(filteredImage, fromRect: extent)
        
        let finalImage = UIImage(CGImage: cgImage)
        
        return finalImage!
        
    }
    
    //UIAlertController Helper
    
    func createUIAlterController (indexPath: NSIndexPath) {
        let alert = UIAlertController(title: "Photo Options", message: "please choose an options", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Add Caption!"
            textField.secureTextEntry = false
        }
        
        
        var text:String
        let textField = alert.textFields![0] as UITextField
        
        if textField.text != nil {
            text = textField.text
        }
        
        //actions for alertViewController
        
        let photoAction = UIAlertAction(title: "Post on Facebook", style: UIAlertActionStyle.Destructive) { (UIAlertAction) -> Void in
            self.shareOnFacebook(indexPath)
            var text : String = textField.text
            self.saveFiltersToCoreData(indexPath, caption: text)
        }
        alert.addAction(photoAction)
        
        let saveFilterAction = UIAlertAction(title: "Save without posting on Facebook", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            var text : String = textField.text
            self.saveFiltersToCoreData(indexPath, caption: text)
        }
        alert.addAction(saveFilterAction)
        
        let cancelAction = UIAlertAction(title: "Select another photo", style: UIAlertActionStyle.Cancel) { (UIAlertAction) -> Void in
            
        }
        alert.addAction(cancelAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //save filters to CoreData
    
    func saveFiltersToCoreData (indexPath: NSIndexPath, caption: String) {
        let filterImage = self.filteredImageFromImage(self.thisFeedItem.image, filter: self.filters[indexPath.row])
        let imageData = UIImageJPEGRepresentation(filterImage, 1.0)
        self.thisFeedItem.image = imageData
        let thumbNailData = UIImageJPEGRepresentation(filterImage, 0.1)
        self.thisFeedItem.thumbNail = thumbNailData
        self.thisFeedItem.caption = caption
        self.thisFeedItem.filtered = true
        
        ((UIApplication.sharedApplication().delegate as AppDelegate).saveContext())
        self.navigationController?.popViewControllerAnimated(true)

    }
    
    //Share a photo on Facebook
    func shareOnFacebook (indexpath: NSIndexPath) {
        let filterImage = self.filteredImageFromImage(self.thisFeedItem.image, filter: self.filters[indexpath.row])
        
        let photos: NSArray = [filterImage]
        var params = FBPhotoParams()
        params.photos = photos
        
        FBDialogs.presentShareDialogWithPhotoParams(params, clientState: nil) { (call, result, error) -> Void in
            
            if result != nil {
                println(result)
            }
            else {
                println(error)
            }
        }
        
    }
    
    //caching functions
    
    func cacheImage(imageNumber: Int) {
        let fileName = "\(thisFeedItem.uniqueID)\(imageNumber)"
        let uniquePath = temp.stringByAppendingPathComponent(fileName)
        
        if !NSFileManager.defaultManager().fileExistsAtPath(fileName){
            let data = self.thisFeedItem.thumbNail
            let filter = self.filters[imageNumber]
            let image = self.filteredImageFromImage(data, filter: filter)
            
            UIImageJPEGRepresentation(image, 1.0).writeToFile(uniquePath, atomically: true)
        }
    }
    
    
    func getCachedImage(imageNumber: Int) -> UIImage {
        
        let fileName = "\(thisFeedItem.uniqueID)\(imageNumber)"
        let uniquePath = temp.stringByAppendingPathComponent(fileName)
        
        var image:UIImage
        
        if NSFileManager.defaultManager().fileExistsAtPath(uniquePath){
            
            var returnedImage = UIImage(contentsOfFile: uniquePath)!
            image = UIImage(CGImage: returnedImage.CGImage, scale: 1.0, orientation: UIImageOrientation.Right)!
            
        }
        else {
            
            self.cacheImage(imageNumber)
            var returnedImage = UIImage(contentsOfFile: uniquePath)!
            image = UIImage(CGImage: returnedImage.CGImage, scale: 1.0, orientation: UIImageOrientation.Right)!

        }
        
        return image
    }
    
    
    
    
    
    
    
    
}
