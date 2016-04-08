//
//  Data.swift
//  MATLABit
//
//  Created by Tomn on 08/04/16.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit

class Data {
    
    static let sharedData = Data()
    
    var connectionsTooMany: NSTimeInterval?
    var connectionsAttempts = 0
    private var pendingConnections = 0
    
    private init() { }
    
    func needsLoadingSpin(asks: Bool) {
        if asks {
            pendingConnections += 1
        } else {
            pendingConnections -= 1
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = pendingConnections > 0
    }
    
    class func isConnected() -> Bool {
        return KeychainSwift().get("login") != nil
    }
    
    class func connect(login: String?, pass: String?, username: String?) {
        let keychain = KeychainSwift()
        keychain.set(login!, forKey: "login")
        keychain.set(pass!, forKey: "passw")
        keychain.set(username!, forKey: "uname")
    }
    
    class func deconnect()  {
        KeychainSwift().clear()
    }
    
    class func JSONRequest(url: String, post: [String: String]?, response: (JSON: AnyObject) -> Void) {
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        if let postData = post {
            request.HTTPMethod = "POST"
            request.HTTPBody = postData.URLBodyString()
        }
        let defaultSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
                                          delegate: nil, delegateQueue: NSOperationQueue.mainQueue())
        let dataTast = defaultSession.dataTaskWithRequest(request) { (data, resp, error) in
            Data.sharedData.needsLoadingSpin(false)
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                response(JSON: JSON)
            } catch {
                let alert = UIAlertController(title: "Erreur inconnue",
                                              message: "Impossible de récupérer la réponse du serveur", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                UIApplication.sharedApplication().keyWindow?.rootViewController!.presentViewController(alert, animated: true, completion: nil)
            }
        }
        Data.sharedData.needsLoadingSpin(true)
        dataTast.resume()
    }
}


extension String {
    func sha256() -> String {
        let data = self.dataUsingEncoding(NSUTF8StringEncoding)!
        let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(data.bytes, CC_LONG(data.length), UnsafeMutablePointer(res!.mutableBytes))
        
        return "\(res!)".stringByReplacingOccurrencesOfString("<", withString: "").stringByReplacingOccurrencesOfString(">", withString: "").stringByReplacingOccurrencesOfString(" ", withString: "")
    }
}


extension Dictionary {
    func URLBodyString() -> NSData {
        var queryItems = Array<NSURLQueryItem>()
        for (key, value) in self {
            queryItems.append(NSURLQueryItem(name: String(key), value: String(value)))
        }
        let comps = NSURLComponents();
        comps.queryItems = queryItems
        let queryString = comps.percentEncodedQuery ?? ""
        return queryString.dataUsingEncoding(NSUTF8StringEncoding)!
    }
}

extension UIImage {
    func scaleAndCrop(target: CGSize, retina: Bool, fit: Bool) -> UIImage {
        let imageSize = self.size
        let width = imageSize.width
        let height = imageSize.height
        let targetWidth = target.width
        let targetHeight = target.height
        var scaleFactor: CGFloat = 0.0
        var scaledWidth = targetWidth
        var scaledHeight = targetHeight
        var thumbnailPoint = CGPointMake(0.0, 0.0)
        
        if CGSizeEqualToSize(imageSize, target) == false {
            let widthFactor: CGFloat = targetWidth / width
            let heightFactor: CGFloat = targetHeight / height
            
            if fit {
                if widthFactor < heightFactor {
                    scaleFactor = widthFactor
                } else {
                    scaleFactor = heightFactor
                }
            } else {
                if widthFactor > heightFactor {
                    scaleFactor = widthFactor
                } else {
                    scaleFactor = heightFactor
                }
            }
            
            scaledWidth  = width * scaleFactor
            scaledHeight = height * scaleFactor
            
            // center the image
            if (fit) {
                if widthFactor < heightFactor {
                    thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5
                } else if widthFactor > heightFactor {
                    thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5
                }
            } else {
                if (widthFactor > heightFactor) {
                    thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5
                } else if (widthFactor < heightFactor) {
                    thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5
                }
            }
        }
        
        if retina {
            UIGraphicsBeginImageContextWithOptions(target, true, 0.0)
        } else {
            UIGraphicsBeginImageContext(target) // crop
        }
        
        var thumbnailRect = CGRectZero
        thumbnailRect.origin = thumbnailPoint
        thumbnailRect.size.width  = scaledWidth
        thumbnailRect.size.height = scaledHeight
        if fit {
            UIColor.whiteColor().set()
            UIRectFill(CGRectMake(0.0, 0.0, target.width, target.height))
        }
        
        self.drawInRect(thumbnailRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}