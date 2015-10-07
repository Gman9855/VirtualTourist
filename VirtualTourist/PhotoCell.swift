//
//  PhotoCell.swift
//  VirtualTourist
//
//  Created by Gershy Lev on 10/5/15.
//  Copyright (c) 2015 Gershy Lev. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    
    var taskToCancelIfCellIsReused: NSURLSessionTask? {
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
}
