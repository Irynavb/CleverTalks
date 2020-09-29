//
//  TalksViewController.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 9/28/20.
//

import Anchorage
import FirebaseAuth
import JGProgressHUD

class TalksViewController: UIViewController {

    private let spinner = JGProgressHUD(style: .dark)

    private let tableView = UITableView().then {
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        $0.isHidden = true
    }

    private let noTalksLabel = UILabel().then {
        $0.text = "You do not have any talks yet"
        $0.textAlignment = .center
        $0.textColor = .darkBrown
        $0.font = .systemFont(ofSize: 21, weight: .medium)
        $0.isHidden = true
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(composeButtonTapped))
        view.backgroundColor = .backgroundLightGreen

        view.addSubview(tableView)
        view.addSubview(noTalksLabel)

        tableView.delegate = self
        tableView.dataSource = self

        fetchTalks()

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(animated)

        validateAuth()

    }

    private func validateAuth() {
        if  FirebaseAuth.Auth.auth().currentUser == nil {

            let vc = SignInViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)

        }
    }

    private func fetchTalks() {
        tableView.isHidden = false
    }

    @objc private func composeButtonTapped() {
        let vc = NewTalkViewController()
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
}

extension TalksViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Hello there!"
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let vc = SingleTalkViewController()
        vc.title = "Cookie Cook"
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }

}

