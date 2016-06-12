//
//  ViewController.swift
//  FBtest
//
//  Created by Alex Nako on 5/19/16.
//  Copyright © 2016 Alex Nako. All rights reserved.
//

import UIKit
import Firebase
import Foundation

class HomeController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var ref = FIRDatabaseReference.init()
    var items = [FIRDataSnapshot]()
    var tags = [String]()
    var filteredTags = [String]()

    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var quoteList: UITableView!
    @IBOutlet weak var tagCollection: UICollectionView!
    
    var sizingCell: TagCell?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        quoteList.delegate = self
        quoteList.dataSource = self
        searchField.delegate = self
        tagCollection.dataSource = self
        tagCollection.delegate = self
        
        // REGISTERING TAGCELL.XIB AS NIB
        let cellNib = UINib(nibName: "TagCell", bundle: nil)
        self.tagCollection.registerNib(cellNib, forCellWithReuseIdentifier: "TagCell")
        self.tagCollection.backgroundColor = UIColor.clearColor()
        self.sizingCell = (cellNib.instantiateWithOwner(nil, options: nil) as NSArray).firstObject as! TagCell?
        
        // FIREBASE
        ref = FIRDatabase.database().reference()
        

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        allQuotes()
        tagsFetch()
    }

    // TAG FLOW COLLECTION VIEW
    func collectionView(tagCollection: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredTags.count
    }
    func collectionView(tagCollection: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = tagCollection.dequeueReusableCellWithReuseIdentifier("TagCell", forIndexPath: indexPath) as! TagCell
        cell.tagName.text = filteredTags[indexPath.row]
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.whiteColor()
        cell.selectedBackgroundView = bgColorView
        
        return cell
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        self.configureCell(self.sizingCell!, forIndexPath: indexPath)
        return self.sizingCell!.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
    }
    func configureCell(cell: TagCell, forIndexPath indexPath: NSIndexPath) {
        let tag = filteredTags[indexPath.row]
        cell.tagName.text = tag
        cell.tagName.textColor = cell.selected ? UIColor.whiteColor() : UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        cell.backgroundColor = cell.selected ? UIColor(red: 0, green: 1, blue: 0, alpha: 1) : UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
    }
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

//        let selectedCell = tagCollection.cellForItemAtIndexPath(indexPath)!
//        selectedCell.backgroundColor = UIColor.purpleColor()
//        tagCollection.deselectItemAtIndexPath(indexPath, animated: true)

        
        
//        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? TagCell {
//            cell.toggleSelectedState()
//        }
//
        let tag = filteredTags[indexPath.row]
//        print(tag)
        filteredTagQuotes(tag)
        
//        self.tagCollection.reloadData()
    }

    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        allQuotes()
    }
    
    // FETCH ALL TAGS AND CREATE ARRAY FOR FLOW COLLECTION
    func tagsFetch () {
        ref.child("tags").observeSingleEventOfType(.Value, withBlock: { (snapshot: FIRDataSnapshot!) in
            for item in snapshot.children {
                self.tags.append(item.key as String)
            }
            self.filteredTags = self.tags
            self.tagCollection.reloadData()
            }, withCancelBlock: { error in
                print(error.description)
        })
    }

    // TAG SEARCH
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if string == " " {
            filteredTags = tags
            tagCollection.reloadData()
            return false
        }
        let userEnteredString = textField.text
        let newString = (userEnteredString! as NSString).stringByReplacingCharactersInRange(range, withString: string) as NSString
        if newString.length > 3 {
            filteredTags = tags.filter { $0.containsString(newString as String) }
            if filteredTags.isEmpty {
            
            } else {
                tagCollection.reloadData()
            }
        }
        if newString.length < 1 {
            filteredTags = tags
            tagCollection.reloadData()
        }
        return true
    }
    
    // FETCH ALL QUOTES
    func allQuotes () {
        ref.child("quotes").observeSingleEventOfType(.Value, withBlock: { (snapshot: FIRDataSnapshot!) in
            for item in snapshot.children {
                self.items.append(item as! FIRDataSnapshot)
            }
            self.quoteList.reloadData()
            
            }, withCancelBlock: { error in
                print(error.description)
        })
    }

    // FILTER QUOTES BY AUTHOR
    func filteredAuthorQuotes (author: String) {
        ref.child("quotes").queryOrderedByChild(author).queryEqualToValue("A. A. Milne").observeSingleEventOfType(.Value, withBlock: { (snapshot: FIRDataSnapshot!) in

            for item in snapshot.children {
                self.items.append(item as! FIRDataSnapshot)
            }
            self.quoteList.reloadData()
            }, withCancelBlock: { error in
                print(error.description)
        })
    }

    // FILTER QUOTES BY TAGS
    func filteredTagQuotes (tag: String) {
        self.items.removeAll()
        ref.child("quotes").removeAllObservers()
        
        ref.child("quotes").queryOrderedByChild("tags/\(tag)").queryEqualToValue(true).observeSingleEventOfType(.Value, withBlock: { (snapshot: FIRDataSnapshot!) in
            self.items.removeAll()

            for item in snapshot.children {
                self.items.append(item as! FIRDataSnapshot)
            }
            
            dispatch_async(dispatch_get_main_queue(), { self.quoteList.reloadData() })

            
            }, withCancelBlock: { error in
                print(error.description)
        })
    }
    
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cel:QuoteCell = tableView.dequeueReusableCellWithIdentifier("QuoteCell", forIndexPath: indexPath) as! QuoteCell
        cel.label1.text = items[indexPath.row].value!["quote"] as? String
        return cel
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

