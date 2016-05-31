//
//  Launch.swift
//  MATLABit
//
//  Created by Thomas Naudet on 11/04/16.
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
import SDWebImage

class Launch: UIViewController {

    @IBOutlet weak var spin: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        spin.startAnimating()
        Data.JSONRequest("https://web59.secure-secure.co.uk/francoisle.fr/wdidy/faq/data.json", on: self, post: nil, cache: .ReloadIgnoringLocalCacheData) { (JSON) in
            self.spin.stopAnimating()
            if let json = JSON {
                if let status = json["status"] as? Int,
                    data   = json["data"] as? [String: AnyObject],
                    logo   = data["logo"] as? String,
                    logo2  = data["logoEux"] as? String,
                    mp3    = data["son"] as? String,
                    fb     = data["fb"] as? String,
                    harder = data["harderiOS"] as? Double,
                    php    = data["php"] as? [String: String],
                    _ = php["connect"],
                    _ = php["addPic"],
                    _ = php["delPic"],
                    _ = php["getScores"],
                    _ = php["sendScore"],
                    _ = php["getMatches"],
                    _ = php["sendMatch"],
                    _ = php["delMatch"],
                    _ = php["getList"] {
                    if status == 200 {
                        Data.sharedData.fbURL = NSURL(string: fb)
                        Data.sharedData.harder = harder
                        Data.sharedData.phpURLs = php
                        SDWebImageManager.sharedManager().downloadImageWithURL(NSURL(string: logo), options: [],
                                                                               progress: nil, completed: { (image, error, cacheType, finished, url) in
                            if image != nil {
                                Data.sharedData.logo = image
                                SDWebImageManager.sharedManager().downloadImageWithURL(NSURL(string: logo2), options: [],
                                    progress: nil, completed: { (image2, error2, cacheType2, finished2, url2) in
                                        if image != nil {
                                            Data.sharedData.logo2 = image2
                                            if !Data.hasMP3(mp3) {
                                                let defaultSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
                                                    delegate: nil, delegateQueue: NSOperationQueue.mainQueue())
                                                let dataTast = defaultSession.dataTaskWithURL(NSURL(string: mp3)!) { (data, resp, error) in
                                                    if error != nil || data == nil {
                                                        let alert = UIAlertController(title: "Oups…",
                                                            message: "Impossible de télécharger les données (3/3)", preferredStyle: .ActionSheet)
                                                        self.presentViewController(alert, animated: true, completion: nil)
                                                    }
                                                    else if let d = data {
                                                        let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
                                                        let filePath = documentsPath.stringByAppendingPathComponent("son.mp3")
                                                        d.writeToFile(filePath, atomically: false)
                                                        NSNotificationCenter.defaultCenter().postNotificationName("launchFinished", object: nil)
                                                    }
                                                }
                                                dataTast.resume()
                                            } else {
                                                NSNotificationCenter.defaultCenter().postNotificationName("launchFinished", object: nil)
                                            }
                                        } else {
                                            let alert = UIAlertController(title: "Oups…",
                                                message: "Impossible de télécharger les données (2/3)", preferredStyle: .ActionSheet)
                                            self.presentViewController(alert, animated: true, completion: nil)
                                        }
                                })
                            } else {
                                let alert = UIAlertController(title: "Oups…",
                                    message: "Impossible de télécharger les données (1/3)", preferredStyle: .ActionSheet)
                                self.presentViewController(alert, animated: true, completion: nil)
                                                                                }
                        })
                    } else {
                        let alert = UIAlertController(title: "Oups…",
                                                      message: "Impossible de récupérer les données", preferredStyle: .ActionSheet)
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                } else {
                    let alert = UIAlertController(title: "Erreur inconnue",
                                                  message: "Vérifie ta connexion !", preferredStyle: .Alert)
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}
