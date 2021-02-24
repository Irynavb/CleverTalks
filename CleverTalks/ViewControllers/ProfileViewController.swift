//
//  ProfileViewController.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 9/28/20.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import SDWebImage

class ProfileViewController: UIViewController {

    @IBOutlet var tableView: UITableView!

    var data = [ProfileViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(ProfileTableViewCell.self,
                           forCellReuseIdentifier: ProfileTableViewCell.identifier)
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Name: \(UserDefaults.standard.value(forKey:"name") as? String ?? "No Name")",
                                     handler: nil))
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Email: \(UserDefaults.standard.value(forKey:"email") as? String ?? "No Email")",
                                     handler: nil))
        data.append(ProfileViewModel(viewModelType: .logout, title: "Log Out", handler: { [weak self] in

            guard let strongSelf = self else {
                return
            }

            let actionSheet = UIAlertController(title: "",
                                          message: "",
                                          preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Log Out",
                                          style: .destructive,
                                          handler: { [weak self] _ in

                                            guard let strongSelf = self else {
                                                return
                                            }

                                            UserDefaults.standard.setValue(nil, forKey: "email")
                                            UserDefaults.standard.setValue(nil, forKey: "name")

                                            // Log Out facebook
                                            FBSDKLoginKit.LoginManager().logOut()

                                            // Google Log out
                                            GIDSignIn.sharedInstance()?.signOut()

                                            do {
                                                try FirebaseAuth.Auth.auth().signOut()

                                                let vc = SignInViewController()
                                                let nav = UINavigationController(rootViewController: vc)
                                                nav.modalPresentationStyle = .fullScreen
                                                strongSelf.present(nav, animated: true)
                                            }
                                            catch {
                                                print("Failed to log out")
                                            }

            }))

            actionSheet.addAction(UIAlertAction(title: "Cancel",
                                                style: .cancel,
                                                handler: nil))

            strongSelf.present(actionSheet, animated: true)
        }))
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self

        tableView.tableHeaderView = createTableViewHeader()
    }

    func createTableViewHeader() -> UIView? {

        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }

        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"

        let path = "images/" + fileName
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))

        headerView.backgroundColor = .mediumGreen

        let imageView = UIImageView(frame: CGRect(x: (headerView.width - 150) / 2, y: 75, width: 150, height: 150)).then {
            $0.contentMode = .scaleAspectFill
            $0.layer.borderColor = UIColor.darkBrown.cgColor
            $0.layer.borderWidth = 3
            $0.layer.masksToBounds = true
            $0.layer.cornerRadius = $0.width/2
        }

        headerView.addSubview(imageView)

        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            switch result {
            case .success(let url):
                self?.downloadImage(imageView: imageView, url: url)
            case .failure(let error):
                print("Failed to download url: \(error) ")
            }

        })


        return headerView
    }

    #warning("check this part of code for redunduncy")
    func downloadImage(imageView: UIImageView, url: URL) {

        URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
            guard let data = data, error == nil else {
                return
            }

            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
            }
        }).resume()
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier,
                                                 for: indexPath) as! ProfileTableViewCell
        cell.setUp(with: viewModel)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
    }
}
