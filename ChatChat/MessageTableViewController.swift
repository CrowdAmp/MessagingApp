//
//  MessageTableViewController.swift
//  ChatChat
//
//  Created by Ruben Mayer on 6/14/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import Haneke
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class MessageTableViewController: UITableViewController {
    
    let rootReference = FIRDatabase.database().reference(fromURL: "https://crowdamp-messaging.firebaseio.com")
    // var conversationIdArray : [String] = []
    //var conversationTitleArray : [String] = []
    var messageSnapshotArray : [FIRDataSnapshot] = []
    var conversationItemDataArray : [ConversationItemData] = []
    var conversationIndex = 0
    var dataManager = DataManager.sharedInstance
    var firebaseStoragePath = ""
    var vCTitle = ""
    let cache = Shared.dataCache
    var lastTableUpdate : Date?
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lastTableUpdate = Date()
        print(dataManager.influencerId)
        
        self.navigationController?.isNavigationBarHidden = false
        self.navigationItem.title = vCTitle
        
        self.navigationController?.navigationBar.barTintColor = UIColor(netHex: darkBlueColor)
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        
        conversationQuery()
        
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return conversationItemDataArray.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        conversationIndex = (indexPath as NSIndexPath).row
        performSegue(withIdentifier: "SegueToConversation" , sender: self) //SegueToConversation
    }
    
    
    
    
    fileprivate func conversationQuery() {
        let ref = rootReference.child(dataManager.influencerId + "/" + firebaseStoragePath)
        let query = ref.queryLimited(toLast: 50).queryOrdered(byChild: "timestamp")
        var conversationItemDataArrayBuffer : [ConversationItemData] = []
        
        query.observe(.childAdded) { (snapshot: FIRDataSnapshot!) in
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async{
                
                conversationItemDataArrayBuffer.insert(ConversationItemData(snapshot: snapshot), at: 0)
                
                
                if self.conversationItemDataArray.count <= conversationItemDataArrayBuffer.count{
                    self.conversationItemDataArray = conversationItemDataArrayBuffer
                    var i = 0 // PROBLEM
                    for item in self.conversationItemDataArray {
                        if item.timestamp == nil {
                            self.conversationItemDataArray.remove(at: i)
                        }
                        i += 1
                        
                    }
                    
                    if self.conversationItemDataArray.count > 40 { // PROBLEM
                        //self.conversationItemDataArray.sortInPlace({ $0.timestamp > $1.timestamp })
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
        
        query.observe(.childChanged) { (snapshot: FIRDataSnapshot!) in
            
            print(snapshot.key)
            if let index = self.conversationItemDataArray.index(where: {$0.itemId == snapshot.key}) {
                self.conversationItemDataArray.remove(at: index)
            } else {
                if (self.conversationItemDataArray.count > 40) {
                    self.conversationItemDataArray.removeLast()
                }
            }
            self.conversationItemDataArray.insert(ConversationItemData(snapshot: snapshot), at: 0)
            self.conversationItemDataArray.sort(by: { $0.timestamp > $1.timestamp })
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    
    // Not used
    func loadCachedData() {
        cache.fetch(key: self.vCTitle + "conversationItemDataArray").onSuccess { conversationItemDataArrayData in
            self.conversationItemDataArray = NSKeyedUnarchiver.unarchiveObject(with: conversationItemDataArrayData) as! [ConversationItemData]
            self.tableView.reloadData()
        }
    }
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "messageCell") as! MessageTableViewCell
        if ((indexPath as NSIndexPath).row < conversationItemDataArray.count) {
            cell.conversationItemData = self.conversationItemDataArray[(indexPath as NSIndexPath).row]
        } else {
            print((indexPath as NSIndexPath).row)
        }
        return cell
        
        
        //        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        //        print(conversationTitleArray)
        //        cell.textLabel?.text = self.conversationTitleArray[indexPath.row]
        //
        //        return cell
    }
    
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        let chatVc = segue.destination as! ChatViewController // 1
        print(conversationItemDataArray.count)
        print(conversationItemDataArray[conversationIndex])
        chatVc.senderId = conversationItemDataArray[conversationIndex].itemId!
        print(firebaseStoragePath)
        chatVc.firebaseContainerRefferenceName = firebaseStoragePath
        chatVc.senderDisplayName = "Test"
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
     if editingStyle == .Delete {
     // Delete the row from the data source
     tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
     } else if editingStyle == .Insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}

class ConversationItemData: NSObject {
    var itemTitle : String?
    var itemText : String?
    var itemRead : Bool?
    var itemId : String?
    var timestamp : Int?
    
    let dataManager = DataManager.sharedInstance
    
    init (snapshot: FIRDataSnapshot) {
        
        var snap : AnyObject?
        for i in 0..<Int(snapshot.childrenCount){
            if (snapshot.children.allObjects[i] as AnyObject).key[0] != "-" {
                break
            } else {
                snap = snapshot.children.allObjects[i] as AnyObject?
            }
        }
        
        if let unwrappedSnapshot : AnyObject = snap {
            if let snapshotText = unwrappedSnapshot.value?["text"] as? String{
                itemText = snapshotText
            } else {
                itemText = "Image Sent"
            }
            
        }
        if let name : String = snapshot.value?["conversationTitle"] as? String{
            itemTitle = name
        } else {
            var nameLabelText = snapshot.key
            if nameLabelText.characters.count == 12 {
                nameLabelText = "(" + nameLabelText[2...4] + ") " + nameLabelText[5...7] + "-" + nameLabelText[8...11]
            }
            itemTitle = nameLabelText
        }
        
        itemId = snapshot.key
        timestamp = snapshot.value?["timestamp"] as? Int
        var didReadKey = "influencerDidRead"
        if dataManager.isUser {
            didReadKey = "userDidRead"
        }
        
        if let didRead : Bool = snapshot.value?[didReadKey] as? Bool {
            itemRead = didRead
        } else {
            itemRead = true
        }
        
    }
    
    
    func encodeWithCoder(_ archiver: NSCoder) {
        archiver.encode(itemTitle, forKey: "itemTitle")
        archiver.encode(itemText, forKey: "itemText")
        archiver.encode(itemRead, forKey: "itemRead")
        archiver.encode(itemId, forKey: "itemId")
        // archiver.encodeObject(timestamp, forKey: "timestamp")
        
        
    }
    
    required init(coder unarchiver: NSCoder) {
        super.init()
        itemTitle = unarchiver.decodeObject(forKey: "itemTitle") as? String
        itemText = unarchiver.decodeObject(forKey: "itemText") as? String
        itemRead = unarchiver.decodeObject(forKey: "itemRead") as? Bool
        itemId = unarchiver.decodeObject(forKey: "itemId") as? String
        //timestamp = unarchiver.decodeObjectForKey("timestamp") as! String
        
        
        
        
    }
    
}

extension RangeReplaceableCollection where Iterator.Element : Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func removeObject(_ object : Iterator.Element) {
        if let index = self.index(of: object) {
            self.remove(at: index)
        }
    }
}

extension Date {
    func yearsFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.year, from: date, to: self, options: []).year!
    }
    func monthsFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.month, from: date, to: self, options: []).month!
    }
    func weeksFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.weekOfYear, from: date, to: self, options: []).weekOfYear!
    }
    func daysFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.day, from: date, to: self, options: []).day!
    }
    func hoursFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.hour, from: date, to: self, options: []).hour!
    }
    func minutesFrom(_ date: Date) -> Int{
        return (Calendar.current as NSCalendar).components(.minute, from: date, to: self, options: []).minute!
    }
    func secondsFrom(_ date: Date) -> Int{
        return (Calendar.current as NSCalendar).components(.second, from: date, to: self, options: []).second!
    }
    func offsetFrom(_ date: Date) -> String {
        if yearsFrom(date)   > 0 { return "\(yearsFrom(date))y"   }
        if monthsFrom(date)  > 0 { return "\(monthsFrom(date))M"  }
        if weeksFrom(date)   > 0 { return "\(weeksFrom(date))w"   }
        if daysFrom(date)    > 0 { return "\(daysFrom(date))d"    }
        if hoursFrom(date)   > 0 { return "\(hoursFrom(date))h"   }
        if minutesFrom(date) > 0 { return "\(minutesFrom(date))m" }
        if secondsFrom(date) > 0 { return "\(secondsFrom(date))s" }
        return ""
    }
}

