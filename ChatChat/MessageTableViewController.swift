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

class MessageTableViewController: UITableViewController {

    let rootReference = FIRDatabase.database().referenceFromURL("https://crowdamp-messaging.firebaseio.com")
    var conversationIdArray : [String] = []
    var conversationTitleArray : [String] = []
    var messageSnapshotArray : [FIRDataSnapshot] = []
    var conversationIndex = 0
    var dataManager = DataManager.sharedInstance
    var firebaseStoragePath = ""
    var vCTitle = ""
    
 
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(dataManager.influencerId)
        
        self.navigationController?.navigationBarHidden = false
        self.navigationItem.title = vCTitle
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
        return conversationIdArray.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        conversationIndex = indexPath.row
        performSegueWithIdentifier("SegueToConversation" , sender: self) //SegueToConversation
    }
    

    private func conversationQuery() {
        let ref = rootReference.child(dataManager.influencerId + "/" + firebaseStoragePath)
        let query = ref.queryLimitedToLast(50).queryOrderedByChild("timestamp")
        query.observeEventType(.ChildAdded) { (snapshot: FIRDataSnapshot!) in
            print(snapshot.key)
            print(snapshot.value!["timestamp"])
            self.messageSnapshotArray.insert(snapshot, atIndex: 0)
            self.conversationIdArray.insert(snapshot.key, atIndex: 0)

            if let conversationName : String = snapshot.value?["conversationTitle"] as? String {
                self.conversationTitleArray.insert(conversationName, atIndex:  0)
            } else {
                self.conversationTitleArray.insert(snapshot.key, atIndex:  0)

            }
            print(snapshot.key)
            self.tableView.reloadData()
        }
        
        query.observeEventType(.ChildChanged) { (snapshot: FIRDataSnapshot!) in
            print(snapshot.key)
            print(snapshot.value!["timestamp"])
            let index = self.conversationIdArray.indexOf(snapshot.key)
            self.conversationIdArray.removeAtIndex(index!)
            self.conversationIdArray.insert(snapshot.key, atIndex: 0)
            self.conversationTitleArray.removeAtIndex(index!)
            self.messageSnapshotArray.removeAtIndex(index!)
            self.messageSnapshotArray.insert(snapshot, atIndex: 0)

            if let conversationName : String = snapshot.value?["conversationTitle"] as? String {
                self.conversationTitleArray.insert(conversationName, atIndex:  0)
            } else {
                self.conversationTitleArray.insert(snapshot.key, atIndex:  0)
                
            }
            print(snapshot.key)
            self.tableView.reloadData()
        }
    }
    
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCellWithIdentifier("messageCell") as! MessageTableViewCell
        cell.snapshot = self.messageSnapshotArray[indexPath.row]
        return cell
        
        
//        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
//        print(conversationTitleArray)
//        cell.textLabel?.text = self.conversationTitleArray[indexPath.row]
//        
//        return cell
    }
    
    

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //super.prepareForSegue(segue, sender: sender)
        let chatVc = segue.destinationViewController as! ChatViewController // 1
        chatVc.senderId = conversationIdArray[conversationIndex]
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

extension RangeReplaceableCollectionType where Generator.Element : Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func removeObject(object : Generator.Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
}
