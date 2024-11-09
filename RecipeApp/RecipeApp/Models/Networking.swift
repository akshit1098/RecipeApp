//
//  Networking.swift
//  RecipeApp
//
//  Created by Akshit Saxena on 11/8/24.
//

import Foundation
import UIKit

enum NetworkingError: Error {
    case badURL
    case badServerResponse
    case decodingError
    case dataCorruption
}

class Networking {
    static func fetchRecipes(from urlString: String) async throws -> [Recipe] {
        guard let url = URL(string: urlString) else {
            throw NetworkingError.badURL
        }
        
        // Fetch data from the network without using a cache
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkingError.badServerResponse
        }
        
        // Decode the response data without caching it
        do {
            let decodedResponse = try JSONDecoder().decode([String: [Recipe]].self, from: data)
            return decodedResponse["recipes"] ?? []
        } catch {
            throw NetworkingError.decodingError
        }
    }
}


class ImageCacheManager {
    static let sharedCache: URLCache = {
        // Configure URLCache for image caching with disk storage
        let cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,  // 50 MB
            diskCapacity: 200 * 1024 * 1024,   // 200 MB
            diskPath: "image_cache"
        )
        return cache
    }()
    
    private static let fileManager = FileManager.default
    private static let cacheDirectory: URL = {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let cacheDirectory = documentsDirectory.appendingPathComponent("ImageCache")
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return cacheDirectory
    }()
    
    // Check for cached image in both memory (URLCache) and disk
    static func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let request = URLRequest(url: url)
        
        // First, try to load image from in-memory cache
        if let cachedImage = loadImageFromMemory(for: url) {
            DispatchQueue.main.async {
                completion(cachedImage)
            }
            return
        }
        
        // Then, try to load image from disk cache
        if let cachedImage = loadImageFromDisk(for: url) {
            DispatchQueue.main.async {
                completion(cachedImage)
            }
            return
        }
        
        // If not cached, fetch from the network and cache it
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network request failure
            if let error = error {
                print("Image loading error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil) // Return nil if there's an error
                }
                return
            }
            
            // Check if the data and response are valid
            guard let data = data, let response = response, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil) // Return nil if data is invalid
                }
                return
            }
            
            // Cache image to memory and disk
            storeImageToMemory(image, for: url)
            storeImageToDisk(image, for: url)
            
            // Store cached response in URLCache
            let cachedResponse = CachedURLResponse(response: response, data: data)
            sharedCache.storeCachedResponse(cachedResponse, for: request)
            
            // Return the loaded image on the main thread
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    // Memory cache: Load image from in-memory cache
    private static func loadImageFromMemory(for url: URL) -> UIImage? {
        // Check URLCache (in-memory cache) for the image
        if let cachedResponse = sharedCache.cachedResponse(for: URLRequest(url: url)),
           let image = UIImage(data: cachedResponse.data) {
            return image
        }
        return nil
    }
    
    // Disk cache: Load image from disk cache
    private static func loadImageFromDisk(for url: URL) -> UIImage? {
        let filePath = cacheDirectory.appendingPathComponent(url.lastPathComponent)
        
        guard fileManager.fileExists(atPath: filePath.path) else { return nil }
        
        if let data = try? Data(contentsOf: filePath) {
            return UIImage(data: data)
        }
        return nil
    }
    
    // Memory cache: Store image in the in-memory cache (URLCache)
    private static func storeImageToMemory(_ image: UIImage, for url: URL) {
        let data = image.pngData() ?? image.jpegData(compressionQuality: 0.8)
        if let data = data {
            let cachedResponse = CachedURLResponse(response: URLResponse(url: url, mimeType: "image/png", expectedContentLength: data.count, textEncodingName: nil), data: data)
            sharedCache.storeCachedResponse(cachedResponse, for: URLRequest(url: url))
        }
    }
    
    // Disk cache: Store image in disk cache
    private static func storeImageToDisk(_ image: UIImage, for url: URL) {
        guard let data = image.pngData() ?? image.jpegData(compressionQuality: 0.8) else { return }
        let filePath = cacheDirectory.appendingPathComponent(url.lastPathComponent)
        
        do {
            try data.write(to: filePath)
        } catch {
            print("Failed to save image to disk: \(error.localizedDescription)")
        }
    }
}
