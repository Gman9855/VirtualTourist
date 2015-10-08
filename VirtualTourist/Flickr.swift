//
//  Flickr.swift
//  VirtualTourist
//
//  Created by Gershy Lev on 10/4/15.
//  Copyright (c) 2015 Gershy Lev. All rights reserved.
//

import UIKit

class Flickr {
    
    var latitude: Double
    var longitude: Double
    var session: NSURLSession
    var resultsPerPage: Int
    let ACCURACY: Int
    var page: Int
    var upperPageLimit: Int
    
    init(lat: Double, lon: Double) {
        session = NSURLSession.sharedSession()
        
        latitude = lat
        longitude = lon
        ACCURACY = 16
        upperPageLimit = 112
        resultsPerPage = 36
        page = 1
    }
    
    func parseJSONResult(data: NSData) -> NSDictionary?  {
        var parsingError: NSError? = nil
        let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
        return parsedResult
    }
    
    func search(completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        self.getPageNumbers() {JSONResult, error in
            
            if let error = error {
                println("Error")
            } else {
                self.page = JSONResult as! Int
                
                let methodArguments: [String: AnyObject] = [
                    "method": Flickr.METHOD_ARGS.METHOD_NAME,
                    "api_key": Flickr.API_KEY.API_KEY,
                    "bbox": self.createBoundingBoxString(),
                    "safe_search": Flickr.METHOD_ARGS.SAFE_SEARCH,
                    "extras": Flickr.METHOD_ARGS.EXTRAS,
                    "format": Flickr.METHOD_ARGS.DATA_FORMAT,
                    "nojsoncallback": Flickr.METHOD_ARGS.NO_JSON_CALLBACK,
                    "per_page": self.resultsPerPage,
                    "accuracy": self.ACCURACY,
                    "page": self.page
                ]
                
                let urlString = Flickr.URLs.BASE_URL + self.escapedParameters(methodArguments)
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
    
    func getPageNumbers(completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        let methodArguments = [
            "method": Flickr.METHOD_ARGS.METHOD_NAME,
            "api_key": Flickr.API_KEY.API_KEY,
            "bbox": createBoundingBoxString(),
            "safe_search": Flickr.METHOD_ARGS.SAFE_SEARCH,
            "extras": Flickr.METHOD_ARGS.EXTRAS,
            "format": Flickr.METHOD_ARGS.DATA_FORMAT,
            "nojsoncallback": Flickr.METHOD_ARGS.NO_JSON_CALLBACK,
            "per_page": self.resultsPerPage,
            "accuracy": self.ACCURACY
        ]
        
        let session = NSURLSession.sharedSession()
        let urlString = Flickr.URLs.BASE_URL + escapedParameters(methodArguments as! [String : AnyObject])
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, error in
            if error != nil {
                // Handle error
                completionHandler(result: nil, error: NSError(domain: "Download", code: 0, userInfo: [NSLocalizedDescriptionKey: "Download Error"]))
            } else {
                if let result = self.parseJSONResult(data) {
                    if let photos = result["photos"] as? NSDictionary {
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
    
    func createBoundingBoxString() -> String {
        
        /* Fix added to ensure box is bounded by minimum and maximum */
        let bottom_left_lon = max(longitude - Flickr.METHOD_ARGS.BOUNDING_BOX_HALF_WIDTH, Flickr.METHOD_ARGS.LON_MIN)
        let bottom_left_lat = max(latitude - Flickr.METHOD_ARGS.BOUNDING_BOX_HALF_HEIGHT, Flickr.METHOD_ARGS.LAT_MIN)
        let top_right_lon = min(longitude + Flickr.METHOD_ARGS.BOUNDING_BOX_HALF_HEIGHT, Flickr.METHOD_ARGS.LON_MAX)
        let top_right_lat = min(latitude + Flickr.METHOD_ARGS.BOUNDING_BOX_HALF_HEIGHT, Flickr.METHOD_ARGS.LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    struct Caches {
        static let imageCache = ImageCache()
    }
}
