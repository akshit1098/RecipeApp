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
    
    static func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let request = URLRequest(url: url)
        
        // Check for a cached response first
        if let cachedResponse = sharedCache.cachedResponse(for: request),
           let image = UIImage(data: cachedResponse.data) {
            // Return cached image if available
            DispatchQueue.main.async {
                completion(image)
            }
            return
        }
        
        // If not cached, fetch from the network and cache it to disk
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
            
            // Create a cached response and store it to disk
            let cachedResponse = CachedURLResponse(response: response, data: data)
            sharedCache.storeCachedResponse(cachedResponse, for: request)
            
            // Return the loaded image on the main thread
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}
