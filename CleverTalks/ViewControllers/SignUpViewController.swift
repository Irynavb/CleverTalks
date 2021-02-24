//
//  SignUpViewController.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 9/28/20.
//

import Anchorage
import FirebaseAuth
import JGProgressHUD

class SignUpViewController: UIViewController {

    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView = UIScrollView().then {
        $0.clipsToBounds = true
    }

    let imageView = UIImageView().then {
        $0.image = UIImage(systemName: "person.circle")
        $0.tintColor = .darkBrown
        $0.contentMode = .scaleAspectFit
        $0.layer.masksToBounds = true
        $0.layer.borderWidth = 2
        $0.layer.borderColor = UIColor.darkGreen.cgColor
    }

    private let firstNameField = UITextField().then {
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
        $0.returnKeyType = .continue
        $0.layer.cornerRadius = 8
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.darkGreen.cgColor
        $0.placeholder = "First Name"
        $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        $0.leftViewMode = .always
        $0.backgroundColor = .secondarySystemBackground
    }

    private let lastNameField = UITextField().then {
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
        $0.returnKeyType = .continue
        $0.layer.cornerRadius = 8
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.darkGreen.cgColor
        $0.placeholder = "Last Name"
        $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        $0.leftViewMode = .always
        $0.backgroundColor = .secondarySystemBackground
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
        $0.backgroundColor = .secondarySystemBackground
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
        $0.backgroundColor = .secondarySystemBackground
    }

    private let signUpButton = UIButton().then {
        $0.setTitle("Sign Up", for: .normal)
        $0.backgroundColor = .darkBrown
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 8
        $0.layer.masksToBounds = true
        $0.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        title = "Create Account"
        view.backgroundColor = .systemBackground


        signUpButton.addTarget(self, action: #selector(didPressSignUp), for: .touchUpInside)

        emailField.delegate = self
        passwordField.delegate = self

        // add subviews
        view.addSubview(scrollView)

        scrollView.addSubview(imageView)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(signUpButton)

        imageView.isUserInteractionEnabled  = true
        scrollView.isUserInteractionEnabled = true

        let gesture = UITapGestureRecognizer(target: self,
                                             action: #selector(didTapChangeProfilePicture)).then{
                                                $0.numberOfTouchesRequired = 1
                                                $0.numberOfTapsRequired = 1
                                             }

        imageView.addGestureRecognizer(gesture)

    }

    @objc private func didTapChangeProfilePicture() {
        presentPhotoActionSheet()
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
        firstNameField.frame = CGRect(x: 30,
                                  y: imageView.bottom + 30,
                                  width: scrollView.width - 60,
                                  height: 52)

        lastNameField.frame = CGRect(x: 30,
                                  y: firstNameField.bottom + 30,
                                  width: scrollView.width - 60,
                                  height: 52)
        emailField.frame = CGRect(x: 30,
                                  y: lastNameField.bottom + 30,
                                  width: scrollView.width - 60,
                                  height: 52)

        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 30,
                                     width: scrollView.width - 60,
                                     height: 52)
        signUpButton.frame = CGRect(x: 30,
                                    y: passwordField.bottom + 50,
                                    width: scrollView.width - 60,
                                    height: 52)
    }

    @objc private func didPressSignUp() {

        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()

        guard let firstName = firstNameField.text,
              let lastName = lastNameField.text,
              let email = emailField.text,
              let password = passwordField.text,
              !firstName.isEmpty,
              !lastName.isEmpty,
              !email.isEmpty,
              !password.isEmpty,
              password.count >= 8
        else {
            alertUserSignUpError()
            return
        }

        spinner.show(in: view)

        // Firebase  Sign In

        DatabaseManager.shared.userExists(with: email, completion: { [weak self] exists in
            guard let strongSelf = self else {
                return
            }

            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }

            guard !exists else {
                // user already exists
                strongSelf.alertUserSignUpError(message: "A user account with this email already exists.")
                return
            }

            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: { authResult, error in
                guard authResult != nil, error == nil else {
                    print("Error creating a user")
                    return

                }

                UserDefaults.standard.setValue(email, forKey: "email")
                UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")

                let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)

                DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                    if success {

                        guard let image = strongSelf.imageView.image,
                              let data = image.pngData() else {
                            return
                        }
                        let fileName = chatUser.profileImageFileName

                        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                            switch result {
                            case .success(let downloadUrl):
                                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                print(downloadUrl)
                            case .failure(let error):
                                print("Storage manager error:\(error)")
                            }

                        })
                    }
                })

                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        })

    }

    func alertUserSignUpError(message: String = "Please enter all information to create a new account") {
        let alert = UIAlertController(title: "Oh no",
                                      message: message ,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title:  "Dismiss",
                                      style: .cancel,
                                      handler: nil))

        present(alert, animated: true)

    }

    @objc private func signUpPressed() {
        let vc = SignUpViewController()
        vc.title = "Create Account"
        vc.view.backgroundColor = .systemBackground
        navigationController?.pushViewController(vc, animated: true)
    }

}

extension SignUpViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            didPressSignUp()
        }

        return true
    }
}

