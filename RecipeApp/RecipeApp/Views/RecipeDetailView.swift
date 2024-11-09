//
//  RecipeDetailView.swift
//  RecipeApp
//
//  Created by Akshit Saxena on 11/8/24.
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @State private var image: UIImage? = nil
    @Environment(\.dismiss) var dismiss // To dismiss the view
    
    var body: some View {
        VStack {
            ZStack {
                if let image = image {
                    // Wrap the image and play button together inside the Button
                    Button(action: {
                        openYouTubeApp(url: recipe.youtubeURL) // Open YouTube app on image tap
                    }) {
                        ZStack {
                            // Image
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 300)
                                .cornerRadius(10)
                            
                            // Play button overlay
                            Image(systemName: "play.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80) // Large play button
                                .foregroundColor(.gray)
                                .opacity(0.7) // Semi-transparent
                        }
                    }
                } else {
                    Color.gray
                        .frame(height: 300)
                        .cornerRadius(10)
                        .onAppear {
                            loadLargeImage() // Load large image when view appears
                        }
                }
            }
            
            Text(recipe.name)
                .font(.largeTitle)
                .padding(.top, 10)
            
            Text(recipe.cuisine)
                .font(.title2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                dismiss() // Close the popover
            }) {
                Text("Close")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private func loadLargeImage() {
        guard let url = recipe.photoURLLarge else { return }
        
        // Use URLSession to load the image asynchronously
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Failed to load image: \(error.localizedDescription)")
                return
            }
            
            // Check if data is valid and can be used to create an image
            guard let data = data, let loadedImage = UIImage(data: data) else {
                print("Failed to decode image data")
                return
            }
            
            // Update the UI on the main thread
            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }.resume() // Don't forget to resume the task
    }
    
    // Function to open the YouTube app (or Safari if app is not available)
    private func openYouTubeApp(url: URL?) {
        guard let url = url else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            // Optionally, open the URL in Safari if YouTube app is not installed
            if let webURL = URL(string: "https://www.youtube.com/watch?v=\(url.lastPathComponent)") {
                UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
            }
        }
    }
}
