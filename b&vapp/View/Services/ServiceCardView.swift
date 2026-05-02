//
//  ServiceCardView.swift
//  b&vapp
//
//  Created by Mustafa KARA on 13.03.2026.
//

import SwiftUI

struct ServiceCardView: View {

    let service: Service

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            ZStack(alignment: .bottomLeading) {

                // Remote image (imageUrl)
                CachedAsyncImage(url: URL(string: service.imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderImage
                    case .empty:
                        // Görsel yüklenirken kart boyutunda shimmer göster
                        ShimmerCard(width: .infinity, height: 150, cornerRadius: 20)
                    @unknown default:
                        placeholderImage
                    }
                }
                .frame(height: 150)
                .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.75)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                priceTag
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))

            Text(service.name)
                .foregroundColor(.primary)
                .fontWeight(.semibold)

            durationView
        }
    }
}

private extension ServiceCardView {

    var placeholderImage: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Image(systemName: "scissors")
                .font(.title)
                .foregroundColor(.gray)
        }
    }

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
            Image(systemName: "clock").font(.caption2)
            Text("\(service.duration) dk").font(.caption)
        }
        .foregroundColor(.secondary)
    }
}
