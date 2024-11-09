//
//  RecipeAppTests.swift
//  RecipeAppTests
//
//  Created by Akshit Saxena on 11/8/24.
//

import XCTest
@testable import RecipeApp

final class RecipeAppTests: XCTestCase {

    
    
    func testMalformedRecipeData() throws {
        // Sample malformed JSON (missing a field)
        let malformedJson = """
        {
            "uuid": "599344f4-3c5c-4cca-b914-2210e3b3312f",
            "name": "Apple & Blackberry Crumble"
            // Missing fields
        }
        """.data(using: .utf8)!
        
        // Attempt to decode the malformed JSON
        let decoder = JSONDecoder()
        do {
            let _ = try decoder.decode(Recipe.self, from: malformedJson)
            XCTFail("The malformed JSON should not have been decoded successfully")
        } catch {
            // We expect decoding to fail
            XCTAssertTrue(true, "Malformed JSON data handled correctly")
        }
    }
    
    func testEmptyRecipeList() throws {
        // Sample empty JSON for recipes
        let emptyJson = """
        []
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        do {
            let recipes = try decoder.decode([Recipe].self, from: emptyJson)
            
            // Assert that no recipes are returned
            XCTAssertEqual(recipes.count, 0, "The recipe list should be empty")
        } catch {
            XCTFail("Failed to decode empty recipe list")
        }
    }
    
 
    func testMissingRequiredField() throws {
        // Sample JSON with a missing required field ('name') for the "Apple & Blackberry Crumble" recipe
        let missingNameJson = """
        {
            "uuid": "599344f4-3c5c-4cca-b914-2210e3b3312f",
            "cuisine": "British",
            "photo_url_large": "https://d3jbb8n5wk0qxi.cloudfront.net/photos/535dfe4e-5d61-4db6-ba8f-7a27b1214f5d/large.jpg",
            "photo_url_small": "https://d3jbb8n5wk0qxi.cloudfront.net/photos/535dfe4e-5d61-4db6-ba8f-7a27b1214f5d/small.jpg",
            "source_url": "https://www.bbcgoodfood.com/recipes/778642/apple-and-blackberry-crumble",
            "youtube_url": "https://www.youtube.com/watch?v=4vhcOwVBDO4"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        do {
            // Attempt to decode the JSON with the missing 'name' field
            let _ = try decoder.decode(Recipe.self, from: missingNameJson)
            XCTFail("The JSON with a missing 'name' field should not have been decoded successfully")
        } catch let decodingError {
            // Check if the error is due to the missing 'name' field (KeyNotFound error)
            if let error = decodingError as? DecodingError,
               case .keyNotFound(let key, _) = error,
               key.stringValue == "name" {
                XCTAssertTrue(true, "Missing required field 'name' was handled correctly")
            } else {
                XCTFail("Decoding failed for an unexpected reason: \(decodingError.localizedDescription)")
            }
        }
    }


}
