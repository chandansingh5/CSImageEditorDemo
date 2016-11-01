//
//  PhotoThumbnail.swift
//  DemoWork
//
//  Created by Chandan Kumar on 01/10/16.
//  Copyright © 2016 Chandan Kumar. All rights reserved.
//

import UIKit

class PhotoThumbnail: UICollectionViewCell {

    @IBOutlet var imgView : UIImageView!
    
    func setThumbnailImage(_ thumbnailImage: UIImage){
        self.imgView.image = thumbnailImage
    }
}
