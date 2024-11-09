//
//  FilterSheetView.swift
//  RecipeApp
//
//  Created by Akshit Saxena on 11/8/24.
//

import SwiftUI

struct FilterSheetView: View {
    let cuisines: [String]
    @Binding var selectedCuisine: String? // To store the selected cuisine
    @Environment(\.dismiss) var dismiss // To dismiss the sheet
    
    var body: some View {
        NavigationView {
            List {
                // Option for "All Categories"
                HStack {
                    Text("All Categories")
                    Spacer()
                    if selectedCuisine == nil {
                        Image(systemName: "checkmark")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedCuisine = nil // Set to nil to show all recipes
                }
                
                // Options for specific cuisines
                ForEach(cuisines, id: \.self) { cuisine in
                    HStack {
                        Text(cuisine)
                        Spacer()
                        if selectedCuisine == cuisine {
                            Image(systemName: "checkmark")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCuisine = cuisine
                    }
                }
            }
            .navigationTitle("Select Cuisine")
            .navigationBarItems(trailing: Button("Done") {
                dismiss() // Close the sheet and apply changes
            })
        }
    }
}
