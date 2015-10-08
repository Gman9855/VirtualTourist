//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by Gershy Lev on 10/8/15.
//  Copyright (c) 2015 Gershy Lev. All rights reserved.
//

import Foundation

extension Flickr {
    
    struct URLs {
        static let BASE_URL = "https://api.flickr.com/services/rest/"
    }
    
    struct API_KEY {
        static let API_KEY = "6bdfa41637f43f737fd10cc59b70515f"
    }
    
    struct METHOD_ARGS {
        static let METHOD_NAME = "flickr.photos.search"
        
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        
        static let BOUNDING_BOX_HALF_WIDTH = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT = 1.0
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
    }
}