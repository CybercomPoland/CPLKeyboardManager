//
//  TableViewController.swift
//  CPLKeyboardManager
//
//  Created by Michal Zietera on 17.03.2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import CPLKeyboardManager

private enum CellProperties: Int {
    case TextField = 0
    case Label
    case TextView

    func getHeight() -> CGFloat {
        switch self {
        case .TextField, .Label:
            return 44
        case .TextView:
            return 220
        }
    }

    func reuseId() -> String {
        switch self {
        case .TextField:
            return "tableViewCellWithTextField"
        case .Label:
            return "tableViewCell"
        case .TextView:
            return "tableViewCellWithTextView"
        }
    }
}

class TableViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var keyboardManager: CPLKeyboardManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        keyboardManager = CPLKeyboardManager(tableView: tableView, inViewController: self)
        tableView.delegate = self
       // tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardManager?.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardManager?.stop()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        //tableView.rowHeight = UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableViewAutomaticDimension
        let modulo = indexPath.row % 3

        return CellProperties(rawValue: modulo)?.getHeight() ?? 44.0
//        if modulo == 0 {
//            return 44.0
//        } else if modulo == 1 {
//            return 44.0
//        } else if modulo == 2 {
//            return 200.0
//        }
//        return 44.0
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
            cell.textLabel?.text = "Cell number \(indexPath.row) sdkjsak sajd kakdkaskd kaksdkaskdkak dkakdak kdakaks kakk dkaskdkasdk kk kaskdka kdkas kdakskask kas "
        } else {
           (cell as? TextViewTableViewCell)?.textView.delegate = self
        }
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 22
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
