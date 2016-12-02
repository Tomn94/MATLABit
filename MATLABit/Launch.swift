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
        Data.JSONRequest("https://web59.secure-secure.co.uk/francoisle.fr/wdidy/faq/data.json", on: self, post: nil, cache: .reloadIgnoringLocalCacheData) { (JSON) in
            self.spin.stopAnimating()
            if let json = JSON {
                if let status = json["status"] as? Int,
                   let data   = json["data"] as? [String: AnyObject],
                   let logo   = data["logo"] as? String,
                   let logo2  = data["logoEux"] as? String,
                   let mp3    = data["son"] as? String,
                   let fb     = data["fb"] as? String,
                   let harder = data["harderiOS"] as? Double,
                   let php    = data["php"] as? [String: String],
                   let _ = php["connect"],
                   let _ = php["addPic"],
                   let _ = php["delPic"],
                   let _ = php["getScores"],
                   let _ = php["sendScore"],
                   let _ = php["getMatches"],
                   let _ = php["sendMatch"],
                   let _ = php["delMatch"],
                   let _ = php["getList"] {
                    if status == 200 {
                        Data.sharedData.fbURL = URL(string: fb)
                        Data.sharedData.harder = harder
                        Data.sharedData.phpURLs = php
                        SDWebImageManager.shared().downloadImage(with: URL(string: logo), options: [],
                                                                               progress: nil, completed: { (image, error, cacheType, finished, url) in
                            if let image = image {
                                Data.sharedData.logo = image
                                SDWebImageManager.shared().downloadImage(with: URL(string: logo2), options: [],
                                    progress: nil, completed: { (image2, error2, cacheType2, finished2, url2) in
                                        if let image2 = image2 {
                                            Data.sharedData.logo2 = image2
                                            if !Data.hasMP3(mp3) {
                                                let defaultSession = URLSession(configuration: .default, delegate: nil, delegateQueue: .main)
                                                let dataTast = defaultSession.dataTask(with: URL(string: mp3)!, completionHandler: { (data, resp, error) in
                                                    if error != nil || data == nil {
                                                        let alert = UIAlertController(title: "Oups…",
                                                            message: "Impossible de télécharger les données (3/3)", preferredStyle: .actionSheet)
                                                        self.present(alert, animated: true, completion: nil)
                                                    }
                                                    else if let d = data {
                                                        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
                                                        let filePath = documentsPath.appendingPathComponent("son.mp3")
                                                        try? d.write(to: URL(fileURLWithPath: filePath), options: [])
                                                        NotificationCenter.default.post(name: Notification.Name(rawValue: "launchFinished"), object: nil)
                                                    }
                                                }) 
                                                dataTast.resume()
                                            } else {
                                                NotificationCenter.default.post(name: Notification.Name(rawValue: "launchFinished"), object: nil)
                                            }
                                        } else {
                                            let alert = UIAlertController(title: "Oups…",
                                                message: "Impossible de télécharger les données (2/3)", preferredStyle: .actionSheet)
                                            self.present(alert, animated: true, completion: nil)
                                        }
                                })
                            } else {
                                let alert = UIAlertController(title: "Oups…",
                                    message: "Impossible de télécharger les données (1/3)", preferredStyle: .actionSheet)
                                self.present(alert, animated: true, completion: nil)
                                                                                }
                        })
                    } else {
                        let alert = UIAlertController(title: "Oups…",
                                                      message: "Impossible de récupérer les données", preferredStyle: .actionSheet)
                        self.present(alert, animated: true, completion: nil)
                    }
                } else {
                    let alert = UIAlertController(title: "Erreur inconnue",
                                                  message: "Vérifie ta connexion !", preferredStyle: .alert)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}
