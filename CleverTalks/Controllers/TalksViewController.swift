//
//  TalksViewController.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 9/28/20.
//

import Anchorage
import FirebaseAuth

class TalksViewController: UIViewController {

    private let imageView = UIImageView().then {
        $0.image = #imageLiteral(resourceName: "FirstScreenImage")
        $0.contentMode = .scaleAspectFit
    }

    override func viewDidLoad() {

        super.viewDidLoad()
        view.backgroundColor = .darkGreen

        view.addSubview(imageView)
        imageView.edgeAnchors == view.edgeAnchors
        imageView.centerAnchors == view.centerAnchors

//        DatabaseManager.shared.insertUser(with: <#T##ChatAppUser#>)

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
}

