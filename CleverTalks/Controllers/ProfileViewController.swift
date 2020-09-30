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

class ProfileViewController: UIViewController {

    @IBOutlet var tableView: UITableView!

    let data = ["Sign Out"]

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let actionSheet = UIAlertController (title: "", message: "", preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }

            // Sign Out Facebook
            FBSDKLoginKit.LoginManager().logOut()

            // Google Sign Out
            GIDSignIn.sharedInstance()?.signOut()

            do {
                try FirebaseAuth.Auth.auth().signOut()

                let vc = SignInViewController()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                strongSelf.present(nav, animated: true)
            }
            catch {
                print(error)
            }

        }))

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(actionSheet, animated: true)
    }
}
