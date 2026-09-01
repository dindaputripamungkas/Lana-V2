//
//  HomeView.swift
//  Lana-V2
//
//  Created by Dinda Putri Pamungkas  on 31/08/26.
//

import SwiftUI

struct HomeView: View {
    @State private var controller = SavedRoutesController()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text("Design a new route")
                            .font(.headline)
                        Text("Ready for a new challenge? Set a new distance and craft another perfect ride")
                            .font(.subheadline)
                        Button("Create a new route") {
                            
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Last Saved routes").font(.headline)
                            Spacer()
                            NavigationLink("See all") {
                                SavedRoutesView()
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        
                        ForEach(controller.routes.prefix(3)){
                            route in
                            NavigationLink(destination: RouteDetailView(route: route)) {
                                SavedRouteCardView(route: route, showFavoriteButton: false)
                            }
                        }
                    }
                }
                .padding()
                .navigationTitle(Text("Routes"))
                .navigationBarTitleDisplayMode(.large)
            }
        }
    }
}

#Preview {
    HomeView()
}
