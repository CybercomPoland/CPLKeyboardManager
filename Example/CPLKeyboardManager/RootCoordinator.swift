//
//  RootCoordinator.swift
//  CPLKeyboardManager
//
//  Created by Michal Zietera on 17.03.2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

class RootCoordinator: MenuViewControllerDelegate {
    let navigationController: UINavigationController
    let storyboard = UIStoryboard(name: "Main", bundle: nil)

    init(withNavigationController navCon: UINavigationController) {
        navigationController = navCon
    }

    func tappedTableViewButton() {
        let tableVC = storyboard.instantiateViewController(withIdentifier: "TableViewController")
        let navCon = UINavigationController(rootViewController: tableVC)
        tableVC.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismiss))
        navigationController.present(navCon, animated: true, completion: nil)
    }

    func tappedScrollViewButton() {
        let scrollVC = storyboard.instantiateViewController(withIdentifier: "ScrollViewController")
        let navCon = UINavigationController(rootViewController: scrollVC)
        scrollVC.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismiss))
        navigationController.present(navCon, animated: true, completion: nil)
    }

    func tappedBottomConstraintButton() {
        let scrollVC = storyboard.instantiateViewController(withIdentifier: "ConstraintViewController")
        let navCon = UINavigationController(rootViewController: scrollVC)
        scrollVC.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismiss))
        navigationController.present(navCon, animated: true, completion: nil)
    }

    @objc func dismiss() {
        navigationController.dismiss(animated: true, completion: nil)
    }
}
