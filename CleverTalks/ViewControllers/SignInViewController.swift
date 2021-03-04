//
//  SignInViewController.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 9/28/20.
//

import Then
import Anchorage
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class SignInViewController: UIViewController {

    private let spinner = JGProgressHUD(style: .light)

    private let scrollView = UIScrollView().then {
        $0.clipsToBounds = true
    }

    private let emailField = CTTextField(placeholder: "Email Address").then {
        $0.returnKeyType = .continue
    }

    private let passwordField = CTTextField(placeholder: "Password (8+ characters)").then {
        $0.returnKeyType = .done
        $0.isSecureTextEntry = true
    }

    private let signInButton = CTButton().then {
        $0.setTitle("Sign In", for: .normal)
        $0.addTarget(self, action: #selector(signInPressed), for: .touchUpInside)
    }

    private let facebookSignInButton = FBLoginButton().then {
        $0.permissions = ["email, public_profile"]
    }

    private let googleSignInButton = GIDSignInButton().then {
        $0.style = .wide
    }

    private var signInObserver: NSObjectProtocol?

    override func viewDidLoad() {

        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        title = "Clever Talks"

        signInObserver = NotificationCenter.default.addObserver(forName: .didSignInNotificanion, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })

        GIDSignIn.sharedInstance()?.presentingViewController = self

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .plain, target: self, action: #selector(signUpPressed))
        navigationController?.navigationBar.prefersLargeTitles = true

        emailField.delegate = self
        passwordField.delegate = self
        facebookSignInButton.delegate = self

        view.addSubview(scrollView)
        scrollView.addSubviews( emailField, passwordField, signInButton, facebookSignInButton, googleSignInButton)
    }

    deinit {
        if let observer = signInObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds

        emailField.frame = CGRect(x: 30,
                                  y: scrollView.top + 65,
                                  width: scrollView.width - 60,
                                  height: 52)

        passwordField.frame = CGRect(x: 30,
                                  y: emailField.bottom + 20,
                                  width: scrollView.width - 60,
                                  height: 52)
        signInButton.frame = CGRect(x: 30,
                                  y: passwordField.bottom + 90,
                                  width: scrollView.width - 60,
                                  height: 52)
        facebookSignInButton.frame = CGRect(x: 30,
                                  y: signInButton.bottom + 20,
                                  width: scrollView.width - 60,
                                  height: 52)
        googleSignInButton.frame = CGRect(x: 30,
                                  y: facebookSignInButton.bottom + 20,
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

        spinner.show(in: view)
        // Firebase Sign In
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] authResult, error in

            guard let strongSelf = self else {
                return
            }
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }

            guard let result = authResult, error == nil else {
                print("Failed to sign in user with email: \(email)")
                return
            }

            let user = result.user

            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: { result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String: Any],
                          let firstName = userData["first_name"] as? String,
                          let lastName = userData["last_name"] as? String else {
                        return
                    }
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")

                case .failure(let error):
                    print("Failed to read data with error \(error)")
                }
            })

            UserDefaults.standard.set(email, forKey: "email")
            print("Logged In User: \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
        
    }

    func alertUserSignInError() {
        let alert = UIAlertController(title: "Oh no",
                                      message: "Please enter all the information to sign in",
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title:  "Dismiss",
                                      style: .cancel,
                                      handler: nil))

        present(alert, animated: true)

    }

    @objc private func signUpPressed() {
        let vc = SignUpViewController()
        vc.view.backgroundColor = .systemBackground
        navigationController?.pushViewController(vc, animated: true)
        navigationController?.navigationBar.prefersLargeTitles = true
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

extension SignInViewController: LoginButtonDelegate {

    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User could not sign in with facebook")
            return
        }

        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields": "email, first_name, last_name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        facebookRequest.start(completionHandler: { _, result, error in
            guard let result = result as? [String: Any],
                  error == nil else {
                print("Failed to make facebook graph request")
                return
            }
            print("\(String(describing: result))")

            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any],
                  let data = picture["data"] as? [String: Any],
                  let pictureUrl = data["url"] as? String else {
                print("Failed to get email and name from facebook result")
                return
            }

            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")

            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }

                            print("Downloading data from facebook image")

                            URLSession.shared.dataTask(with: url, completionHandler: { data, _, _ in
                                guard let data = data else {
                                    print("failed to get data from FB")
                                    return
                                }

                                print("got data from facebook image")
                                // upload image
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

                            }).resume()
                        }
                    })
                }

            })

            let credential = FacebookAuthProvider.credential(withAccessToken: token)

            FirebaseAuth.Auth.auth().signIn(with: credential, completion: { [weak self] authResult, error in
                guard let strongSelf = self else {
                    return
                }
                guard authResult != nil, error == nil else {
                    if let error = error {
                        print("Facebook credential sign in failed, error occured: \(error), MFA may be needed")
                    }
                    return
                }
                print("Signed in successfully")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
    }

    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no operation
    }


}
