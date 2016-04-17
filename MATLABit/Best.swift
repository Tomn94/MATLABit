//
//  Best.swift
//  MATLABit
//
//  Created by Tomn on 16/04/16.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit

class Best: UITableViewController, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    var emptyDataSetView: DZNEmptyDataSetView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let view = UIView()
        view.backgroundColor = UIColor.groupTableViewBackgroundColor()
        tableView.backgroundView = view
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let login = KeychainSwift().get("login"),
            passw = KeychainSwift().get("passw") {
            let body = ["client": login,
                        "password": passw,
                        "hash": ("TheSubsLongestNight" + login + passw).sha256()]
            Data.JSONRequest(Data.sharedData.phpURLs["getBest"]!, on: self, post: body) { (JSON) in
                if let json = JSON {
                    if let status = json.valueForKey("status") as? Int,
                        data = json.valueForKey("data") as? [String: AnyObject],
                        people = data["people"] as? Array<[String: AnyObject]> {
                        if status == 1 {
                            let animation = CATransition()
                            animation.duration = 0.25
                            animation.type = kCATransitionFade
                            self.tableView.layer.addAnimation(animation, forKey: nil)
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
        let hasData = Data.sharedData.best.count > 0
        tableView.backgroundColor = hasData ? UIColor.whiteColor() : UIColor.groupTableViewBackgroundColor()
        tableView.tableFooterView = hasData ? nil : UIView()
        
        tableView.reloadData()
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Data.sharedData.best.count > 0 ? 1 : 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Data.sharedData.best.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("bestCell", forIndexPath: indexPath)
        
        let data = Data.sharedData.best[indexPath.row]
        cell.textLabel?.text = data["name"] as? String
        
        var sub = "Dans "
        if let nbr = data["nbr"] as? Int {
            sub += String(nbr) + " liste"
            
            if nbr > 1 {
                sub += "s"
            }
        }
        cell.detailTextLabel?.text = sub
        
        if let url = data["img"] as? String {
            cell.imageView?.sd_setImageWithURL(NSURL(string: url), placeholderImage: UIImage(named: "placeholder"))
        } else {
            cell.imageView?.image = UIImage(named: "placeholder")
        }
        
        return cell
    }
    
    
    // MARK: - DZNEmptyDataSet
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        let height = UIScreen.mainScreen().bounds.size.height
        if UI_USER_INTERFACE_IDIOM() != .Pad && (UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) || UIScreen.mainScreen().bounds.size.width > height) {
            return nil
        }
        return Data.sharedData.logo2.scaleAndCrop(CGSize(width: 127 * pow(height / 480, 2), height: 127 * pow(height / 480, 2)))
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18),
                     NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: "Encore aucun match !", attributes: attrs)
    }
}
