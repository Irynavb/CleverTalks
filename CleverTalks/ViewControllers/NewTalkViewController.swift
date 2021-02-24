//
//  NewTalkViewController.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 9/29/20.
//

import Anchorage
import JGProgressHUD

class NewTalkViewController: UIViewController {

    public var completion: ((SearchResult) -> (Void))?

    private let spinner = JGProgressHUD(style: .dark)

    private var users = [[String: String]]()

    private var results = [SearchResult]()

    private var hasFetched = false

    private let searchBar = UISearchBar().then {
        $0.placeholder = "Search for contacts"
    }

    private let tableView = UITableView().then {
        $0.register(NewTalkCell.self, forCellReuseIdentifier: NewTalkCell.identifier)
        $0.isHidden = true
    }

    private let noUsersFoundLabel = UILabel().then {
        $0.text = "No Results"
        $0.textAlignment = .center
        $0.textColor = .darkBrown
        $0.font = .systemFont(ofSize: 18, weight: .medium)
        $0.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        view.addSubview(noUsersFoundLabel)

        tableView.delegate = self
        tableView.dataSource = self

        searchBar.delegate = self

        view.backgroundColor = .systemBackground

        navigationController?.navigationBar.topItem?.titleView = searchBar

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))

        searchBar.becomeFirstResponder()

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds

        noUsersFoundLabel.centerAnchors == view.centerAnchors
    }

    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
}

extension NewTalkViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewTalkCell.identifier, for: indexPath) as! NewTalkCell
        cell.configure(with: model)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // start a talk
        let targetUserData = results[indexPath.row]

        dismiss(animated: true, completion: { [weak self] in
            self?.completion?(targetUserData)
        })

    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }

}

extension NewTalkViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }

        searchBar.resignFirstResponder()

        results.removeAll()

        spinner.show(in: view)

        searchUsers(query: text)
    }

    func searchUsers(query: String) {

        // check if the array of users has already Firebase results
        if hasFetched {
            // if it does, then filter
            filterUsers(with: query)
        }
        else {
            // if it does NOT, then FIRST fetch, then filter
            DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                switch result {
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("failed to get users \(error)")
                }
            })
        }




        // update the UI to either display the results or not
    }

    func filterUsers(with term: String) {
        // update the UI: eitehr show results or show no results label
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String, hasFetched else {
            return
        }

        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)

        self.spinner.dismiss()

        let results: [SearchResult] = users.filter({
            guard let email = $0["email"], email != safeEmail else {
                return false
            }

            guard let name = $0["name"]?.lowercased() else {
                return false
            }

            return name.hasPrefix(term.lowercased())
        }).compactMap({

            guard let email = $0["email"],
                let name = $0["name"] else {
                return nil
            }

            return SearchResult(name: name, email: email)
        })

        self.results = results

        updateUI()
    }

    func updateUI() {
        if results.isEmpty {
            self.noUsersFoundLabel.isHidden = false
            self.tableView.isHidden = true
        }
        else {
            self.noUsersFoundLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }

}
