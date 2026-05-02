//
//  MainContentView.swift
//  b&vapp
//
//  Created by Mustafa KARA on 13.03.2026.
//

import SwiftUI
import MapKit

struct MainContentView: View {

    @Binding var selectedTab: Tab
    @EnvironmentObject var viewModel: HomeViewModel
    @State private var goToAppointment: Bool = false

    var body: some View {

        Group {
            if viewModel.isLoading {
                // Veriler hazır olana kadar loading spinner
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.4)
                        .tint(.yellow)
                    Text("Yükleniyor...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 28) {

                        headerSection
                            .padding(.horizontal, 20)

                        promoCard
                            .padding(.horizontal, 20)

                        servicesSection

                        directionCard
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)
                }
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.visible, for: .tabBar)
        .task {
            await viewModel.fetchHomeData()
        }
    }
}


// MARK: - Header

extension MainContentView {
    
    @ViewBuilder
    var headerSection: some View {

        // Kullanıcı verisi yüklenene kadar shimmer skeleton
        if viewModel.user == nil {
            ShimmerHeaderSkeleton()
        } else {
            HStack {

                Button {
                    selectedTab = .profile
                } label: {
                    // Profil fotoğrafı varsa CachedAsyncImage, yoksa initials
                    Group {
                        if let urlStr = viewModel.user?.profileImageUrl,
                           !urlStr.isEmpty,
                           let url = URL(string: urlStr) {
                            CachedAsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                default:
                                    initialsAvatar
                                }
                            }
                        } else {
                            initialsAvatar
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.yellow.opacity(0.5), lineWidth: 2))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Hoş geldin,")
                        .foregroundColor(.yellow)
                        .font(.subheadline)

                    Text(viewModel.userName)
                        .foregroundColor(.primary)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                NavigationLink(destination: NotificationView()) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 42, height: 42)
                        Image(systemName: "bell")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
    // Initials avatar (profil URL yoksa gösterilen)
    private var initialsAvatar: some View {
        ZStack {
            Circle().fill(Color.yellow.opacity(0.2))
            Text(viewModel.user?.initials ?? "B")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
        }
    }
}


// MARK: - Promo Card

extension MainContentView {

    var promoCard: some View {

        ZStack {

            Image("promoBackground")
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .clipped()
                .opacity(0.2)

            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.9), Color.yellow.opacity(0.35)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            VStack(alignment: .leading, spacing: 14) {

                Text("B&V COFFEE BARBER")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Usta ellerden profesyonel tasarım ve bakım hizmeti alın.")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {

                    // Berber avatarları (initials)
                    HStack(spacing: -10) {
                        ForEach(viewModel.barbers.prefix(3)) { barber in
                            ZStack {
                                Circle()
                                    .fill(Color.yellow.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                Text(barber.initials)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }

                        if viewModel.barbers.count > 3 {
                            ZStack {
                                Circle()
                                    .fill(Color.yellow)
                                    .frame(width: 32, height: 32)
                                Text("+\(viewModel.barbers.count - 3)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                            }
                        }
                    }

                    Spacer()

                    Button {
                        goToAppointment = true
                    } label: {
                        Text("Hemen Randevu Al")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.yellow)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    .navigationDestination(isPresented: $goToAppointment) {
                        SelectAppointmentView()
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}


// MARK: - Services Section

extension MainContentView {

    var servicesSection: some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Text("Hizmetlerimiz")
                    .foregroundColor(.primary)
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    selectedTab = .services
                } label: {
                    Text("Tümünü Gör")
                        .foregroundColor(.yellow)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if viewModel.services.isEmpty {
                        // Hizmetler yüklenirken 3 skeleton kart göster
                        ForEach(0..<3, id: \.self) { _ in
                            ShimmerServiceCard()
                        }
                    } else {
                        ForEach(viewModel.services.prefix(5)) { service in
                            serviceCard(service: service)
                        }
                    }
                }
                .padding(.leading, 20)
            }
        }
    }

    func serviceCard(service: Service) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            ZStack(alignment: .bottomLeading) {

                // CachedAsyncImage: önbelleğe alınan görsel
                CachedAsyncImage(url: URL(string: service.imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        // Yükleniyor — shimmer placeholder
                        ShimmerCard(width: 160, height: 180, cornerRadius: 16)
                    default:
                        ZStack {
                            Color.gray.opacity(0.2)
                            Image(systemName: "scissors").foregroundColor(.gray)
                        }
                    }
                }
                .frame(width: 160, height: 180)
                .clipped()
                .cornerRadius(16)

                Text("₺\(service.price)")
                    .foregroundColor(.yellow)
                    .fontWeight(.bold)
                    .padding(8)
            }

            Text(service.name)
                .foregroundColor(.primary)
                .fontWeight(.semibold)
                .lineLimit(1)
        }
        .frame(width: 160)
    }
}


// MARK: - Direction Card

extension MainContentView {

    var directionCard: some View {

        let location = CLLocationCoordinate2D(latitude: 36.9238616, longitude: 34.9011379)

        return ZStack {

            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.2))

            HStack(spacing: 16) {

                Map(position: .constant(
                    MapCameraPosition.region(
                        MKCoordinateRegion(
                            center: location,
                            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
                        )
                    )
                )) {
                    Marker("B&V Co...", coordinate: location)
                }
                .mapStyle(.hybrid)
                .frame(width: 100, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 6) {
                    Text("B&V COFFEE BARBER")
                        .foregroundColor(.primary)
                        .fontWeight(.bold)

                    Text("Fatih Mah. Çağlayan Cad. No:39D/B Tarsus/Mersin")
                        .foregroundColor(.secondary)
                        .font(.caption2)
                }

                Spacer()

                Button {
                    viewModel.openMaps()
                } label: {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                        .padding(11)
                        .background(Color.yellow)
                        .clipShape(Circle())
                }
            }
            .padding(16)
        }
        .frame(height: 120)
    }
}


#Preview {
    MainContentView(selectedTab: .constant(.home))
}
