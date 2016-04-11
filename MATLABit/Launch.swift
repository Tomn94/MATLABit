//
//  Launch.swift
//  MATLABit
//
//  Created by Tomn on 11/04/16.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit
import SDWebImage

class Launch: UIViewController {

    @IBOutlet weak var spin: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        spin.startAnimating()
        Data.JSONRequest("https://web59.secure-secure.co.uk/francoisle.fr/wdidy/faq/data.json", on: self, post: nil) { (JSON) in
            if let json = JSON {
                if let status = json["status"] as? Int,
                    data   = json["data"] as? [String: AnyObject],
                    logo   = data["logo"] as? String,
                    fb     = data["fb"] as? String,
                    harder = data["harder"] as? Double,
                    php    = data["php"] as? [String: String],
                    _ = php["connect"],
                    _ = php["getScores"],
                    _ = php["sendScore"],
                    _ = php["getMatches"],
                    _ = php["sendMatch"],
                    _ = php["getList"] {
                    if status == 200 {
                        Data.sharedData.fbURL = NSURL(string: fb)
                        Data.sharedData.harder = harder
                        Data.sharedData.phpURLs = php
                        SDWebImageManager.sharedManager().downloadImageWithURL(NSURL(string: logo), options: [],
                                                                               progress: nil, completed: { (image, error, cacheType, finished, url) in
                                                                                if image != nil {
                                                                                    Data.sharedData.logo = image
                                                                                    NSNotificationCenter.defaultCenter().postNotificationName("launchFinished", object: nil)
                                                                                } else {
                                                                                    let alert = UIAlertController(title: "Oups…",
                                                                                        message: "Impossible de télécharger les données", preferredStyle: .ActionSheet)
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
        spin.startAnimating()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}
