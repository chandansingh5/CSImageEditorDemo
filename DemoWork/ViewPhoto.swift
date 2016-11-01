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
    var photosAsset: PHFetchResult<PHAsset>!
    var index: Int = 0
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    fileprivate let AdjustmentFormatIdentifier = "com.example.apple"
    @IBOutlet var imgView : UIImageView!
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PHPhotoLibrary.shared().register(self)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.activityIndicator.isHidden = true
        self.updateImage()
        self.view.layoutIfNeeded()
    }

  
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
 
    //MARK: - Photo editing methods.
    fileprivate var isContentEditable: Bool {
        return self.asset?.canPerform(.content) ?? false
    }
    
    fileprivate func applyFilterWithName(_ filterName: String) {
        // Prepare the options to pass when requesting to edit the image.
        let options = PHContentEditingInputRequestOptions()
        options.canHandleAdjustmentData = {adjustmentData->Bool in
            adjustmentData.formatIdentifier == self.AdjustmentFormatIdentifier && adjustmentData.formatVersion == "1.0"
        }
        
        self.asset!.requestContentEditingInput(with: options) {contentEditingInput, info in
            // Create a CIImage from the full image representation.
            let url = contentEditingInput!.fullSizeImageURL!
            let orientation = contentEditingInput!.fullSizeImageOrientation
            var inputImage = CIImage(contentsOf: url, options: nil)!
            inputImage = inputImage.applyingOrientation(orientation)
            
            // Create the filter to apply.
            let filter = CIFilter(name: filterName)!
            filter.setDefaults()
            filter.setValue(inputImage, forKey: kCIInputImageKey)
            
            // Apply the filter.
            let outputImage = filter.outputImage
            
            // Create a PHAdjustmentData object that describes the filter that was applied.
            let adjustmentData = PHAdjustmentData(formatIdentifier: self.AdjustmentFormatIdentifier, formatVersion: "1.0", data: filterName.data(using: String.Encoding.utf8)!)
            
            /*
             Create a PHContentEditingOutput object and write a JPEG representation
             of the filtered object to the renderedContentURL.
             */
            let contentEditingOutput = PHContentEditingOutput(contentEditingInput: contentEditingInput!)
            let jpegData = outputImage?.aapl_jpegRepresentationWithCompressionQuality(0.9)!
            try? jpegData?.write(to: contentEditingOutput.renderedContentURL, options: [.atomic])
            contentEditingOutput.adjustmentData = adjustmentData
            
            // Ask the shared PHPhotoLinrary to perform the changes.
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest(for: self.asset!)
                request.contentEditingOutput = contentEditingOutput
                }, completionHandler: {success, error in
                    if !success {
                    }
            })
        }
    }
    
    fileprivate func toggleFavoriteState() {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest(for: self.asset!)
            request.isFavorite = !self.asset!.isFavorite
            }, completionHandler: {success, error in
                if !success {
                }
        })
    }
    
    fileprivate func revertToOriginal() {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest(for: self.asset!)
            request.revertAssetContentToOriginal()
            }, completionHandler: {success, error in
                if !success {
                }
        })
    }
    
    fileprivate func updateStaticImage() {
        // Prepare the options to pass when fetching the live photo.
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestImage(for: self.asset!, targetSize:self.targetSize, contentMode: .aspectFit, options: options) {result, info in
            // Hide the progress view now the request has completed.
            // Check if the request was successful.
            if result == nil {
                return
            }
            self.activityIndicator.isHidden = true
            self.imgView.image = result
        }
    }
    
    fileprivate var targetSize: CGSize {
        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: self.imgView.bounds.width * scale, height: self.imgView.bounds.height * scale)
        return targetSize
    }
    
    fileprivate func updateImage() {
        self.updateStaticImage()
    }
    
    
    
    //MARK: - PHPhotoLibraryChangeObserver

    
    @IBAction func handleEditButtonItem(_ sender: AnyObject) {
        
        // Use a UIAlertController to display the editing options to the user.
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.modalPresentationStyle = .popover
        alertController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        alertController.popoverPresentationController?.permittedArrowDirections = .up
        // Add an action to dismiss the UIAlertController.
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
     
        // Only allow editing if the PHAsset supports edit operations and it is not a Live Photo.
        if self.isContentEditable {
            // Allow filters to be applied if the PHAsset is an image.
            if self.asset?.mediaType == PHAssetMediaType.image {
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Sepia", comment: ""), style: .default) {action in
                    self.activityIndicator.isHidden = false
                    self.activityIndicator.startAnimating()
                    self.applyFilterWithName("CISepiaTone")
                    })
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Chrome", comment: ""), style: .default) {action in
                    self.activityIndicator.startAnimating()
                    self.applyFilterWithName("CIPhotoEffectChrome")
                    })
            }
            
            // Add actions to revert any edits that have been made to the PHAsset.
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Revert", comment: ""), style: .default) {action in
                self.activityIndicator.startAnimating()
                self.revertToOriginal()
                })
        }
        // Present the UIAlertController.
        self.present(alertController, animated: true, completion: nil)
    }
    

    //@Return to photos
    @IBAction func btnCancel(_ sender : AnyObject) {
        self.navigationController?.popToRootViewController(animated: true) //!!Added Optional Chaining
    }
    
    //@Export photo
    @IBAction func btnExport(_ sender : AnyObject) {
        print("Export")
        let img: UIImage = self.imgView.image!
        //var shareItems:Array = [img, messageStr]
        let shareItems:Array = [img]
        let activityViewController:UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityType.print, UIActivityType.postToWeibo, UIActivityType.copyToPasteboard, UIActivityType.addToReadingList, UIActivityType.postToVimeo]
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    //@Remove photo from Collection
    @IBAction func btnTrash(_ sender : AnyObject) {
        let alert = UIAlertController(title: "Delete Image", message: "Are you sure you want to delete this image?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default,
            handler: {(alertAction)in
                PHPhotoLibrary.shared().performChanges({
                    //Delete Photo
                      let fastEnumeration = NSArray(array: [self.photosAsset[self.index]])
                    if let request = PHAssetCollectionChangeRequest(for: self.assetCollection){
                        request.removeAssets(fastEnumeration)
                    }
                    },
                    completionHandler: {(success, error)in
                        NSLog("\nDeleted Image -> %@", (success ? "Success":"Error!"))
                        alert.dismiss(animated: true, completion: nil)
                        if(success){
                            // Move to the main thread to execute
                            DispatchQueue.main.async(execute: {
                                self.photosAsset = PHAsset.fetchAssets(in: self.assetCollection, options: nil)
                                self.navigationController?.popViewController(animated: true)
                            })
                        }else{
                            print("Error: \(error)")
                        }
                })
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: {(alertAction)in
            //Do not delete photo
            alert.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
}

//MARK: - PHPhotoLibraryChangeObserver
extension ViewPhoto : PHPhotoLibraryChangeObserver{
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Call might come on any background queue. Re-dispatch to the main queue to handle it.
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            // Check if there are changes to the asset we're displaying.
            guard let
                asset = self.asset,
                let changeDetails = changeInstance.changeDetails(for: asset) else {
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
