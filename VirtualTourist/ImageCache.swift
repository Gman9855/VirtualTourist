//
//  ImageCache.swift
//  VirtualTourist
//
//  Created by Gershy Lev on 10/6/15.
//  Copyright (c) 2015 Gershy Lev. All rights reserved.
//

import Foundation
import UIKit

class ImageCache {
    
    private var inMemoryCache = NSCache()
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    
    func imageWithIdentifier(identifier: String?) -> UIImage? {
        var newImage: UIImage?
        if identifier != nil || identifier != "" {
            let path = pathForIdentifier(identifier!)
            if let image = inMemoryCache.objectForKey(path) as? UIImage {
                newImage = image
            }
            if let data = NSData(contentsOfFile: path) {
                newImage = UIImage(data: data)
            }
        }
        return newImage
    }
    
    func storeImage(image: UIImage?, withIdentifier identifier: String) {
        let path = pathForIdentifier(identifier)
        if image == nil {
            inMemoryCache.removeObjectForKey(path)
            NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
            return
        }
        
        inMemoryCache.setObject(image!, forKey: path)
        
        let data = UIImagePNGRepresentation(image!)
        data.writeToFile(path, atomically: true)
    }
    
    func deletePhotoCacheFromDocumentsDirectory(photo: Photo) {
        photo.photoImage = nil
        photo.imagePath = nil
        photo.pin = nil
        let path = pathForIdentifier(photo.fileName)
        if let data = NSData(contentsOfFile: path) {
            NSFileManager.defaultManager().delete(UIImage(data: data))
        }
    }
        
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        
        return fullURL.path!
    }
}