import SwiftUI
import PhotosUI
import Vision

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage?
    @State private var containsPerson = false
    @State private var showResult = false

    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .padding()
            } else {
                Text("Seleccione una imagen")
                    .font(.headline)
                    .padding()
            }

            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                Text("Subir Imagen")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        detectPerson(in: uiImage)
                    }
                }
            }

            if showResult {
                Text(containsPerson ? "Personas detectadas en la imagen" : "No se detectaron personas en la imagen")
                    .foregroundColor(containsPerson ? .green : .red)
                    .padding()
            }
        }
    }

    func detectPerson(in image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let request = VNDetectHumanRectanglesRequest { request, error in
            guard error == nil else { return }
            containsPerson = request.results?.first != nil
            showResult = true
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global().async {
            do {
                try handler.perform([request])
            } catch {
                print("Error al procesar la imagen: \(error)")
            }
        }
    }
}
