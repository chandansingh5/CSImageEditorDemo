//
//  ViewPhoto.swift
//  DemoWork
//
//  Created by Chandan Kumar on 01/10/16.
//  Copyright © 2016 Chandan Kumar. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class ViewPhoto: UIViewController  {
    
    @IBOutlet weak var editButton: UINavigationItem!
    var asset: PHAsset?
    var assetCollection: PHAssetCollection!
    var photosAsset: PHFetchResult!
    var index: Int = 0
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    private let AdjustmentFormatIdentifier = "com.example.apple"
    @IBOutlet var imgView : UIImageView!
    
    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.activityIndicator.hidden = true
        self.updateImage()
        self.view.layoutIfNeeded()
    }

  
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
 
    //MARK: - Photo editing methods.
    private var isContentEditable: Bool {
        return self.asset?.canPerformEditOperation(.Content) ?? false
    }
    
    private func applyFilterWithName(filterName: String) {
        // Prepare the options to pass when requesting to edit the image.
        let options = PHContentEditingInputRequestOptions()
        options.canHandleAdjustmentData = {adjustmentData->Bool in
            adjustmentData.formatIdentifier == self.AdjustmentFormatIdentifier && adjustmentData.formatVersion == "1.0"
        }
        
        self.asset!.requestContentEditingInputWithOptions(options) {contentEditingInput, info in
            // Create a CIImage from the full image representation.
            let url = contentEditingInput!.fullSizeImageURL!
            let orientation = contentEditingInput!.fullSizeImageOrientation
            var inputImage = CIImage(contentsOfURL: url, options: nil)!
            inputImage = inputImage.imageByApplyingOrientation(orientation)
            
            // Create the filter to apply.
            let filter = CIFilter(name: filterName)!
            filter.setDefaults()
            filter.setValue(inputImage, forKey: kCIInputImageKey)
            
            // Apply the filter.
            let outputImage = filter.outputImage
            
            // Create a PHAdjustmentData object that describes the filter that was applied.
            let adjustmentData = PHAdjustmentData(formatIdentifier: self.AdjustmentFormatIdentifier, formatVersion: "1.0", data: filterName.dataUsingEncoding(NSUTF8StringEncoding)!)
            
            /*
             Create a PHContentEditingOutput object and write a JPEG representation
             of the filtered object to the renderedContentURL.
             */
            let contentEditingOutput = PHContentEditingOutput(contentEditingInput: contentEditingInput!)
            let jpegData = outputImage?.aapl_jpegRepresentationWithCompressionQuality(0.9)!
            jpegData?.writeToURL(contentEditingOutput.renderedContentURL, atomically: true)
            contentEditingOutput.adjustmentData = adjustmentData
            
            // Ask the shared PHPhotoLinrary to perform the changes.
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                let request = PHAssetChangeRequest(forAsset: self.asset!)
                request.contentEditingOutput = contentEditingOutput
                }, completionHandler: {success, error in
                    if !success {
                        NSLog("Error: %@", error!)
                    }
            })
        }
    }
    
    private func toggleFavoriteState() {
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            let request = PHAssetChangeRequest(forAsset: self.asset!)
            request.favorite = !self.asset!.favorite
            }, completionHandler: {success, error in
                if !success {
                    NSLog("Error: %@", error!)
                }
        })
    }
    
    private func revertToOriginal() {
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            let request = PHAssetChangeRequest(forAsset: self.asset!)
            request.revertAssetContentToOriginal()
            }, completionHandler: {success, error in
                if !success {
                    NSLog("Error: %@", error!)
                }
        })
    }
    
    private func updateStaticImage() {
        // Prepare the options to pass when fetching the live photo.
        let options = PHImageRequestOptions()
        options.deliveryMode = .HighQualityFormat
        options.networkAccessAllowed = true
        PHImageManager.defaultManager().requestImageForAsset(self.asset!, targetSize:self.targetSize, contentMode: .AspectFit, options: options) {result, info in
            // Hide the progress view now the request has completed.
            // Check if the request was successful.
            if result == nil {
                return
            }
            self.activityIndicator.hidden = true
            self.imgView.image = result
        }
    }
    
    private var targetSize: CGSize {
        let scale = UIScreen.mainScreen().scale
        let targetSize = CGSizeMake(CGRectGetWidth(self.imgView.bounds) * scale, CGRectGetHeight(self.imgView.bounds) * scale)
        return targetSize
    }
    
    private func updateImage() {
        self.updateStaticImage()
    }
    
    
    
    //MARK: - PHPhotoLibraryChangeObserver

    
    @IBAction func handleEditButtonItem(sender: AnyObject) {
        
        // Use a UIAlertController to display the editing options to the user.
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        alertController.modalPresentationStyle = .Popover
        alertController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        alertController.popoverPresentationController?.permittedArrowDirections = .Up
        // Add an action to dismiss the UIAlertController.
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: nil))
     
        // Only allow editing if the PHAsset supports edit operations and it is not a Live Photo.
        if self.isContentEditable {
            // Allow filters to be applied if the PHAsset is an image.
            if self.asset?.mediaType == PHAssetMediaType.Image {
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Sepia", comment: ""), style: .Default) {action in
                    self.activityIndicator.hidden = false
                    self.activityIndicator.startAnimating()
                    self.applyFilterWithName("CISepiaTone")
                    })
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Chrome", comment: ""), style: .Default) {action in
                    self.activityIndicator.startAnimating()
                    self.applyFilterWithName("CIPhotoEffectChrome")
                    })
            }
            
            // Add actions to revert any edits that have been made to the PHAsset.
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Revert", comment: ""), style: .Default) {action in
                self.activityIndicator.startAnimating()
                self.revertToOriginal()
                })
        }
        // Present the UIAlertController.
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    

    //@Return to photos
    @IBAction func btnCancel(sender : AnyObject) {
        self.navigationController?.popToRootViewControllerAnimated(true) //!!Added Optional Chaining
    }
    
    //@Export photo
    @IBAction func btnExport(sender : AnyObject) {
        print("Export")
        let img: UIImage = self.imgView.image!
        //var shareItems:Array = [img, messageStr]
        let shareItems:Array = [img]
        let activityViewController:UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypePostToWeibo, UIActivityTypeCopyToPasteboard, UIActivityTypeAddToReadingList, UIActivityTypePostToVimeo]
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    //@Remove photo from Collection
    @IBAction func btnTrash(sender : AnyObject) {
        let alert = UIAlertController(title: "Delete Image", message: "Are you sure you want to delete this image?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .Default,
            handler: {(alertAction)in
                PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                    //Delete Photo
                    if let request = PHAssetCollectionChangeRequest(forAssetCollection: self.assetCollection){
                        request.removeAssets([self.photosAsset[self.index]])
                    }
                    },
                    completionHandler: {(success, error)in
                        NSLog("\nDeleted Image -> %@", (success ? "Success":"Error!"))
                        alert.dismissViewControllerAnimated(true, completion: nil)
                        if(success){
                            // Move to the main thread to execute
                            dispatch_async(dispatch_get_main_queue(), {
                                self.photosAsset = PHAsset.fetchAssetsInAssetCollection(self.assetCollection, options: nil)
                                self.navigationController?.popViewControllerAnimated(true)
                            })
                        }else{
                            print("Error: \(error)")
                        }
                })
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .Cancel, handler: {(alertAction)in
            //Do not delete photo
            alert.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

//MARK: - PHPhotoLibraryChangeObserver
extension ViewPhoto : PHPhotoLibraryChangeObserver{
    func photoLibraryDidChange(changeInstance: PHChange) {
        // Call might come on any background queue. Re-dispatch to the main queue to handle it.
        dispatch_async(dispatch_get_main_queue()) {
            self.activityIndicator.stopAnimating()
            // Check if there are changes to the asset we're displaying.
            guard let
                asset = self.asset,
                changeDetails = changeInstance.changeDetailsForObject(asset) else {
                    return
            }
            
            // Get the updated asset.
            self.asset = changeDetails.objectAfterChanges as? PHAsset
            
            // If the asset's content changed, update the image and stop any video playback.
            if changeDetails.assetContentChanged {
                self.updateImage()
            }
        }
    }
}
