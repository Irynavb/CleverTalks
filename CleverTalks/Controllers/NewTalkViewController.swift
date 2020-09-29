//
//  NewTalkViewController.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 9/29/20.
//

import UIKit
import JGProgressHUD

class NewTalkViewController: UIViewController {

    private let spinner = JGProgressHUD()

    private let searchBar = UISearchBar().then {
        $0.placeholder = "Search for contacts"
    }

    private let tableView = UITableView().then {
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        $0.isHidden = true
    }

    private let noUsersFoundLabel = UILabel().then {
        $0.text = "No Results"
        $0.textAlignment = .center
        $0.textColor = .darkBrown
        $0.font = .systemFont(ofSize: 18, weight: .medium)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self

        view.backgroundColor = .backgroundLightGreen

        navigationController?.navigationBar.topItem?.titleView = searchBar

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))

        searchBar.becomeFirstResponder()

    }
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
}

extension NewTalkViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
    }
}
