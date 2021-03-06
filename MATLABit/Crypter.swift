//
//  Crypter.swift
//  MATLABit
//
//  Created by Thomas Naudet on 07/04/16.
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

class Crypter: UITableViewController, UITextFieldDelegate {

    @IBOutlet var inField: UITextField!
    @IBOutlet var keyField: UITextField!
    @IBOutlet var outField: UITextField!
    @IBOutlet var btnChiffrer: UIButton!
    @IBOutlet var btnDechiffrer: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard #available(iOS 9.1, *) else {
            btnChiffrer.setTitle("Chiffrer", for: UIControlState())
            btnDechiffrer.setTitle("Déchiffrer", for: UIControlState())
            return
        }
    }
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if outField.text == "" {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        let menuPartage = UIActivityViewController(activityItems: [outField.text!], applicationActivities: nil)
        menuPartage.title = "Partager le message chiffré"
        menuPartage.excludedActivityTypes = [UIActivityType.addToReadingList]
        
        if let pop = menuPartage.popoverPresentationController {
            pop.sourceView = tableView
            pop.sourceRect = tableView.cellForRow(at: indexPath)!.frame
            pop.permittedArrowDirections = .up
        }
        
        present(menuPartage, animated: true) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    
    // MARK: - Text Field delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var text1 = inField.text
        var text2 = keyField.text
        let text = textField.text
        let newText = (text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField == inField {
            text1 = newText
        }
        else {
            text2 = newText
        }
        
        let hex = "[0-9a-fA-F]+"
        let isHex = NSPredicate(format: "SELF MATCHES %@", hex)
        
        btnChiffrer.isEnabled   = text1 != "" && text2 != ""
        btnDechiffrer.isEnabled = isHex.evaluate(with: text1) && text2 != ""
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if inField.isFirstResponder {
            keyField.becomeFirstResponder()
        }
        else {
            keyField.resignFirstResponder()
        }
        return false;
    }
    
    
    // MARK: - Chiffrement niveau zéro
    
    @IBAction func chiffrer() {
        inField.resignFirstResponder()
        keyField.resignFirstResponder()
        
        let in16 = Array(inField.text!.utf16)
        let ke16 = Array(keyField.text!.utf16)
        
        var j = 0
        var result = ""
        
        for inChar in in16 {
            let res = inChar ^ ke16[j]
            result += String(format: "%04X", res)
            
            j += 1
            if j == ke16.count {
                j = 0
            }
        }
        
        outField.text = result.trimmingCharacters(in: .whitespaces)
    }
    
    @IBAction func dechiffrer() {
        inField.resignFirstResponder()
        keyField.resignFirstResponder()
        
        let original = inField.text!
        let nbrChar = original.characters.count / 4
        let ke16 = Array(keyField.text!.utf16)
        
        var j = 0
        var result = Array<UInt16>()
        
        for i in 0 ..< nbrChar {
            let range = original.characters.index(original.startIndex, offsetBy: i * 4) ..< original.characters.index(original.startIndex, offsetBy: (i * 4) + 4)
            let hexPart = original.substring(with: range)
            
            var originalChar: UInt32 = 0
            let scanner = Scanner(string: hexPart)
            scanner.scanHexInt32(&originalChar)
            
            let res = UInt16(originalChar) ^ ke16[j]
            result.append(res)
            
            j += 1
            if j == ke16.count {
                j = 0
            }
        }
        
        let final = String(utf16CodeUnits: result, count: result.count)
        outField.text = final.trimmingCharacters(in: .whitespaces)
    }
}
