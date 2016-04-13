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
    
    var logo = UIImage(named: "ESEOasis")!
    var fbURL = NSURL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    var harder = 1.0
    var bestScore = 0
    var phpURLs = [String: String]()
    
    var scores = Array<(String, Int)>()
    var team = [Array<[String: AnyObject]>(), Array<[String: AnyObject]>()]
    
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
    
    class func hasProfilePic() -> Bool {
        let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let filePath = documentsPath.stringByAppendingPathComponent("imageProfil.jpg")
        return NSData(contentsOfFile: filePath) != nil
    }
    
    class func connect(login: String, pass: String, username: String) {
        let keychain = KeychainSwift()
        keychain.set(login, forKey: "login")
        keychain.set(pass, forKey: "passw")
        keychain.set(username, forKey: "uname")
    }
    
    class func deconnect()  {
        KeychainSwift().clear()
    }
    
    class func JSONRequest(url: String, on: UIViewController? = nil, post: [String: String]? = nil, cache: NSURLRequestCachePolicy = .UseProtocolCachePolicy,
                           response: (JSON: AnyObject?) -> Void = { _ in }) {
        let request = NSMutableURLRequest(URL: NSURL(string: url)!, cachePolicy: cache, timeoutInterval: 60)
        if let postData = post {
            request.HTTPMethod = "POST"
            request.HTTPBody = postData.URLBodyString()
        }
        let defaultSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
                                          delegate: nil, delegateQueue: NSOperationQueue.mainQueue())
        let dataTast = defaultSession.dataTaskWithRequest(request) { (data, resp, error) in
            var messageErreur = ""
            if let err = error {
                messageErreur = "\n" + err.localizedDescription
            }
            Data.sharedData.needsLoadingSpin(false)
            do {
                if let d = data {
                    let JSON = try NSJSONSerialization.JSONObjectWithData(d, options: [])
                    response(JSON: JSON)
                } else {
                    response(JSON: nil)
                    if let vc = on {
                        let alert = UIAlertController(title: "Erreur",
                                                      message: "Impossible d'analyser la réponse du serveur" + messageErreur, preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                        vc.presentViewController(alert, animated: true, completion: nil)
                    }
                }
            } catch {
                response(JSON: nil)
                if let vc = on {
                    let alert = UIAlertController(title: "Erreur",
                                                  message: "Impossible de récupérer la réponse du serveur" + messageErreur, preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                    vc.presentViewController(alert, animated: true, completion: nil)
                }
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
    
    func URLencode() -> String {
        let characters = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
        characters.removeCharactersInString("&")
        guard let encodedString = self.stringByAddingPercentEncodingWithAllowedCharacters(characters) else {
            return self
        }
        return encodedString
    }
}


extension Array where Element: Equatable {
    mutating func removeObject(element: Element) {
        if let index = indexOf(element) {
            removeAtIndex(index)
        }
    }
    mutating func removeObjects(elements: [Element]) {
        for element in elements {
            removeObject(element)
        }
    }
}
extension Array {
    func chunk(chunkSize : Int) -> Array<Array<Element>> {
        return 0.stride(to: count, by: chunkSize).map {
            Array(self[$0..<$0.advancedBy(chunkSize, limit: count)])
        }
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
    func scaleAndCrop(target: CGSize, retina: Bool = true, fit: Bool = true, opaque: Bool = false) -> UIImage {
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
            UIGraphicsBeginImageContextWithOptions(target, opaque, 0.0)
        } else {
            UIGraphicsBeginImageContext(target) // crop
        }
        
        var thumbnailRect = CGRectZero
        thumbnailRect.origin = thumbnailPoint
        thumbnailRect.size.width  = scaledWidth
        thumbnailRect.size.height = scaledHeight
        if fit && opaque {
            UIColor.whiteColor().set()
            UIRectFill(CGRectMake(0.0, 0.0, target.width, target.height))
        }
        
        self.drawInRect(thumbnailRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}