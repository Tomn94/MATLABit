//
//  User.swift
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
import SDWebImage

class User: JAQBlurryTableViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    private let nbrMaxConnectAttempts = 5
    private let imgSize: CGFloat = max(UIScreen.main.bounds.size.height, UIScreen.main.bounds.size.width) < 500 ? 120 : 170
    private let ph = ["lannistertyr", "snowjohn", "starkarya", "whitewalter", "pinkmanjesse", "swansonron", "nadirabed", "mccormickkenny", "foxmulder", "goodmansaul", "rothasher", "archersterling"]
    
    var emptyDataSetView: DZNEmptyDataSetView!
    @IBOutlet var connexionCell: UITableViewCell!
    @IBOutlet var idField: UITextField!
    @IBOutlet var mdpField: UITextField!
    @IBOutlet var spin: UIActivityIndicatorView!
    @IBOutlet var spinBtn: UIBarButtonItem!
    private var decoBtn: UIBarButtonItem!
    private var uploading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        decoBtn = UIBarButtonItem(title: "Déconnexion", style: .plain, target: self, action: #selector(deconnexion))
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(viewWillAppear(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        chargerUI()
        reloadEmpty()
    }
    
    
    // MARK: - Actions
    
    func chargerUI() {
        let index = Int(arc4random_uniform(UInt32(ph.count)))
        idField.placeholder = ph[index]
        
        if !Data.isConnected() {
            navigationItem.setLeftBarButtonItems([spinBtn], animated: true)
            configureBanner(with: UIImage(named: "header"),
                                     blurRadius: 0, blurTintColor: UIColor.clear, saturationFactor: 1, maxHeight: 157)
        } else {
            navigationItem.setLeftBarButtonItems([decoBtn], animated: true)
            configureBanner(with: nil)
        }
    }
    
    @IBAction func fermer() {
        if !uploading {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func connexion() {
        idField.resignFirstResponder()
        mdpField.resignFirstResponder()
        
        if uploading {
            return
        }
        
        let login = idField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let pass: NSString = mdpField.text! as NSString
        
        if login == "" || pass == "" {
            return
        }
        
        // Éviter le brute force et la surcharge
        var bug = false
        if let lastTry = Data.sharedData.connectionsTooMany {
            if Date.timeIntervalSinceReferenceDate - lastTry <= 300 {
                bug = true
            }
        }
        else if Data.sharedData.connectionsAttempts >= nbrMaxConnectAttempts {
            Data.sharedData.connectionsTooMany = Date.timeIntervalSinceReferenceDate
            bug = true
        }
        if bug {
            let alert = UIAlertController(title: "Doucement",
                                          message: "Veuillez attendre 5 minutes, tu as réalisé trop de tentatives à la suite.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title:"Mince !", style: .cancel, handler:nil))
            present(alert, animated:true, completion:nil)
            return;
        }
        
        // CONNEXION
        Data.sharedData.connectionsAttempts += 1
        
        connexionCell.textLabel?.isEnabled = false
        connexionCell.isUserInteractionEnabled = false
        connexionCell.selectionStyle = .none
        
        // Codage du mot de passe
        let passDec = NSMutableString()
        for i in 0 ..< pass.length {
            let ch = pass.character(at: i)
            passDec.appendFormat("%c", (unichar)(ch + 1))
        }
        let pass1: NSString = (pass.data(using: String.Encoding.utf8.rawValue)?.base64EncodedString(options: []))! as NSString
        let pass2: NSString = (passDec.data(using: String.Encoding.utf8.rawValue)?.base64EncodedString(options: []))! as NSString
        let passFinal = NSMutableString()
        for i in 0 ..< pass2.length {
            passFinal.appendFormat("%c%c", pass1.character(at: i), pass2.character(at: i))
        }
        let finPass = passFinal.length > 2 ? passFinal.substring(from: passFinal.length - 2) : ""
        if finPass != "==" {
            passFinal.append("==")
        }
        
        let lePassFinal = "Oups, erreur de connexion\(pass)".sha256()
        
        // Envoi
        let hash = (login! + (passFinal as String) + "selfRetain_$_0x128D4_objc").sha256()
        let body: [String: String] = ["username": login!, "password": passFinal as String, "hash": hash]
        Data.JSONRequest(Data.sharedData.phpURLs["connect"]!, on: nil, post: body) { (JSON) in
            self.uploading = false
            var connecté = false
            if let json = JSON {
                let alert = UIAlertController(title: "Erreur inconnue",
                                              message: "Impossible de valider votre connexion.", preferredStyle: .alert)
                if let status = json["status"] as? Int,
                    let cause = json["cause"] as? String {
                    if status == 1 {
                        if let data = json["data"] as? [String: AnyObject],
                            let username = data["username"] as? String,
                            let info = data["info"] as? String,
                            let img = data["img"] as? String {
                            let nom = username.components(separatedBy: " ")[0]
                            var title = "Bienvenue \(nom) !"
                            if info.contains("existe") {
                                title = "Hey, de retour, \(nom) !"
                            }
                            
                            if img != "" {
                                self.uploading = true
                                SDWebImageManager.shared().downloadImage(with: URL(string: img), options: [],
                                                                                       progress: nil, completed: { (image, error, cacheType, finished, url) in
                                                                                        self.uploading = false
                                                                                        if let image = image {
                                                                                            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
                                                                                            let filePath = documentsPath.appendingPathComponent("imageProfil.jpg")
                                                                                            
                                                                                            let pic = image.scaleAndCrop(CGSize(width: self.imgSize, height: self.imgSize), retina: false, fit: false, opaque: true)
                                                                                            let imageData = UIImageJPEGRepresentation(pic, 1.0)
                                                                                            try? imageData?.write(to: URL(fileURLWithPath: filePath), options: [])
                                                                                            self.reloadEmpty()
                                                                                        } else {
                                                                                            let alert = UIAlertController(title: "Oups…",
                                                                                                message: "Impossible de récupérer la photo de profil", preferredStyle: .actionSheet)
                                                                                            self.present(alert, animated: true, completion: nil)
                                                                                        }
                                })
                            }
                            
                            self.idField.text = ""
                            self.mdpField.text = ""
                            connecté = true
                            Data.sharedData.connectionsAttempts = 0
                            Data.sharedData.connectionsTooMany = nil
                            
                            alert.title = title
                            alert.message = "MATLABit te souhaite beaucoup de fruits, de l'eau de source, du fun\n\nN'oublie pas de choisir une photo de profil !"
                            
                            Data.connect(login!, pass: lePassFinal, username: username)
                        }
                    } else if status == -2 {
                        alert.title = "Oups…"
                        alert.message = "Mauvaise combinaison identifiant/mot de passe.\nVeuillez vérifier vos informations, puis réessayer."
                    } else {
                        alert.title = "Erreur"
                        alert.message = cause
                    }
                }
                
                alert.addAction(UIAlertAction(title: connecté ? "OKLM 👌🏼" : "OK", style: .cancel, handler: { (a) in
                    if connecté {
                        self.chargerUI()
                        self.tableView.reloadData()
                        self.reloadEmpty()
                    }
                }))
                self.present(alert, animated: true, completion: nil)
            }
            
            self.spin.stopAnimating()
            self.connexionCell.textLabel!.isEnabled = true
            self.connexionCell.isUserInteractionEnabled = true
            self.connexionCell.selectionStyle = .default
        }
        uploading = true
        spin.startAnimating()
    }
    
    func deconnexion() {
        if uploading {
            return
        }
        
        let alert = UIAlertController(title: "Veux-tu vraiment te déconnecter ?",
                                      message: "On s'amusait bien !", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Oui", style: .default, handler: { (a) in
            
            let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
            let filePath = documentsPath.appendingPathComponent("imageProfil.jpg")
            if (try? Foundation.Data(contentsOf: URL(fileURLWithPath: filePath))) != nil {
                self.removePhoto(false)
            }
            
            Data.deconnect()
            
            self.chargerUI()
            self.tableView.reloadData()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - Photo
    
    func choosePhoto() {
        let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let filePath = documentsPath.appendingPathComponent("imageProfil.jpg")
        if (try? Foundation.Data(contentsOf: URL(fileURLWithPath: filePath))) != nil {
            let alert = UIAlertController(title: "Changer l'image de profil", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Supprimer la photo", style: .destructive, handler: { (a) in
                self.removePhoto()
            }))
            alert.addAction(UIAlertAction(title: "Choisir une photo", style: .default, handler: { (a) in
                self.showPhotos()
            }))
            alert.addAction(UIAlertAction(title: "Annuler", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            showPhotos()
        }
    }
    
    func removePhoto(_ showAlert: Bool = true) {
        delPic(showAlert)
    }
    
    func removePhotoDisk(_ showAlert: Bool = true) {
        let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let filePath = documentsPath.appendingPathComponent("imageProfil.jpg")
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: filePath)
        } catch let error as NSError {
            if showAlert {
                let alert = UIAlertController(title: "Impossible de supprimer l'image",
                                              message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func showPhotos() {
        if (UI_USER_INTERFACE_IDIOM() == .pad)
        {
            let pop = UIImagePickerController()
            pop.sourceType = .photoLibrary
            pop.delegate = self
            let popOver = UIPopoverController(contentViewController: pop)
            popOver.present(from: tableView.emptyDataSetView.imageView.convert(tableView.emptyDataSetView.imageView.bounds, to: navigationController!.view), in: view, permittedArrowDirections: .any, animated: true)
        }
        else
        {
            let pop = UIImagePickerController()
            pop.sourceType = .photoLibrary
            pop.delegate = self
            present(pop, animated: true, completion: { 
                UIApplication.shared.statusBarStyle = .lightContent
            })
        }
    }
    
    
    // MARK: Upload
    
    func uploadPic(_ selectedImage: UIImage) {
        
        if let login = KeychainSwift().get("login"),
            let passw = KeychainSwift().get("passw") {
            let body = ["client": login,
                        "password": passw,
                        "hash": ("hmmmdaOUI42" + login + passw).sha256()]
            
            // Constantes
            let boundaryConstant  = "----------V2y2HZDDDFg03epSStjsqdbaKO0j1"
            let fileParamConstant = "file"
            let requestUrl = URL(string: Data.sharedData.phpURLs["addPic"]!)
            
            // Requête
            var request = URLRequest(url: requestUrl!)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.httpShouldHandleCookies = false
            request.timeoutInterval = 30
            request.httpMethod = "POST"
            
            // Début du formatage
            let contentType = "multipart/form-data; boundary=" + boundaryConstant
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            
            // Ajout des paramètres POST normaux (client, pass, hash)
            let httpBody = NSMutableData()
            for param in body {
                httpBody.append(("--" + boundaryConstant + "\r\n").data(using: String.Encoding.utf8)!)
                httpBody.append(("Content-Disposition: form-data; name=\"" + param.0.URLencode() + "\"\r\n\r\n").data(using: String.Encoding.utf8)!)
                httpBody.append((param.1.URLencode() + "\r\n").data(using: String.Encoding.utf8)!)
            }
            
            // Récupération de l'image JPEG sélectionnée, en ≈ 150×150
            let pic = selectedImage.scaleAndCrop(CGSize(width: imgSize, height: imgSize), retina: false, fit: false, opaque: true)
            if let imageData = UIImageJPEGRepresentation(pic, 1.0) {
                // Maintenant qu'on a l'image de type NSData, on la fout dans la requête
                httpBody.append(("--" + boundaryConstant + "\r\n").data(using: String.Encoding.utf8)!)
                httpBody.append(("Content-Disposition: form-data; name=\"" + fileParamConstant + "\"; filename=\"image.jpg\"\r\n").data(using: String.Encoding.utf8)!)
                httpBody.append("Content-Type: image/jpeg\r\n\r\n".data(using: String.Encoding.utf8)!)
                httpBody.append(imageData)
                httpBody.append("\r\n".data(using: String.Encoding.utf8)!)
                
                // On finit
                httpBody.append(("--" + boundaryConstant + "--\r\n").data(using: String.Encoding.utf8)!)
                request.httpBody = httpBody as Foundation.Data
                request.setValue(String(httpBody.length), forHTTPHeaderField: "Content-Length")
                
                // On envoie tout
                let defaultSession = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: .main)
                let dataTast = defaultSession.dataTask(with: request, completionHandler: { (data, resp, error) in
                    self.spin.startAnimating()
                    Data.sharedData.needsLoadingSpin(false)
                    do {
                        if let d = data {
                            let JSON = try JSONSerialization.jsonObject(with: d, options: []) as! [String: AnyObject]
                            if let status = JSON["status"] as? Int,
                                let cause = JSON["cause"] as? String {
                                if status == 1 {
                                    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
                                    let filePath = documentsPath.appendingPathComponent("imageProfil.jpg")
                                    try? imageData.write(to: URL(fileURLWithPath: filePath), options: [])
                                    self.reloadEmpty()
                                } else {
                                    let alert = UIAlertController(title: "Erreur lors de l'envoi de la photo",
                                                                  message: cause, preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                                    self.present(alert, animated: true, completion: nil)
                                }
                            } else {
                                let alert = UIAlertController(title: "Erreur lors de l'envoi de la photo",
                                                              message: "Impossible de lire la réponse du serveur", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            }
                        } else {
                            let alert = UIAlertController(title: "Erreur lors de l'envoi de la photo",
                                                          message: "Impossible d'analyser la réponse du serveur", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                    } catch {
                        let alert = UIAlertController(title: "Erreur lors de l'envoi de la photo",
                                                      message: "Impossible de récupérer la réponse du serveur", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    self.uploading = false
                }) 
                uploading = true
                spin.startAnimating()
                Data.sharedData.needsLoadingSpin(true)
                dataTast.resume()
            }
        }
    }

    func delPic(_ showAlert: Bool = true) {
        if let login = KeychainSwift().get("login"),
            let passw = KeychainSwift().get("passw") {
            let body = ["client": login,
                        "password": passw,
                        "hash": ("tucroixcketuvoiBaseDonneeSinusvidal" + login + passw).sha256()]
            Data.JSONRequest(Data.sharedData.phpURLs["delPic"]!, on: nil, post: body) { (JSON) in
                self.uploading = false
                if let json = JSON {
                    if let status = json["status"] as? Int,
                        let cause = json["cause"] as? String {
                        if status != -10 {
                            self.removePhotoDisk(showAlert)
                            self.reloadEmpty()
                        }
                        if status != 1 && showAlert {
                            let alert = UIAlertController(title: "Erreur lors de la demande de suppresion de la photo", message: cause, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                    } else if showAlert {
                        self.removePhotoDisk(showAlert)
                        self.reloadEmpty()
                        let alert = UIAlertController(title: "Erreur lors de la demande de suppresion de la photo", message: "Erreur serveur", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                } else {
                    self.removePhotoDisk(showAlert)
                    self.reloadEmpty()
                }
            }
            uploading = true
        }
    }
    
    
    // MARK: Image picker delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        uploadPic(image)
        
        reloadEmpty()
        
        dismiss(animated: true) {
            UIApplication.shared.statusBarStyle = .lightContent
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true) {
            UIApplication.shared.statusBarStyle = .lightContent
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return (Data.isConnected()) ? 0 : 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if Data.isConnected() {
            return 0
        } else if section == 1 {
            return 1
        }
        return 2
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 0 {
            connexion()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    // MARK: - Text Field delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if idField.isFirstResponder {
            return mdpField.becomeFirstResponder()
        } else {
            connexion()
        }
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text
        var proposedString: NSString = (text! as NSString).replacingCharacters(in: range, with: string) as NSString
        proposedString = proposedString.trimmingCharacters(in: .whitespaces) as NSString
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
            connexionCell.textLabel?.isEnabled = nouv
            connexionCell.selectionStyle = (nouv) ? .default : .none
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
        tableView.emptyDataSetView.imageView.isUserInteractionEnabled = true
        tableView.emptyDataSetView.imageView.addGestureRecognizer(tap)
        
        tableView.emptyDataSetView.imageView.layer.cornerRadius = CGFloat(imgSize / 2)
        tableView.emptyDataSetView.imageView.clipsToBounds = true
        tableView.emptyDataSetView.imageView.layer.borderWidth = 4
        tableView.emptyDataSetView.imageView.layer.borderColor = UIColor.white.cgColor
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        let documentsPath: NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let filePath = documentsPath.appendingPathComponent("imageProfil.jpg")
        if let data = try? Foundation.Data(contentsOf: URL(fileURLWithPath: filePath)) {
            return UIImage(data: data)
        }
        
        if UIScreen.main.bounds.size.height < 500 {
            return UIImage(named:"defaultUser")?.scaleAndCrop(CGSize(width: imgSize, height: imgSize), retina: false, fit: false, opaque: true)
        }
        return UIImage(named:"defaultUser")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Salut \(KeychainSwift().get("uname")!) !"
        let attrs = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18),
                     NSForegroundColorAttributeName: UIColor.darkGray]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17),
                     NSForegroundColorAttributeName: UINavigationBar.appearance().barTintColor!] as [String : Any]
        var string = "Choisir une photo"
        if Data.hasProfilePic() {
            string = "Modifier ma photo"
        }
        return NSAttributedString(string: string, attributes: attrs)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap didTapButton: UIButton!) {
        choosePhoto()
    }
}
