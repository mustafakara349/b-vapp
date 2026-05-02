//
//  ServicesView.swift
//  b&vapp
//
//  Created by Mustafa KARA on 13.03.2026.
//

import SwiftUI

struct ServicesView: View {
    
    @EnvironmentObject var viewModel: ServicesViewModel
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 0) {
                
                // HEADER
                HStack {
                    Text("Hizmetlerimiz")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding()
                
                
                // CONTENT
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 20) {
                        if viewModel.isLoading {
                            // Yükleniyor durumunda 6 adet skeleton kart göster
                            ForEach(0..<6, id: \.self) { _ in
                                ShimmerGridServiceCard()
                            }
                        } else {
                            ForEach(viewModel.services) { service in
                                ServiceCardView(service: service)
                            }
                        }
                    }
                    .padding()
                }
            }
            .toolbar(.visible, for: .tabBar)
        }
        .task {
            await viewModel.fetchServices()
        }
    }
}

#Preview {
    ServicesView()
}
