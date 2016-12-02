//
//  Liste.swift
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

class Liste: UITableViewController, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    var emptyDataSetView: DZNEmptyDataSetView!
    fileprivate let reci = "  💞 réciproque"
    
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
                        "hash": ("JavaleduSwift,Taylor" + login + passw).sha256()]
            Data.JSONRequest(Data.sharedData.phpURLs["getList"]!, on: nil, post: body) { (JSON) in
                if let json = JSON {
                    if let status = json["status"] as? Int,
                        let data = json["data"] as? [String: AnyObject],
                        let moi = data["moi"] as? Array<[String: AnyObject]>,
                        let eux = data["eux"] as? Array<[String: AnyObject]> {
                        if status == 1 {
                            let animation = CATransition()
                            animation.duration = 0.25
                            animation.type = kCATransitionFade
                            self.tableView.layer.add(animation, forKey: nil)
                            Data.sharedData.team = [moi, eux]
                        } else {
                            Data.sharedData.team = [Array<[String: AnyObject]>(), Array<[String: AnyObject]>()]
                        }
                    } else {
                        Data.sharedData.team = [Array<[String: AnyObject]>(), Array<[String: AnyObject]>()]
                    }
                    self.loadFetchedData()
                }
            }
        }
    }
    
    func loadFetchedData() {
        let hasData = !Data.sharedData.team[0].isEmpty && !Data.sharedData.team[1].isEmpty
        tableView.backgroundColor = hasData ? UIColor.white : UIColor.groupTableViewBackground
        tableView.tableFooterView = hasData ? nil : UIView()
        
        tableView.reloadData()
    }

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Data.sharedData.team.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Data.sharedData.team[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if Data.sharedData.team[0].count == 0 && Data.sharedData.team[1].count == 0 {
            return nil
        } else if section == 1 {
            if Data.sharedData.team[1].count > 1 {
                return "Tu as une touche ! Ils te veulent :"
            } else if !Data.sharedData.team[1].isEmpty {
                return "Tu as une touche ! Il/elle te veut :"
            } else {
                return "Tu n'as aucune touche"
            }
        }
        return "Ta liste"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "listeCell", for: indexPath)

        let data = Data.sharedData.team[indexPath.section][indexPath.row]
        
        var txt = data["name"] as! String
        cell.textLabel?.text = txt
        if let mutuel = data["mutual"] as? Bool, mutuel {
            txt += reci
            let at = NSMutableAttributedString(string: txt)
            let len = reci.characters.count
            at.setAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 13), NSForegroundColorAttributeName: UIColor(white: 0.7, alpha: 1)],
                             range: NSMakeRange(txt.characters.count - len, len + 1))
            cell.textLabel?.attributedText = at
        }
        
        var sub = ""
        var verbe = "a"
        var pronom = "sa liste"
        if let nbrOthers = data["others"] as? Int {
            if indexPath.section != 0 {
                sub = "T'es dans sa liste avec "
            }
            
            if nbrOthers > 1 {
                sub += String(nbrOthers) + " autres personnes"
                verbe = "ont"
                pronom = "la leur"
            } else if nbrOthers == 1 {
                sub += "1 autre personne"
            } else if indexPath.section == 0 {
                sub = "Personne à part toi ne l'a ajouté… 😏"
            } else {
                sub = "T'es tout seul dans sa liste… 😏"
            }
            
            if indexPath.section == 0 && nbrOthers >= 1 {
                sub += " l'" + verbe + " aussi dans " + pronom
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

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let coeur = Data.sharedData.team[0][indexPath.row]["login"] as? String,
                let login = KeychainSwift().get("login"),
                let passw = KeychainSwift().get("passw") {
                let body = ["coeur": coeur,
                            "client": login,
                            "password": passw,
                            "hash": ("jeSuisTresSerieuxxxx" + login + coeur + passw).sha256()]
                
                Data.JSONRequest(Data.sharedData.phpURLs["delMatch"]!, post: body) { (JSON) in
                    if let json = JSON,
                       let status = json["status"] as? Int,
                       let cause = json["cause"] as? String {
                        if status == 1 {
                            Data.sharedData.team[0].remove(at: indexPath.row)
                            tableView.deleteRows(at: [indexPath], with: .fade)
                        } else {
                            let alert = UIAlertController(title: "Erreur lors la suppresion", message: cause, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                    } else {
                        let alert = UIAlertController(title: "Erreur lors la suppresion", message: "Erreur serveur", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
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
        return NSAttributedString(string: "Tu peux tenter une monarchie mais ça va être compliqué…\nAjoute des membres à ta liste !", attributes: attrs)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17),
                     NSForegroundColorAttributeName: UINavigationBar.appearance().barTintColor!] as [String : Any]
        return NSAttributedString(string: "Matcher", attributes: attrs)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap didTapButton: UIButton!) {
        _ = navigationController?.popViewController(animated: true)
    }
}
