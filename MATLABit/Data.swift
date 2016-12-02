//
//  Data.swift
//  MATLABit
//
//  Created by Thomas Naudet on 08/04/16.
//  Copyright © 2016 Thomas Naudet

//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.

//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see http://www.gnu.org/licenses/
//

import UIKit

class Data {
    
    static let sharedData = Data()
    
    var connectionsTooMany: TimeInterval?
    var connectionsAttempts = 0
    
    var logo = UIImage(named: "ESEOasis")!
    var logo2 = UIImage(named: "ESEOasis")!
    var fbURL = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    var harder = 1.0
    var bestScore = 0
    var phpURLs = [String: String]()
    
    var scores = Array<(String, Int, String, Int)>()
    var team = [Array<[String: AnyObject]>(), Array<[String: AnyObject]>()]
    var best = Array<[String: AnyObject]>()
    
    private var pendingConnections = 0
    
    private init() { }
    
    func needsLoadingSpin(_ asks: Bool) {
        if asks {
            pendingConnections += 1
        } else {
            pendingConnections -= 1
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = pendingConnections > 0
    }
    
    class func isConnected() -> Bool {
        return KeychainSwift().get("login") != nil
    }
    
    class func hasProfilePic() -> Bool {
        let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let filePath = documentsPath.appendingPathComponent("imageProfil.jpg")
        return (try? Foundation.Data(contentsOf: URL(fileURLWithPath: filePath))) != nil
    }
    
    class func hasMP3(_ newURL: String) -> Bool {
        let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let filePath = documentsPath.appendingPathComponent("son.mp3")
        return (try? Foundation.Data(contentsOf: URL(fileURLWithPath: filePath))) != nil && UserDefaults.standard.string(forKey: "mp3URL") != nil && UserDefaults.standard.string(forKey: "mp3URL") == newURL
    }
    
    class func hasNotifs() -> Int {
        if UserDefaults.standard.bool(forKey: "notifsAsked") {
            if UIApplication.shared.isRegisteredForRemoteNotifications {
                return 1
            } else {
                return -1
            }
        }
        return 0;
    }
    
    class func connect(_ login: String, pass: String, username: String) {
        let keychain = KeychainSwift()
        _ = keychain.set(login, forKey: "login")
        _ = keychain.set(pass, forKey: "passw")
        _ = keychain.set(username, forKey: "uname")
    }
    
    class func deconnect()  {
        if let login = KeychainSwift().get("login"),
           let passw = KeychainSwift().get("passw"),
           let push = UserDefaults.standard.string(forKey: "pushToken") {
           let body = ["client": login,
                       "password": passw,
                       "os": "IOS",
                       "token": push,
                       "hash": ("Bonjour %s !" + login + passw + "IOS" + push).sha256()]
            Data.sharedData.needsLoadingSpin(true)
            Data.JSONRequest(Data.sharedData.phpURLs["delPush"]!, on: nil, post: body) { (JSON) in
                Data.sharedData.needsLoadingSpin(false)
                UserDefaults.standard.removeObject(forKey: "pushToken")
            }
        }
        
        _ = KeychainSwift().clear()
    }
    
    class func JSONRequest(_ url: String, on: UIViewController? = nil, post: [String: String]? = nil, cache: NSURLRequest.CachePolicy = .useProtocolCachePolicy,
                           response: @escaping (_ JSON: [String: AnyObject]?) -> Void = { _ in }) {
        var request = URLRequest(url: URL(string: url)!, cachePolicy: cache, timeoutInterval: 60)
        if let postData = post {
            request.httpMethod = "POST"
            request.httpBody = postData.URLBodyString()
        }
        let defaultSession = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: .main)
        let dataTask = defaultSession.dataTask(with: request, completionHandler: { (data, resp, error) in
            var messageErreur = ""
            if let err = error {
                messageErreur = "\n" + err.localizedDescription
            }
            Data.sharedData.needsLoadingSpin(false)
            do {
                if let d = data {
                    let JSON = try JSONSerialization.jsonObject(with: d, options: []) as! [String: AnyObject]
                    response(JSON)
                } else {
                    response(nil)
                    if let vc = on {
                        let alert = UIAlertController(title: "Erreur",
                                                      message: "Impossible d'analyser la réponse du serveur" + messageErreur, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        vc.present(alert, animated: true, completion: nil)
                    }
                }
            } catch {
                response(nil)
                if let vc = on {
                    let alert = UIAlertController(title: "Erreur",
                                                  message: "Impossible de récupérer la réponse du serveur" + messageErreur, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    vc.present(alert, animated: true, completion: nil)
                }
            }
        }) 
        Data.sharedData.needsLoadingSpin(true)
        dataTask.resume()
    }
}


extension String {
    func sha256() -> String {
        let data = self.data(using: String.Encoding.utf8)!
        let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256((data as NSData).bytes, CC_LONG(data.count), res?.mutableBytes.assumingMemoryBound(to: UInt8.self))
        
        return "\(res!)".replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "").replacingOccurrences(of: " ", with: "")
    }
    
    func URLencode() -> String {
        let characters = (CharacterSet.urlQueryAllowed as NSCharacterSet).mutableCopy() as! NSMutableCharacterSet
        characters.removeCharacters(in: "&")
        guard let encodedString = self.addingPercentEncoding(withAllowedCharacters: characters as CharacterSet) else {
            return self
        }
        return encodedString
    }
}


extension Array where Element: Equatable {
    mutating func removeObject(_ element: Element) {
        if let index = index(of: element) {
            remove(at: index)
        }
    }
    mutating func removeObjects(_ elements: [Element]) {
        for element in elements {
            removeObject(element)
        }
    }
}
extension Array {
    func chunk(_ chunkSize : Int) -> Array<Array<Element>> {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            let end = self.endIndex
            let chunkEnd = self.index($0, offsetBy: chunkSize, limitedBy: end) ?? end
            return Array(self[$0 ..< chunkEnd])
        }
    }
}


extension Dictionary {
    func URLBodyString() -> Foundation.Data {
        var queryItems = Array<URLQueryItem>()
        for (key, value) in self {
            queryItems.append(URLQueryItem(name: String(describing: key), value: String(describing: value)))
        }
        var comps = URLComponents();
        comps.queryItems = queryItems
        let queryString = comps.percentEncodedQuery ?? ""
        return queryString.data(using: String.Encoding.utf8)!
    }
}

extension UIImage {
    func scaleAndCrop(_ target: CGSize, retina: Bool = true, fit: Bool = true, opaque: Bool = false) -> UIImage {
        let imageSize = self.size
        let width = imageSize.width
        let height = imageSize.height
        let targetWidth = target.width
        let targetHeight = target.height
        var scaleFactor: CGFloat = 0.0
        var scaledWidth = targetWidth
        var scaledHeight = targetHeight
        var thumbnailPoint = CGPoint(x: 0.0, y: 0.0)
        
        if imageSize.equalTo(target) == false {
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
        
        var thumbnailRect = CGRect.zero
        thumbnailRect.origin = thumbnailPoint
        thumbnailRect.size.width  = scaledWidth
        thumbnailRect.size.height = scaledHeight
        if fit && opaque {
            UIColor.white.set()
            UIRectFill(CGRect(x: 0.0, y: 0.0, width: target.width, height: target.height))
        }
        
        self.draw(in: thumbnailRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
