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

    private var talks = [Talk]()

    private let tableView = UITableView().then {
        $0.register(SingleTalkTableViewCell.self, forCellReuseIdentifier: SingleTalkTableViewCell.identifier)
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
        startListeningForTalks()

    }

    private func startListeningForTalks() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return }

        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)

        DatabaseManager.shared.getAllTalks(for: safeEmail, completion: { [weak self] result in
            switch result {
            case .success(let talks):
                guard !talks.isEmpty else {
                    return
                }

                self?.talks = talks

                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print("failed to get talks \(error)")
            }

        })
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
        vc.completion = { [weak self] result in
            print("\(result)")
            self?.createNewTalk(result: result)
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }

    private func createNewTalk(result: [String: String]) {
        guard let name = result["name"],
              let email = result["email"] else {
            return
        }

        let vc = SingleTalkViewController(with: email)
        vc.isNewTalk = true
        vc.title = name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension TalksViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return talks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = talks[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: SingleTalkTableViewCell.identifier, for: indexPath) as! SingleTalkTableViewCell
        cell.configure(with: model)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let model = talks[indexPath.row]

        let vc = SingleTalkViewController(with: model.otherUserEmail)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }

}

