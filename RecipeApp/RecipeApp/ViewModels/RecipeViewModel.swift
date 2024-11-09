//
//  RecipeViewModel.swift
//  RecipeApp
//
//  Created by Akshit Saxena on 11/8/24.
//

import Foundation

@MainActor
class RecipeViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // Computed property to get a list of unique cuisines
    var cuisines: [String] {
        Array(Set(recipes.map { $0.cuisine })).sorted()
    }
    
    func loadRecipes() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetchedRecipes = try await Networking.fetchRecipes(from: "https://d3jbb8n5wk0qxi.cloudfront.net/recipes.json")
            if fetchedRecipes.isEmpty {
                errorMessage = "😞 No recipes available."
            } else {
                recipes = fetchedRecipes
            }
        } catch {
            errorMessage = "😞 Failed to load recipes. Please try again."
        }
        isLoading = false
    }

}

