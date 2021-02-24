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

    private var loginObserver: NSObjectProtocol?

    override func viewDidLoad() {

        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(composeButtonTapped))
//        view.backgroundColor = .backgroundLightGreen

        view.addSubview(tableView)
        view.addSubview(noTalksLabel)
        tableView.delegate = self
        tableView.dataSource = self

        startListeningForTalks()

        loginObserver = NotificationCenter.default.addObserver(forName: .didSignInNotificanion, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }

            strongSelf.startListeningForTalks()
        })

    }

    private func startListeningForTalks() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return }

        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        print("starting conversation fetch...")

        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)

        DatabaseManager.shared.getAllTalks(for: safeEmail, completion: { [weak self] result in
            switch result {
            case .success(let talks):
                guard !talks.isEmpty else {
                    self?.tableView.isHidden = true
                    self?.noTalksLabel.isHidden = false
                    return
                }
                self?.noTalksLabel.isHidden = true
                self?.tableView.isHidden = false
                self?.talks = talks

                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                self?.tableView.isHidden = true
                self?.noTalksLabel.isHidden = false
                print("failed to get talks \(error)")
            }
        })
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noTalksLabel.frame = CGRect(x: 10, y: (view.height-100)/2, width: view.width-20, height: 100)
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

    @objc private func composeButtonTapped() {
        let vc = NewTalkViewController()
        vc.completion = { [weak self] result in
            guard let strongSelf = self else {
                return
            }

            let currentTalks = strongSelf.talks

            if let targetTalk = currentTalks.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(emailAddress: result.email)
            }) {
                let vc = SingleTalkViewController(with: targetTalk.otherUserEmail, id: targetTalk.id)
                vc.isNewTalk = false
                vc.title = targetTalk.name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
            else {
                strongSelf.createNewTalk(result: result)
            }
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)

    }

    private func createNewTalk(result: SearchResult) {
        let name = result.name
        let email = DatabaseManager.safeEmail(emailAddress: result.email)


        DatabaseManager.shared.talkExists(iwth: email, completion: { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let conversationId):
                let vc = SingleTalkViewController(with: email, id: conversationId)
                vc.isNewTalk = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc = SingleTalkViewController(with: email, id: nil)
                vc.isNewTalk = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        })
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

        openTalk(model)
    }

    func openTalk(_ model: Talk) {
        let vc = SingleTalkViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // begin delete
            let talkId = talks[indexPath.row].id
            tableView.beginUpdates()
            self.talks.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)

            DatabaseManager.shared.deleteTalk(talkId: talkId, completion: { success in
                if !success {
                    // add model and row back and show error alert

                }
            })

            tableView.endUpdates()
        }
    }
}

