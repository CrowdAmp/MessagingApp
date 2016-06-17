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

    let rootReference = FIRDatabase.database().referenceFromURL("https://project-5770689541369228207.firebaseio.com/")
    var conversationIdArray : [String] = []
    var conversationIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        let ref = rootReference
        let query = ref.queryLimitedToLast(500)
        query.observeEventType(.ChildAdded) { (snapshot: FIRDataSnapshot!) in
            print(snapshot.key)
            self.conversationIdArray.append(snapshot.key)
            print(snapshot.key)
            self.tableView.reloadData()
        }
    }
    
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        
        cell.textLabel?.text = self.conversationIdArray[indexPath.row]
        
        return cell
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //super.prepareForSegue(segue, sender: sender)
        let chatVc = segue.destinationViewController as! ChatViewController // 1
        chatVc.senderId = conversationIdArray[conversationIndex]
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
