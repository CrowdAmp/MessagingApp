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

class MessageTableViewController: UITableViewController {
    
    let rootReference = FIRDatabase.database().referenceFromURL("https://crowdamp-messaging.firebaseio.com")
    // var conversationIdArray : [String] = []
    //var conversationTitleArray : [String] = []
    var messageSnapshotArray : [FIRDataSnapshot] = []
    var conversationItemDataArray : [ConversationItemData] = []
    var conversationIndex = 0
    var dataManager = DataManager.sharedInstance
    var firebaseStoragePath = ""
    var vCTitle = ""
    let cache = Shared.dataCache
    var lastTableUpdate : NSDate?
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lastTableUpdate = NSDate()
        //FIRDatabase.database().persistenceEnabled = true
        print(dataManager.influencerId)
        
        self.navigationController?.navigationBarHidden = false
        self.navigationItem.title = vCTitle
        //loadCachedData()
        
        self.navigationController?.navigationBar.barTintColor = UIColor(netHex: darkBlueColor)
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        
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
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return conversationItemDataArray.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        conversationIndex = indexPath.row
        performSegueWithIdentifier("SegueToConversation" , sender: self) //SegueToConversation
    }
    
    
    
    
    private func conversationQuery() {
        let ref = rootReference.child(dataManager.influencerId + "/" + firebaseStoragePath)
        let query = ref.queryLimitedToLast(50).queryOrderedByChild("timestamp")
        var conversationItemDataArrayBuffer : [ConversationItemData] = []
        
        query.observeEventType(.ChildAdded) { (snapshot: FIRDataSnapshot!) in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
                
                conversationItemDataArrayBuffer.insert(ConversationItemData(snapshot: snapshot), atIndex: 0)
                
                
                if self.conversationItemDataArray.count <= conversationItemDataArrayBuffer.count{
                    self.conversationItemDataArray = conversationItemDataArrayBuffer
                    var i = 0 // PROBLEM
                    for item in self.conversationItemDataArray {
                        if item.timestamp == nil {
                            self.conversationItemDataArray.removeAtIndex(i)
                        }
                        i += 1
                        
                    }
                    
                    if self.conversationItemDataArray.count > 40 { // PROBLEM
                        self.conversationItemDataArray.sortInPlace({ $0.timestamp > $1.timestamp })
                    }
                    self.cache.set(value: NSKeyedArchiver.archivedDataWithRootObject(Array(self.conversationItemDataArray)), key: self.vCTitle + "conversationItemDataArray")
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                    }
                }
            }
        }
        
        query.observeEventType(.ChildChanged) { (snapshot: FIRDataSnapshot!) in
            
            print(snapshot.key)
            if let index = self.conversationItemDataArray.indexOf({$0.itemId == snapshot.key}) {
                self.conversationItemDataArray.removeAtIndex(index)
            } else {
                if (self.conversationItemDataArray.count > 40) {
                    self.conversationItemDataArray.removeLast()
                }
            }
            self.conversationItemDataArray.insert(ConversationItemData(snapshot: snapshot), atIndex: 0)
            self.conversationItemDataArray.sortInPlace({ $0.timestamp > $1.timestamp })
            self.cache.set(value: NSKeyedArchiver.archivedDataWithRootObject(Array(self.conversationItemDataArray)), key: self.vCTitle + "conversationItemDataArray")
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
        }
    }
    
    
    
    func loadCachedData() {
        cache.fetch(key: self.vCTitle + "conversationItemDataArray").onSuccess { conversationItemDataArrayData in
            self.conversationItemDataArray = NSKeyedUnarchiver.unarchiveObjectWithData(conversationItemDataArrayData) as! [ConversationItemData]
            self.tableView.reloadData()
        }
    }
    
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCellWithIdentifier("messageCell") as! MessageTableViewCell
        if (indexPath.row < conversationItemDataArray.count) {
            cell.conversationItemData = self.conversationItemDataArray[indexPath.row]
        } else {
            print(indexPath.row)
        }
        return cell
        
        
        //        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        //        print(conversationTitleArray)
        //        cell.textLabel?.text = self.conversationTitleArray[indexPath.row]
        //
        //        return cell
    }
    
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        let chatVc = segue.destinationViewController as! ChatViewController // 1
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
            if snapshot.children.allObjects[i].key[0] != "-" {
                break
            } else {
                snap = snapshot.children.allObjects[i]
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
    
    
    func encodeWithCoder(archiver: NSCoder) {
        archiver.encodeObject(itemTitle, forKey: "itemTitle")
        archiver.encodeObject(itemText, forKey: "itemText")
        archiver.encodeObject(itemRead, forKey: "itemRead")
        archiver.encodeObject(itemId, forKey: "itemId")
        // archiver.encodeObject(timestamp, forKey: "timestamp")
        
        
    }
    
    required init(coder unarchiver: NSCoder) {
        super.init()
        itemTitle = unarchiver.decodeObjectForKey("itemTitle") as? String
        itemText = unarchiver.decodeObjectForKey("itemText") as? String
        itemRead = unarchiver.decodeObjectForKey("itemRead") as? Bool
        itemId = unarchiver.decodeObjectForKey("itemId") as? String
        //timestamp = unarchiver.decodeObjectForKey("timestamp") as! String
        
        
        
        
    }
    
}

extension RangeReplaceableCollectionType where Generator.Element : Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func removeObject(object : Generator.Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
}

extension NSDate {
    func yearsFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.Year, fromDate: date, toDate: self, options: []).year
    }
    func monthsFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.Month, fromDate: date, toDate: self, options: []).month
    }
    func weeksFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.WeekOfYear, fromDate: date, toDate: self, options: []).weekOfYear
    }
    func daysFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.Day, fromDate: date, toDate: self, options: []).day
    }
    func hoursFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.Hour, fromDate: date, toDate: self, options: []).hour
    }
    func minutesFrom(date: NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Minute, fromDate: date, toDate: self, options: []).minute
    }
    func secondsFrom(date: NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Second, fromDate: date, toDate: self, options: []).second
    }
    func offsetFrom(date: NSDate) -> String {
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

