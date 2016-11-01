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
    let eaglContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
    return CIContext(EAGLContext: eaglContext)
}()

extension CIImage {
    
    func aapl_jpegRepresentationWithCompressionQuality(compressionQuality: CGFloat) -> NSData? {
        let outputImageRef = ciContext.createCGImage(self, fromRect: self.extent)
        let uiImage = UIImage(CGImage: outputImageRef, scale: 1.0, orientation: .Up)
        let jpegRepresentation = UIImageJPEGRepresentation(uiImage, compressionQuality)
        return jpegRepresentation
    }
    
}