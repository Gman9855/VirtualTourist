//
//  Flickr.swift
//  VirtualTourist
//
//  Created by Gershy Lev on 10/4/15.
//  Copyright (c) 2015 Gershy Lev. All rights reserved.
//

import UIKit

class Flickr {
    
    let METHOD_NAME = "flickr.photos.search"
    let BASE_URL = "https://api.flickr.com/services/rest/"
    let API_KEY = "672d6269dad2b175f45cd863bacb5053"
    
    // Method arguments for photo search
    let EXTRAS = "url_m"
    let SAFE_SEARCH = "1"
    let DATA_FORMAT = "json"
    let NO_JSON_CALLBACK = "1"
    
    // Constants for the bbox
    let BOUNDING_BOX_HALF_WIDTH = 1.0
    let BOUNDING_BOX_HALF_HEIGHT = 1.0
    let LAT_MIN = -90.0
    let LAT_MAX = 90.0
    let LON_MIN = -180.0
    let LON_MAX = 180.0
    
    var latitude: Double
    var longitude: Double
    var session: NSURLSession
    var resultsPerPage: Int
    let ACCURACY: Int
    var page: Int
    var upperPageLimit: Int
    
    init(lat: Double, lon: Double) {
        session = NSURLSession.sharedSession()
        
        // For bbox pull
        latitude = lat
        longitude = lon
        
        // For street level detail
        ACCURACY = 16
        
        // Because Flickr only returns 4000 unique photos, we will limit pages to about upperPageLimit to ensure that we have random pulls with new content.
        upperPageLimit = 112
        resultsPerPage = 36
        
        // Initializing to 1 but will be set later by the getPageNumbers function that grabs a random page number within the range (up to upperPageLimit).
        page = 1
    }
    
    // Helper function to parse JSON data.
    func parseJSONResult(data: NSData) -> NSDictionary?  {
        var parsingError: NSError? = nil
        let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
        return parsedResult
    }
    
    // The base Flickr search based on the bbox of the pin's latitude and longitude
    func search(completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        // First, grab a random page from Flickr with the same arguments below
        self.getPageNumbers() {JSONResult, error in
            
            if let error = error {
                println("Error")
                
            } else {
                
                self.page = JSONResult as! Int
                
                let methodArguments: [String: AnyObject] = [
                    "method": self.METHOD_NAME,
                    "api_key": self.API_KEY,
                    "bbox": self.createBoundingBoxString(),
                    "safe_search": self.SAFE_SEARCH,
                    "extras": self.EXTRAS,
                    "format": self.DATA_FORMAT,
                    "nojsoncallback": self.NO_JSON_CALLBACK,
                    "per_page": self.resultsPerPage,
                    "accuracy": self.ACCURACY,
                    "page": self.page
                ]
                
                // Create the API call
                let urlString = self.BASE_URL + self.escapedParameters(methodArguments)
                let url = NSURL(string: urlString)!
                let request = NSURLRequest(URL: url)
                let task = self.session.dataTaskWithRequest(request) {data, response, error in
                    if error != nil {
                        // Handle error
                        completionHandler(result: nil, error: NSError(domain: "Download", code: 0, userInfo: [NSLocalizedDescriptionKey: "Download Error"]))
                    } else {
                        // Parse the result to hand the photo array to the PhotoAlbumViewController
                        if let result = self.parseJSONResult(data) {
                            if let photosDict = result["photos"] as? NSDictionary {
                                if let photosArray = photosDict["photo"] as? [[String: AnyObject]] {
                                    completionHandler(result: photosArray, error: nil)
                                }
                            }
                        }
                    }
                }
                task.resume()
            }
        }
        
    }
    
    // Function to grab a random page number from Flickr with the same parameters as the above search call.
    func getPageNumbers(completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "bbox": createBoundingBoxString(),
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK,
            "per_page": self.resultsPerPage,
            "accuracy": self.ACCURACY
        ]
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments as! [String : AnyObject])
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, error in
            if error != nil {
                // Handle error
                completionHandler(result: nil, error: NSError(domain: "Download", code: 0, userInfo: [NSLocalizedDescriptionKey: "Download Error"]))
            } else {
                if let result = self.parseJSONResult(data) {
                    if let photos = result["photos"] as? NSDictionary {
                        // Here we grab a random number up to the upperPageLimit to ensure content is not repeated.
                        if let numPages = photos["pages"] as? Int {
                            var randomPage = 1
                            if numPages > self.upperPageLimit {
                                randomPage = Int(arc4random_uniform(UInt32(self.upperPageLimit)))
                            } else {
                                randomPage = Int(arc4random_uniform(UInt32(numPages)))
                            }
                            completionHandler(result: randomPage, error: nil)
                        } else {
                            completionHandler(result: nil, error: NSError(domain: "Download", code: 0, userInfo: [NSLocalizedDescriptionKey: "Download Error"]))
                        }
                    }
                }
            }
        }
        task.resume()
        return task
    }
    
    // Processing images that have a path.
    func taskForImage(filePath: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        
        let request = NSURLRequest(URL: NSURL(string: filePath)!)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                completionHandler(imageData: nil, error: NSError(domain: "Download", code: 0, userInfo: [NSLocalizedDescriptionKey: "Download Error"]))
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        
        task.resume()
        
        return task
    }
    
    // Helper function to build escaped parameters for the Flickr call.
    func escapedParameters(parameters: [String: AnyObject]) -> String {
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
    // Helper function to build the bbox string
    func createBoundingBoxString() -> String {
        
        /* Fix added to ensure box is bounded by minimum and maximum */
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    struct Caches {
        static let imageCache = ImageCache()
    }
}
