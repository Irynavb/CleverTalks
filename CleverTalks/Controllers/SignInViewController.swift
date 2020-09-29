//
//  SignInViewController.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 9/28/20.
//

import Then
import Anchorage

class SignInViewController: UIViewController {

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()

    private let imageView = UIImageView().then {
        $0.image = #imageLiteral(resourceName: "SmallLogoImage")
        $0.contentMode = .scaleAspectFit
        $0.layer.masksToBounds = true
        $0.layer.borderWidth = 2
        $0.layer.borderColor = UIColor.darkGreen.cgColor
    }

    private let emailField = UITextField().then {
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
        $0.returnKeyType = .continue
        $0.layer.cornerRadius = 8
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.darkGreen.cgColor
        $0.placeholder = "Email Address"
        $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        $0.leftViewMode = .always
    }

    private let passwordField = UITextField().then {
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
        $0.returnKeyType = .done
        $0.layer.cornerRadius = 8
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.darkGreen.cgColor
        $0.placeholder = "Password (8+ characters)"
        $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        $0.leftViewMode = .always
        $0.isSecureTextEntry = true
    }

    private let signInButton = UIButton().then {
        $0.setTitle("Sign In", for: .normal)
        $0.backgroundColor = .darkBrown
        $0.setTitleColor(.darkGreen, for: .normal)
        $0.layer.cornerRadius = 8
        $0.layer.masksToBounds = true
        $0.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        title = "Sign In"
        view.backgroundColor = .backgroundLightGreen

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(signUpPressed))

        signInButton.addTarget(self, action: #selector(signInPressed), for: .touchUpInside)

        emailField.delegate = self
        passwordField.delegate = self

        // add subviews
        view.addSubview(scrollView)

        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(signInButton)

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width - size) / 2,
                                 y: 50,
                                 width: size,
                                 height: size)
        imageView.layer.cornerRadius = imageView.width / 2.0
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom + 30,
                                  width: scrollView.width - 60,
                                  height: 52)

        passwordField.frame = CGRect(x: 30,
                                  y: emailField.bottom + 30,
                                  width: scrollView.width - 60,
                                  height: 52)
        signInButton.frame = CGRect(x: 30,
                                  y: passwordField.bottom + 50,
                                  width: scrollView.width - 60,
                                  height: 52)
    }

    @objc private func signInPressed() {

        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()

        guard let email = emailField.text,
              let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 8 else {
                alertUserSignInError()
            return
        }

        // Firebase Sign In
        
    }

    func alertUserSignInError() {
        let alert = UIAlertController(title: "Oh no",
                                      message: "Please enter all information to sign in",
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title:  "Dismiss",
                                      style: .cancel,
                                      handler: nil))

        present(alert, animated: true)

    }

    @objc private func signUpPressed() {
        let vc = SignUpViewController()
        vc.title = "Create Account"
        vc.view.backgroundColor = .backgroundLightGreen
        navigationController?.pushViewController(vc, animated: true)
    }

}

extension SignInViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            signInPressed()
        }

        return true
    }

}
