//
//  StorageManager.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 9/29/20.
//

import FirebaseStorage

final class StorageManager {

    static let shared = StorageManager()

    private let storage = Storage.storage().reference()

    public typealias UploadImageCompletion = (Result<String, Error>) -> Void

    func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadImageCompletion) {

        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else {
                print("Failed to upload data to Firebase")
                completion(.failure(StorageErrors.uploadFailure))
                return
            }

            self.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to download URL")
                    completion(.failure(StorageErrors.urlDownloadingFailure))
                    return
                }

                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))

            })
        })

    }

    public enum StorageErrors: Error {
        case uploadFailure
        case urlDownloadingFailure
    }

    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)

        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.urlDownloadingFailure))
                return
            }
            completion(.success(url))
        })
    }
}
