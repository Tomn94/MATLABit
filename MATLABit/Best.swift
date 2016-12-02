//
//  Best.swift
//  MATLABit
//
//  Created by Thomas Naudet on 16/04/16.
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

class Best: UITableViewController, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    var emptyDataSetView: DZNEmptyDataSetView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let view = UIView()
        view.backgroundColor = UIColor.groupTableViewBackground
        tableView.backgroundView = view
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let login = KeychainSwift().get("login"),
            let passw = KeychainSwift().get("passw") {
            let body = ["client": login,
                        "password": passw,
                        "hash": ("TheSubsLongestNight" + login + passw).sha256()]
            Data.JSONRequest(Data.sharedData.phpURLs["getBest"]!, on: nil, post: body) { (JSON) in
                if let json = JSON {
                    if let status = json["status"] as? Int,
                        let data = json["data"] as? [String: AnyObject],
                        let people = data["people"] as? Array<[String: AnyObject]> {
                        if status == 1 {
                            let animation = CATransition()
                            animation.duration = 0.25
                            animation.type = kCATransitionFade
                            self.tableView.layer.add(animation, forKey: nil)
                            Data.sharedData.best = people
                        } else {
                            Data.sharedData.best = Array<[String: AnyObject]>()
                        }
                    } else {
                        Data.sharedData.best = Array<[String: AnyObject]>()
                    }
                    self.loadFetchedData()
                }
            }
        }
    }
    
    func loadFetchedData() {
        let hasData = !Data.sharedData.best.isEmpty
        tableView.backgroundColor = hasData ? UIColor.white : UIColor.groupTableViewBackground
        tableView.tableFooterView = hasData ? nil : UIView()
        
        tableView.reloadData()
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Data.sharedData.best.isEmpty ? 0 : 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Data.sharedData.best.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bestCell", for: indexPath)
        
        let data = Data.sharedData.best[indexPath.row]
        cell.textLabel?.text = data["name"] as? String
        
        var sub = "dans "
        if let nbr = data["nbr"] as? Int {
            sub += String(nbr) + " liste"
            
            if nbr > 1 {
                sub += "s"
            }
        }
        cell.detailTextLabel?.text = sub
        
        if let url = data["img"] as? String {
            cell.imageView?.sd_setImage(with: URL(string: url), placeholderImage: UIImage(named: "placeholder"))
        } else {
            cell.imageView?.image = UIImage(named: "placeholder")
        }
        
        return cell
    }
    
    
    // MARK: - DZNEmptyDataSet
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        let height = UIScreen.main.bounds.size.height
        if UI_USER_INTERFACE_IDIOM() != .pad && (UIDeviceOrientationIsLandscape(UIDevice.current.orientation) || UIScreen.main.bounds.size.width > height) {
            return nil
        }
        return Data.sharedData.logo2.scaleAndCrop(CGSize(width: 127 * pow(height / 480, 2), height: 127 * pow(height / 480, 2)))
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18),
                     NSForegroundColorAttributeName: UIColor.darkGray]
        return NSAttributedString(string: "Encore aucun match !", attributes: attrs)
    }
}
