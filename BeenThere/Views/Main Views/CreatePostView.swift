//
//  CreatePostView.swift
//  BeenThere
//
//  Created by Jared Jones on 11/27/23.
//

import CoreLocation
import ImageIO
import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @State private var post: Post?
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var authorName: String = ""
    @State private var error: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Post Details")) {
                    TextField("Title", text: $title)
                    TextField("Content", text: $content)
                    TextField("Author Name", text: $authorName)
                }

                Section {
                    Button("Select Image") {
                        showingImagePicker = true
                    }
                }

                if let error = error {
                    Text(error).foregroundColor(.red)
                }

                Button("Create Post") {
                    createPost()
                }
            }
            .navigationBarTitle("Create Post")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
        }
    }

    func createPost() {
        guard let inputImage = inputImage else {
            error = "Please select an image."
            return
        }

        guard let location = extractLocation(from: inputImage) else {
            error = "No location data found in image."
            return
        }

        let image = Image(uiImage: inputImage)
        post = Post(title: title, content: content, image: image, location: location, authorName: authorName)
        error = nil
    }

    func extractLocation(from image: UIImage) -> Location? {
        // Convert UIImage to NSData
        guard let data = image.jpegData(compressionQuality: 1) else { return nil }

        // Create an image source
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        
        // Get image properties
        let imageProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as Dictionary?
        guard let gpsDict = imageProperties?[kCGImagePropertyGPSDictionary as String as NSObject] as? [String: Any] else { return nil }

        // Extract latitude and longitude from GPS Dictionary
        guard let latitudeNumber = gpsDict[kCGImagePropertyGPSLatitude as String] as? Double,
              let longitudeNumber = gpsDict[kCGImagePropertyGPSLongitude as String] as? Double,
              let latRef = gpsDict[kCGImagePropertyGPSLatitudeRef as String] as? String,
              let lonRef = gpsDict[kCGImagePropertyGPSLongitudeRef as String] as? String else { return nil }

        // Convert latitude and longitude to proper format
        let latitude = (latRef == "N") ? latitudeNumber : -latitudeNumber
        let longitude = (lonRef == "E") ? longitudeNumber : -longitudeNumber

        // Create and return a Location instance
        return Location(lowLatitude: latitude, highLatitude: latitude, lowLongitude: longitude, highLongitude: longitude)
    }

}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    if let uiImage = image as? UIImage {
                        self.parent.image = uiImage
                    }
                }
            }
        }
    }
}


#Preview {
    CreatePostView()
}
