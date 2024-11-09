//
//  ContentView.swift
//  RecipeApp
//
//  Created by Akshit Saxena on 11/8/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RecipeViewModel()
    @State private var showingFilterSheet = false
    @State private var selectedCuisine: String? = nil
    @State private var selectedRecipe: Recipe? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red)
                } else if filteredRecipes.isEmpty {
                    Text("No recipes available.")
                } else {
                    List(filteredRecipes) { recipe in
                        RecipeRowView(recipe: recipe)
                            .contentShape(Rectangle()) // Ensures the whole row is tappable
                            .onTapGesture {
                                selectedRecipe = recipe
                            }
                            .sheet(item: $selectedRecipe) { recipe in
                                RecipeDetailView(recipe: recipe) // Navigate to RecipeDetailView
                            }
                    }
                }
            }
            .navigationTitle("Recipes")
            .navigationBarItems(
                leading: Button(action: {
                    showingFilterSheet = true // Show filter options
                }) {
                    HStack {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                        Text("Filter")
                    }
                    .foregroundColor(.blue)
                },
                trailing: Button(action: {
                    selectedCuisine = nil // Clear any filters
                    Task {
                        await viewModel.loadRecipes() // Refresh the data
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .foregroundColor(.blue)
                }
            )
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheetView(
                    cuisines: viewModel.cuisines,
                    selectedCuisine: $selectedCuisine
                )
            }
            .refreshable {
                selectedCuisine = nil // Clear any filters
                await viewModel.loadRecipes() // Refresh the data
            }
            .onAppear {
                Task {
                    await viewModel.loadRecipes()
                }
            }
        }
    }
    
    // Computed property to filter recipes based on selected cuisine
    private var filteredRecipes: [Recipe] {
        if let selectedCuisine = selectedCuisine {
            return viewModel.recipes.filter { $0.cuisine == selectedCuisine }
        }
        return viewModel.recipes
    }
}



struct RecipeRowView: View {
    let recipe: Recipe
    @State private var image: UIImage? = nil
    
    var body: some View {
        HStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Color.gray
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onAppear {
                        loadImage()
                    }
            }
            
            VStack(alignment: .leading) {
                Text(recipe.name).font(.headline)
                Text(recipe.cuisine).font(.subheadline).foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle()) // Ensures the whole area is tappable
            }
    
    private func loadImage() {
        guard let url = recipe.photoURLSmall else { return }
        ImageCacheManager.loadImage(from: url) { loadedImage in
            self.image = loadedImage
        }
    }
}


#Preview {
    ContentView()
}
