//
//  MenuViewController.swift
//  CPLKeyboardManager
//
//  Created by Michał Ziętera on 03/17/2017.
//  Copyright (c) 2017 Michał Ziętera. All rights reserved.
//

import UIKit
import CPLKeyboardManager

class MenuViewController: UIViewController {

    weak var delegate: MenuViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func showTableView(_ sender: UIButton) {
        delegate?.tappedTableViewButton()
    }
}

