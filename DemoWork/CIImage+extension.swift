//
//  CIImage+extension.swift
//  DemoWork
//
//  Created by Chandan Kumar on 01/10/16.
//  Copyright © 2016 Chandan Kumar. All rights reserved.
//

import CoreImage
import UIKit

private let ciContext: CIContext = {
    let eaglContext = EAGLContext(api: EAGLRenderingAPI.openGLES2)
    return CIContext(eaglContext: eaglContext!)
}()

extension CIImage {
    
    func aapl_jpegRepresentationWithCompressionQuality(_ compressionQuality: CGFloat) -> Data? {
        let outputImageRef = ciContext.createCGImage(self, from: self.extent)
        let uiImage = UIImage(cgImage: outputImageRef!, scale: 1.0, orientation: .up)
        let jpegRepresentation = UIImageJPEGRepresentation(uiImage, compressionQuality)
        return jpegRepresentation
    }
    
}
