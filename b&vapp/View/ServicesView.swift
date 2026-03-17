//
//  ServicesView.swift
//  b&vapp
//
//  Created by Mustafa KARA on 13.03.2026.
//

import SwiftUI

struct ServicesView: View {
    
    // MARK: - Layout
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // MARK: - Data
    
    private let services: [Service] = [
        .init(name: "Saç Kesimi", price: 350, duration: 45, imageName: "barber1"),
        .init(name: "Sakal Tıraşı", price: 200, duration: 30, imageName: "barber2"),
        .init(name: "Cilt Bakımı", price: 500, duration: 60, imageName: "barber3"),
        .init(name: "Saç Boyama", price: 850, duration: 90, imageName: "barber4"),
        .init(name: "Saç Kesimi", price: 350, duration: 45, imageName: "barber1"),
        .init(name: "Sakal Tıraşı", price: 200, duration: 30, imageName: "barber2"),
        .init(name: "Cilt Bakımı", price: 500, duration: 60, imageName: "barber3"),
        .init(name: "Saç Boyama", price: 850, duration: 90, imageName: "barber4"),
        .init(name: "Saç Kesimi", price: 350, duration: 45, imageName: "barber1"),
        .init(name: "Sakal Tıraşı", price: 200, duration: 30, imageName: "barber2"),
        .init(name: "Cilt Bakımı", price: 500, duration: 60, imageName: "barber3"),
        .init(name: "Saç Boyama", price: 850, duration: 90, imageName: "barber4")
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 12) {
                header
            
                servicesGrid
            }
        }
    }
}

// MARK: - UI Components

private extension ServicesView {
    
    var header: some View {
        Text("Hizmetlerimiz")
            .font(.title2)
            .fontWeight(.bold)
    }
    
    var servicesGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(services) { service in
                    ServiceCard(service: service)
                }
            }
            .padding()
        }
    }
}


struct ServiceCard: View {
    
    let service: Service
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            ZStack(alignment: .bottomLeading) {
                
                // MARK: - IMAGE
                
                Image(service.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipped()
                
                // MARK: - GRADIENT OVERLAY
                
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                
                // MARK: - PRICE
                
                priceTag
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            // MARK: - INFO
            
            Text(service.name)
                .foregroundColor(.white)
                .fontWeight(.semibold)
            
            durationView
        }
    }
}

// MARK: - Sub Components

private extension ServiceCard {
    
    var priceTag: some View {
        Text("₺\(service.price)")
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.yellow)
            .foregroundColor(.black)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(10)
    }
    
    var durationView: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.caption2)
            
            Text("\(service.duration) dk")
                .font(.caption)
        }
        .foregroundColor(.gray)
    }
}

#Preview {
    ServicesView()
}
