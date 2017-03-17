//
//  TableViewController.swift
//  CPLKeyboardManager
//
//  Created by Michal Zietera on 17.03.2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import CPLKeyboardManager

class TableViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITextViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var keyboardManager: CPLKeyboardManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        keyboardManager = CPLKeyboardManager(withTableView: tableView)
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        keyboardManager?.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        keyboardManager?.stop()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var reusableId: String
        let modulo = indexPath.row % 3
        if modulo == 0 {
            reusableId = "tableViewCellWithTextField"
        } else if modulo == 1 {
            reusableId = "tableViewCell"
        } else {
            reusableId = "tableViewCellWithTextView"
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: reusableId)!

        if modulo == 1 {
            cell.textLabel?.text = "Cell number \(indexPath.row)"
        } else {
           (cell as? TextViewTableViewCell)?.textView.delegate = self
        }
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 21
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
    }

    func textViewDidChange(_ textView: UITextView) {
        let currentOffset = tableView.contentOffset
        UIView.setAnimationsEnabled(false)
        tableView.beginUpdates()
        tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
        tableView.setContentOffset(currentOffset, animated: false)
    }
}
