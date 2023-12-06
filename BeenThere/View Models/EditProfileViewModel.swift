//
//  EditProfileViewModel.swift
//  BeenThere
//
//  Created by Jared Jones on 11/13/23.
//

import Foundation
import Firebase
import SwiftUI
import FirebaseStorage

class EditProfileViewModel: ObservableObject {
    func saveChanges(uid: String, firstName: String, lastName: String, username: String, profileImage: UIImage?, completion: @escaping () -> Void) {
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(uid)

            let group = DispatchGroup()

            group.enter()
            userRef.updateData([
                "firstName": firstName,
                "lastName": lastName,
                "username": username,
                "lowercaseUsername": username.lowercased()
            ]) { error in
                if let error = error {
                    print("Error updating user: \(error)")
                } else {
                    print("User successfully updated")
                }
                group.leave()
            }

            // Uploading profile images to Firebase Storage
            if let image = profileImage {
                group.enter()
                uploadProfileImage(image, atPath: "\(uid)/profile.jpg", resolution: 200) {
                    group.leave()
                }

//                group.enter()
//                uploadProfileImage(image, atPath: "\(uid)/profile-small.jpg", resolution: 50) {
//                    group.leave()
//                }
            }

            // Call completion handler after all tasks are finished
            group.notify(queue: DispatchQueue.main) {
                completion()
            }
        }

        private func uploadProfileImage(_ image: UIImage, atPath path: String, resolution: CGFloat, completion: @escaping () -> Void) {
            let resizedImage = resizeImage(image: image, targetSize: CGSize(width: resolution, height: resolution))
            guard let imageData = resizedImage.jpegData(compressionQuality: 1) else {
                completion()
                return
            }

            let storageRef = Storage.storage().reference().child(path)
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading image: \(error)")
                } else {
                    print("Image successfully uploaded at path: \(path)")
                }
                completion()
            }
        }
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let contextImage: UIImage = UIImage(cgImage: image.cgImage!)

        let contextSize: CGSize = contextImage.size
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(contextSize.width)
        var cgheight: CGFloat = CGFloat(contextSize.height)

        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }

        let rect: CGRect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)

        // Create bitmap image from context using the rect
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!

        // Create a new image based off the imageRef and rotate back to the original orientation
        let imageCropped: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)

        // Resize the cropped image
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        imageCropped.draw(in: CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage ?? image
    }

}
