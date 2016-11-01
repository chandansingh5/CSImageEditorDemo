//
//  DemoViewcontroller.swift
//  Photos Gallery App
//
//  Created by Chandan Kumar on 01/10/16.
//  Copyright © 2016 Abbouds Corner. All rights reserved.
//

import UIKit
import Photos

class DemoViewcontroller: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "App Folder1")
        _ = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
    }
    
    override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
        }
        
}
