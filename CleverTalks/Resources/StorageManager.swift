//
//  StorageManager.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 9/29/20.
//

import FirebaseStorage

final class StorageManager {

    static let shared = StorageManager()

    private init() {}

    private let storage = Storage.storage().reference()

    public typealias UploadFileCompletion = (Result<String, Error>) -> Void

    func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadFileCompletion) {

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

    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping UploadFileCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                // failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.uploadFailure))
                return
            }

            self?.storage.child("message_images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.urlDownloadingFailure))
                    return
                }

                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }

    public func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping UploadFileCompletion) {
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                // failed
                print("failed to upload video file")
                completion(.failure(StorageErrors.uploadFailure))
                return
            }

            self?.storage.child("message_videos/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.urlDownloadingFailure))
                    return
                }

                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
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
