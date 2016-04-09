//
//  User.swift
//  MATLABit
//
//  Created by Tomn on 08/04/16.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit

class User: JAQBlurryTableViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    private let URLconnect = ""
    private let nbrMaxConnectAttempts = 5
    private let imgSize: CGFloat = UIScreen.mainScreen().bounds.size.height < 500 ? 120 : 170
    private let ph = ["lannistertyr", "snowjohn", "starkarya", "whitewalter", "pinkmanjesse", "swansonron", "nadirabed", "mccormickkenny", "foxmulder", "goodmansaul", "rothasher", "archersterling"]
    
    private var decalOrientDebut: CGFloat = UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) ? -32 : 0
    
    var emptyDataSetView: DZNEmptyDataSetView!
    @IBOutlet weak var connexionCell: UITableViewCell!
    @IBOutlet weak var idField: UITextField!
    @IBOutlet weak var mdpField: UITextField!
    @IBOutlet weak var spin: UIActivityIndicatorView!
    @IBOutlet weak var spinBtn: UIBarButtonItem!
    private var decoBtn: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        decoBtn = UIBarButtonItem(title: "Déconnexion", style: .Plain, target: self, action: #selector(deconnexion))
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(viewWillAppear(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        chargerUI()
        configureBannerWithImage(UIImage(named: "header"),
                                 blurRadius: 0, blurTintColor: UIColor.clearColor(), saturationFactor: 1, maxHeight: 157)
        reloadEmpty()
    }
    
    
    // MARK: - Actions
    
    func chargerUI() {
        let index = Int(arc4random_uniform(UInt32(ph.count)))
        idField.placeholder = ph[index]
        
        var bouton = spinBtn
        if Data.isConnected() {
            bouton = decoBtn
        }
        navigationItem.setLeftBarButtonItems([bouton], animated: true)
    }
    
    @IBAction func fermer() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func connexion() {
        idField.resignFirstResponder()
        mdpField.resignFirstResponder()
        
        let login = idField.text?.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
        let pass: NSString = mdpField.text!
        
        if login == "" || pass == "" {
            return
        }
        
        // Éviter le brute force et la surcharge
        var bug = false
        if let lastTry = Data.sharedData.connectionsTooMany {
            if NSDate.timeIntervalSinceReferenceDate() - lastTry <= 300 {
                bug = true
            }
        }
        else if Data.sharedData.connectionsAttempts >= nbrMaxConnectAttempts {
            Data.sharedData.connectionsTooMany = NSDate.timeIntervalSinceReferenceDate()
            bug = true
        }
        if bug {
            let alert = UIAlertController(title: "Doucement",
                                          message: "Veuillez attendre 5 minutes, vous avez réalisé trop de tentatives à la suite.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title:"Mince !", style: .Cancel, handler:nil))
            presentViewController(alert, animated:true, completion:nil)
            return;
        }
        
        // CONNEXION
        Data.sharedData.connectionsAttempts += 1
        
        connexionCell.textLabel?.enabled = false
        connexionCell.userInteractionEnabled = false
        connexionCell.selectionStyle = .None
        
        // Codage du mot de passe
        let passDec = NSMutableString()
        for i in 0 ..< pass.length {
            let ch = pass.characterAtIndex(i)
            passDec.appendFormat("%c", (unichar)(ch + 1))
        }
        let pass1: NSString = (pass.dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions([]))!
        let pass2: NSString = (passDec.dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions([]))!
        let passFinal = NSMutableString()
        for i in 0 ..< pass2.length {
            passFinal.appendFormat("%c%c", pass1.characterAtIndex(i), pass2.characterAtIndex(i))
        }
        let finPass = passFinal.length > 2 ? passFinal.substringFromIndex(passFinal.length - 2) : ""
        if finPass != "==" {
            passFinal.appendString("==")
        }
        
        let lePassFinal = "Oups, erreur de connexion \(pass)".sha256()
        
        // Envoi
        let hash = "\(login)selfRetain_$_0x128D4_objc".sha256()
        let body: [String: String] = ["username": login!, "password": passFinal as String, "hash": hash]
        Data.JSONRequest(URLconnect, post: body) { (JSON) in
            var connecté = false
            let alert = UIAlertController(title: "Erreur inconnue",
                                          message: "Impossible de valider votre connexion.", preferredStyle: .Alert)
            
            if let status = JSON["status"] as? Int,
                let data = JSON["data"] as? [String: AnyObject],
                let username = data["username"] as? String,
                let info = data["info"] as? String {
                if status == 1 {
                    let nom = username.componentsSeparatedByString(" ")[0]
                    var title = "Bienvenue \(nom) !"
                    if info.containsString("existe") {
                        title = "Vous êtes de retour, \(nom) !"
                    }
                    
                    connecté = true
                    Data.sharedData.connectionsAttempts = 0
                    Data.sharedData.connectionsTooMany = nil
                    
                    alert.title = title
                    alert.message = "Vous êtes désormais connecté(e)."
                    
                    Data.connect(login, pass: lePassFinal, username: username)
                } else if status == 2 {
                    alert.title = "Oups…"
                    alert.message = "Mauvaise combinaison identifiant/mot de passe.\nVeuillez vérifier vos informations, puis réessayer."
                }
            }
            
            self.spin.stopAnimating()
            self.connexionCell.textLabel!.enabled = true
            self.connexionCell.userInteractionEnabled = true
            self.connexionCell.selectionStyle = .Default
            
            alert.addAction(UIAlertAction(title: connecté ? "Parfait" : "OK", style: .Cancel, handler: { (a) in
                if connecté {
                    self.fermer()
                }
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        spin.startAnimating()
        
        let request = NSMutableURLRequest(URL: NSURL(string: URLconnect)!)
        request.HTTPMethod = "POST"
        request.HTTPBody = body.URLBodyString()
        let defaultSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
                                          delegate: nil, delegateQueue: NSOperationQueue.mainQueue())
        let dataTast = defaultSession.dataTaskWithRequest(request) { (data, response, error) in
            Data.sharedData.needsLoadingSpin(false)
            var connecte = false
            let alert = UIAlertController(title: "Erreur inconnue",
                                          message: "Impossible de valider votre connexion. Si le problème persiste, contactez-nous.", preferredStyle: .Alert)
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                
                if let status = JSON["status"] as? Int,
                    let data = JSON["data"] as? [String: AnyObject],
                    let username = data["username"] as? String,
                    let info = data["info"] as? String {
                    if status == 1 {
                        let nom = username.componentsSeparatedByString(" ")[0]
                        var title = "Bienvenue \(nom) !"
                        if info.containsString("existe") {
                            title = "Vous êtes de retour, \(nom) !"
                        }
                        
                        connecte = true
                        Data.sharedData.connectionsAttempts = 0
                        Data.sharedData.connectionsTooMany = nil
                        
                        alert.title = title
                        alert.message = "Vous êtes désormais connecté(e)."
                        
                        Data.connect(login, pass: lePassFinal, username: username)
                        NSNotificationCenter.defaultCenter().postNotificationName("connecte", object: nil)
                    } else if status == 2 {
                        alert.title = "Oups…"
                        alert.message = "Mauvaise combinaison identifiant/mot de passe.\nVeuillez vérifier vos informations, puis réessayer."
                    }
                }
            } catch {
                alert.title = "Erreur inconnue"
                alert.message = "Impossible de récupérer la réponse du serveur"
            }
            
            self.spin.stopAnimating()
            self.connexionCell.textLabel!.enabled = true
            self.connexionCell.userInteractionEnabled = true
            self.connexionCell.selectionStyle = .Default
            
            alert.addAction(UIAlertAction(title: connecte ? "Parfait" : "OK", style: .Cancel, handler: { (a) in
                if connecte {
                    self.fermer()
                }
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            
        }
        Data.sharedData.needsLoadingSpin(true)
        spin.startAnimating()
        dataTast.resume()
    }
    
    func deconnexion() {
        let alert = UIAlertController(title: "Veux-tu vraiment te déconnecter ?",
                                      message: "On s'amusait bien !", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Annuler", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Oui", style: .Default, handler: { (a) in
            
            let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let filePath = documentsPath.stringByAppendingPathComponent("imageProfil.png")
            if NSData(contentsOfFile: filePath) != nil {
                self.removePhoto()
            }
            
            Data.deconnect()
            
            self.chargerUI()
            self.tableView.reloadData()
            
            NSNotificationCenter.defaultCenter().postNotificationName("connecte", object: nil)
        }))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - Photo
    
    func choosePhoto() {
        let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let filePath = documentsPath.stringByAppendingPathComponent("imageProfil.png")
        if NSData(contentsOfFile: filePath) != nil {
            let alert = UIAlertController(title: "Changer l'image de profil", message: "", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Supprimer la photo", style: .Destructive, handler: { (a) in
                self.removePhoto()
            }))
            alert.addAction(UIAlertAction(title: "Choisir une photo", style: .Default, handler: { (a) in
                self.showPhotos()
            }))
            alert.addAction(UIAlertAction(title: "Annuler", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        } else {
            showPhotos()
        }
    }
    
    func removePhoto() {
        let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let filePath = documentsPath.stringByAppendingPathComponent("imageProfil.png")
        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.removeItemAtPath(filePath)
        } catch let error as NSError {
            let alert = UIAlertController(title: "Impossible de supprimer l'image",
                                          message: error.localizedDescription, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        }
        
        reloadEmpty()
    }
    
    func showPhotos() {
        if (UI_USER_INTERFACE_IDIOM() == .Pad)
        {
            let pop = UIImagePickerController()
            pop.sourceType = .PhotoLibrary
            pop.delegate = self
            let popOver = UIPopoverController(contentViewController: pop)
            popOver.presentPopoverFromRect(tableView.emptyDataSetView.imageView.convertRect(tableView.emptyDataSetView.imageView.bounds, toView: navigationController!.view), inView: view, permittedArrowDirections: .Any, animated: true)
        }
        else
        {
            let pop = UIImagePickerController()
            pop.sourceType = .PhotoLibrary
            pop.delegate = self
            presentViewController(pop, animated: true, completion: { 
                UIApplication.sharedApplication().statusBarStyle = .LightContent
            })
        }
    }
    
    
    // MARK: Image picker delegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        var image = info[UIImagePickerControllerOriginalImage] as! UIImage
        let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let filePath = documentsPath.stringByAppendingPathComponent("imageProfil.png")
        
        image = image.scaleAndCrop(CGSizeMake(imgSize, imgSize), retina: false, fit: false)
        let imageData = UIImagePNGRepresentation(image)
        imageData?.writeToFile(filePath, atomically: false)
        
        reloadEmpty()
        
        dismissViewControllerAnimated(true) {
            UIApplication.sharedApplication().statusBarStyle = .LightContent
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        UIApplication.sharedApplication().statusBarStyle = .LightContent
    }
    
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        UIApplication.sharedApplication().statusBarStyle = .LightContent
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (Data.isConnected()) ? 0 : 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if Data.isConnected() {
            return 0
        } else if section == 1 {
            return 1
        }
        return 2
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 && indexPath.row == 0 {
            connexion()
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    
    // MARK: - Text Field delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if idField.isFirstResponder() {
            return mdpField.becomeFirstResponder()
        } else {
            connexion()
        }
        return false
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text
        var proposedString: NSString = (text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        proposedString = proposedString.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
        let length = proposedString.length
        
        var prev1 = idField.text != ""
        var prev2 = mdpField.text != ""
        let prev  = prev1 && prev2
        if textField.tag > 0 {
            prev2 = length > 0
        } else {
            prev1 = length > 0
        }
        
        let nouv = prev1 && prev2
        if prev != nouv {
            connexionCell.textLabel?.enabled = nouv
            connexionCell.selectionStyle = (nouv) ? .Default : .None
        }
        
        if textField.tag > 0 {
            return true
        }
        
        return length <= 15
    }
    
    
    // MARK: - DZNEmptyDataSet
    
    func reloadEmpty() {
        tableView.reloadEmptyDataSet()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(choosePhoto))
        tableView.emptyDataSetView.imageView.userInteractionEnabled = true
        tableView.emptyDataSetView.imageView.addGestureRecognizer(tap)
        
        tableView.emptyDataSetView.imageView.layer.cornerRadius = CGFloat(imgSize / 2)
        tableView.emptyDataSetView.imageView.clipsToBounds = true
        tableView.emptyDataSetView.imageView.layer.borderWidth = 4
        tableView.emptyDataSetView.imageView.layer.borderColor = UIColor.whiteColor().CGColor
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        if UI_USER_INTERFACE_IDIOM() != .Pad && (UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) || UIScreen.mainScreen().bounds.size.width > UIScreen.mainScreen().bounds.size.height) {
            return nil
        }
        
        let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let filePath = documentsPath.stringByAppendingPathComponent("imageProfil.png")
        if let data = NSData(contentsOfFile: filePath) {
            return UIImage(data: data)
        }
        
        if UIScreen.mainScreen().bounds.size.height < 500 {
            return UIImage(named:"defaultUser")?.scaleAndCrop(CGSizeMake(imgSize, imgSize), retina: false, fit: false)
        }
        return UIImage(named:"defaultUser")
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Salut"
        let attrs = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18),
                     NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Vous êtes connecté(e)"
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .ByWordWrapping
        paragraph.alignment = .Center
        let attrs = [NSFontAttributeName: UIFont.systemFontOfSize(12),
                     NSForegroundColorAttributeName: UIColor.lightGrayColor(),
                     NSParagraphStyleAttributeName: paragraph]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func offsetForEmptyDataSet(scrollView: UIScrollView!) -> CGPoint {
        if UIScreen.mainScreen().bounds.size.height <= 320 && UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) {
            return CGPointMake(0, -tableView.tableHeaderView!.frame.size.height / 2 + 180 + decalOrientDebut)
        }
        return CGPointMake(0, -tableView.tableHeaderView!.frame.size.height / 2 + 150 + decalOrientDebut)
    }
}
