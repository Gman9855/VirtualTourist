//
//  Photo.swift
//  VirtualTourist
//
//  Created by Gershy Lev on 10/3/15.
//  Copyright (c) 2015 Gershy Lev. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(Photo)

class Photo: NSManagedObject {
    
    @NSManaged var title: String
    @NSManaged var fileName: String
    @NSManaged var imagePath: String?
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: NSDictionary, context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // image url
        if let imageURL = dictionary["url_m"] as? String {
            imagePath = imageURL
        }
        
        // unique flickr image id that will be used to store the photo
        fileName = dictionary["id"] as! String
        
    }
    
    var photoImage: UIImage? {
        get {
            return Flickr.Caches.imageCache.imageWithIdentifier(fileName)
        }
        
        set {
            Flickr.Caches.imageCache.storeImage(newValue, withIdentifier: fileName)
        }
    }
}