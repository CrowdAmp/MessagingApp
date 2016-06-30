//
//  MessageTableViewCell.swift
//  ChatChat
//
//  Created by Ruben Mayer on 6/28/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import AFDateHelper

class MessageTableViewCell: UITableViewCell {

    let dataManager = DataManager.sharedInstance
    var snapshot: FIRDataSnapshot? {
        didSet {
            updateUI()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateUI() {
        
        var snap : AnyObject?
        for i in 0..<Int(snapshot!.childrenCount){
            if snapshot!.children.allObjects[i].key[0] != "-" {
                break
            } else {
               snap = snapshot!.children.allObjects[i]
            }
        }
        
        if let snapshotForLastMessage : AnyObject = snap {
            print(snapshotForLastMessage)
            if let snapshotText = snapshotForLastMessage.value?["text"] as? String{
                messageContentLabel.text = snapshotText
            }
            
            if let name : String = snapshot!.value?["conversationTitle"] as? String{
                nameLabel.text = name
            } else {
                var nameLabelText = snapshot!.key 
                if nameLabelText.characters.count == 12 {
                    nameLabelText = "(" + nameLabelText[2...4] + ") " + nameLabelText[5...7] + "-" + nameLabelText[8...11]
                }
                nameLabel.text = nameLabelText
            }
            
            var didReadKey = "influencerDidRead"
            if dataManager.isUser {
                didReadKey = "userDidRead"
            }
            
            if let didRead : Bool = snapshot!.value?[didReadKey] as? Bool {
                if didRead {
                    self.backgroundColor = UIColor.whiteColor()
                    dateLabel.text = "Read"
                } else {
                    self.backgroundColor = UIColor(netHex:0xCFDEEA)
                    dateLabel.text = "Unread"
                    
                }
            }
        }

        
    }
    

    
    @IBOutlet weak var messageContentLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}

extension String {
    
    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = startIndex.advancedBy(r.startIndex)
        let end = start.advancedBy(r.endIndex - r.startIndex)
        return self[Range(start ..< end)]
    }
}
