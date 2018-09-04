//
//  WikiSearchHomeScreen.swift
//  MM Wiki
//
//  Created by CBH iOS on 01/09/18.
//  Copyright © 2018 MM Techie. All rights reserved.
//

import UIKit
import Alamofire
import SDWebImage
import SafariServices

class WikiSearchHomeScreen: UIViewController {

    let searchController = UISearchController(searchResultsController: nil)

    @IBOutlet weak var mTableView: UITableView!
    
    var mSearchResultsURLS =  Array<Any>()
    var mTableData =  Array<Any>()
    var isAPIGoingon = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchController()
    }

    func setupSearchController() {
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.barTintColor = UIColor(white: 0.9, alpha: 0.9)
        searchController.searchBar.placeholder = "Search in Wiki"
        searchController.hidesNavigationBarDuringPresentation = false
        
        self.mTableView.tableHeaderView = searchController.searchBar
    }

    func filterRowsForSearchedText(_ searchText: String) {
        self.isAPIGoingon = true
        //WikiSearchSuggestionAPIPath
        //.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        Alamofire.request((WikiSearchAPIPath + searchText.replacingOccurrences(of: " ", with: "%20"))).responseJSON { response in
            self.isAPIGoingon = false
            if (response.result.value != nil) {
                if let result = (response.result.value as? NSDictionary) {
                    if let query = (result.value(forKey: "query")  as? NSDictionary) {
                        if let pages = query.value(forKey: "pages") as? NSArray {
                            let pages_sort_index = NSSortDescriptor(key: "index", ascending: true)
                            let sorted_pages = pages.sortedArray(using: [pages_sort_index]) as NSArray
                            self.mTableData = sorted_pages as! [Any]
                            self.mTableView.reloadData()
                        }
                    }
                }
                else if let error = (response.result.value as? NSDictionary) {
                    print(error)
                }
                else {
                    print(response.result.value!)
                }
            }
            if (response.result.error != nil) {
                print(response.result.error!)
            }
        }
    }

}

extension WikiSearchHomeScreen: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mTableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ce = tableView.dequeueReusableCell(withIdentifier: "WikiTableCellId") as! WikiTableCell
        let single = self.mTableData[indexPath.row] as! NSDictionary
        ce.lblTitle.text = single.value(forKey: "title") as? String
        ce.lblSubTitle.text = ""
        ce.imgPic.image = #imageLiteral(resourceName: "Default User Profile Image")
        if (single.value(forKey: "terms") != nil) {
            let terms = single.value(forKey: "terms") as! NSDictionary
            if (terms.value(forKey: "description") != nil) {
                let description = terms.value(forKey: "description") as! NSArray
                if (description.count > 0) {
                    ce.lblSubTitle.text = description.firstObject as? String
                }
            }
        }
        if (single.value(forKey: "thumbnail") != nil) {
            let thumbnail = single.value(forKey: "thumbnail") as! NSDictionary
            ce.imgPic.sd_setImage(with: URL(string: thumbnail.value(forKey: "source") as! String), placeholderImage: #imageLiteral(resourceName: "Default User Profile Image"))
        }
        
        return ce
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let single = self.mTableData[indexPath.row] as! NSDictionary
        let pageid = single.value(forKey: "pageid") as! Int
        guard let url = URL(string: WikiPageWithIDAPIPath + String(pageid)) else {
            return //be safe
        }
        let svc =  SFSafariViewController.init(url: url)
        self.present(svc, animated: true) {
            
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

extension WikiSearchHomeScreen: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let term = searchController.searchBar.text {
            if (self.isAPIGoingon == false) {
                filterRowsForSearchedText(term)
            }
        }
    }
    
    
    
}

