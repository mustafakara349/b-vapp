//
//  SelectAppointmentView.swift
//  b&vapp
//
//  Created by Mustafa KARA on 14.03.2026.
//

import SwiftUI

struct SelectAppointmentView: View {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AppointmentsViewModel
    
    // Özet bottom sheet
    @State private var showBookingSummary = false
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            // HEADER
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                Spacer()
                Text("Randevu Oluştur")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Circle().fill(Color.clear).frame(width: 24)
            }
            .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    
                    // MARK: Berber Seç
                    sectionHeader("Personel Seç")
                    
                    if viewModel.barbers.isEmpty {
                        loadingOrEmpty("Berber yükleniyor...")
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 18) {
                                ForEach(viewModel.barbers) { barber in
                                    BarberCard(
                                        barber: barber,
                                        isSelected: barber.id == viewModel.selectedBarber?.id
                                    )
                                    .onTapGesture {
                                        if barber.id != viewModel.selectedBarber?.id {
                                            viewModel.selectedBarber = barber
                                            viewModel.onBarberChanged()
                                        }
                                    }
                                }
                            }
                            // Üst padding: daire çerçevesinin üst kısmının kesilmesini önler
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        }
                    }
                    
                    // MARK: Tarih Seç
                    HStack {
                        sectionHeader("Tarih Seçin")
                        Spacer()
                        Text(DateManager.monthYearString(from: viewModel.selectedDate))
                            .foregroundColor(.yellow)
                    }
                    
                    if viewModel.isLoadingAvailability {
                        HStack {
                            ProgressView()
                                .tint(.yellow)
                            Text("Müsait günler yükleniyor...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else if viewModel.availableDates.isEmpty {
                        Text("Bu berber için müsait gün bulunamadı.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.availableDates, id: \.self) { date in
                                    DateCard(
                                        date: date,
                                        isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate)
                                    )
                                    .onTapGesture {
                                        viewModel.selectedDate = date
                                        viewModel.onDateChanged()
                                    }
                                }
                            }
                        }
                    }
                    
                    // MARK: Hizmet Seç
                    sectionHeader("Hizmet Seçin")
                    
                    if viewModel.services.isEmpty {
                        loadingOrEmpty("Hizmetler yükleniyor...")
                    } else {
                        VStack(spacing: 10) {
                            ForEach(viewModel.services) { service in
                                ServiceSelectCard(
                                    service: service,
                                    isSelected: service.id == viewModel.selectedService?.id
                                )
                                .onTapGesture {
                                    viewModel.selectedService = service
                                }
                            }
                        }
                    }
                    
                    // MARK: Saat Seç
                    HStack {
                        sectionHeader("Saat Seçin")
                        Spacer()
                        HStack(spacing: 6) {
                            Circle().frame(width: 8, height: 8).foregroundColor(.yellow)
                            Text("DOLU").font(.caption).foregroundColor(.gray)
                        }
                    }
                    
                    if viewModel.isLoadingAvailability {
                        // Saatler sorgulanırken shimmer grid göster
                        ShimmerTimeGrid()
                    } else if viewModel.currentTimeSlots.isEmpty {
                        Text("Bu gün için müsait saat bulunamadı.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible()), count: 4),
                            spacing: 14
                        ) {
                            ForEach(viewModel.currentTimeSlots, id: \.self) { time in
                                let isPast    = TimeManager.isPastTime(selectedDate: viewModel.selectedDate, time: time)
                                let isBlocked = viewModel.blockedSlots.contains(time)
                                let disabled  = isPast || isBlocked
                                
                                TimeCard(
                                    time: time,
                                    isSelected: viewModel.selectedTime == time,
                                    disabled: disabled
                                )
                                .onTapGesture {
                                    if !disabled { viewModel.selectedTime = time }
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            
            // MARK: Onayla Butonu
            Button {
                // Doğrudan DB'ye kaydetmek yerine önce özet paneli göster
                showBookingSummary = true
            } label: {
                Text("Randevuyu Onayla")
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canConfirm ? Color.yellow : Color.gray.opacity(0.4))
                    .foregroundColor(canConfirm ? .black : .gray)
                    .cornerRadius(16)
            }
            .disabled(!canConfirm)
            .padding()
        }
        .background(Color(.systemBackground))
        .foregroundColor(.primary)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
        .task {
            await viewModel.fetchBookingData()
        }
        // MARK: Özet Bottom Sheet
        .sheet(isPresented: $showBookingSummary) {
            BookingSummarySheet(
                viewModel: viewModel,
                onConfirm: {
                    showBookingSummary = false
                    Task {
                        let success = await viewModel.createAppointment()
                        if success {
                            viewModel.resetSelection()
                            dismiss()
                        }
                    }
                },
                onEdit: {
                    // Sadece sheet'i kapat, seçimler korunuyor
                    showBookingSummary = false
                }
            )
            .presentationDetents([.medium])
            .presentationCornerRadius(28)
            .presentationDragIndicator(.visible)
        }
        

    }
    
    // MARK: - Helpers
    
    private var canConfirm: Bool {
        viewModel.selectedBarber != nil &&
        viewModel.selectedService != nil &&
        viewModel.selectedTime != nil &&
        !viewModel.availableDates.isEmpty
    }
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.title3)
            .fontWeight(.semibold)
    }
    
    private func loadingOrEmpty(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.vertical, 4)
    }
    
    // MARK: - Date Card
    
    struct DateCard: View {
        let date: Date
        let isSelected: Bool
        
        var body: some View {
            VStack(spacing: 4) {
                Text(DateManager.dayString(from: date)).font(.caption)
                Text(DateManager.dayNumber(from: date)).font(.title2).fontWeight(.bold)
            }
            .frame(width: 70, height: 80)
            .background(isSelected ? Color.yellow : Color(.systemGray6).opacity(0.6))
            .foregroundColor(isSelected ? .black : .primary)
            .cornerRadius(14)
        }
    }
    
    
    // MARK: - Barber Card
    
    struct BarberCard: View {
        let barber: Barber
        let isSelected: Bool
        
        var body: some View {
            VStack(spacing: 6) {
                ZStack {
                    // Daire 60x60'a küçültüldü — üst kesimleri önlemek için
                    Circle()
                        .fill(isSelected ? Color.yellow.opacity(0.25) : Color(.systemGray5))
                        .frame(width: 60, height: 60)
                        .overlay(Circle().stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 3))
                    
                    Text(barber.initials)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .yellow : .primary)
                }
                
                Text(barber.fullName)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 70)
                
                if barber.rating > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", barber.rating))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            // Sabit yükseklik + ek üst boşluk: scroll view'da kesilmeyi önler
            .frame(minHeight: 100)
            .padding(.top, 4)
        }
    }
    
    
    // MARK: - Service Select Card
    
    struct ServiceSelectCard: View {
        let service: Service
        let isSelected: Bool
        
        var body: some View {
            HStack(spacing: 14) {
                CachedAsyncImage(url: URL(string: service.imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        // Yükleniyor — shimmer
                        ShimmerCard(width: 54, height: 54, cornerRadius: 10)
                    default:
                        ZStack {
                            Color.gray.opacity(0.2)
                            Image(systemName: "scissors").foregroundColor(.gray)
                        }
                    }
                }
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .yellow : .primary)
                    HStack(spacing: 8) {
                        Label("\(service.duration) dk", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("·").foregroundColor(.secondary).font(.caption)
                        Text(service.category.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("₺\(service.price)")
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.yellow)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.yellow.opacity(0.08) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 1.5)
                    )
            )
        }
    }
    
    
    // MARK: - Time Card
    
    struct TimeCard: View {
        let time: String
        let isSelected: Bool
        let disabled: Bool
        
        var body: some View {
            Text(TimeManager.displayTime(time))
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    disabled ? Color.gray.opacity(0.12) :
                        isSelected ? Color.yellow :
                        Color(.systemGray6).opacity(0.6)
                )
                .foregroundColor(
                    disabled ? .gray :
                        isSelected ? .black : .primary
                )
                .cornerRadius(10)
        }
    }
    
    
    // MARK: - Booking Summary Sheet
    
    struct BookingSummarySheet: View {
        
        @ObservedObject var viewModel: AppointmentsViewModel
        let onConfirm: () -> Void
        let onEdit: () -> Void
        
        var body: some View {
            VStack(spacing: 0) {
                
                // Başlık
                Text("Randevu Özeti")
                    .font(.title3.bold())
                    .padding(.top, 90)
                    .padding(.bottom, 20)
                
                Divider()
                
                // Detay satırları
                VStack(spacing: 0) {
                    
                    summaryRow(
                        icon: "calendar",
                        label: "Tarih",
                        value: formattedDate
                    )
                    Divider().padding(.leading, 56)
                    
                    summaryRow(
                        icon: "clock.fill",
                        label: "Saat",
                        value: viewModel.selectedTime ?? "-"
                    )
                    Divider().padding(.leading, 56)
                    
                    summaryRow(
                        icon: "person.fill",
                        label: "Personel",
                        value: viewModel.selectedBarber?.fullName ?? "-"
                    )
                    Divider().padding(.leading, 56)
                    
                    summaryRow(
                        icon: "scissors",
                        label: "Hizmet",
                        value: viewModel.selectedService?.name ?? "-"
                    )
                    Divider().padding(.leading, 56)
                    
                    summaryRow(
                        icon: "turkishlirasign.circle.fill",
                        label: "Ücret",
                        value: viewModel.selectedService.map { "₺\($0.price)" } ?? "-",
                        valueColor: .yellow
                    )
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // Butonlar
                VStack(spacing: 10) {
                    
                    // ONAYLA — DB kaydı tetiklenir
                    Button(action: onConfirm) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView().tint(.black)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Randevuyu Onayla")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(16)
                    }
                    .disabled(viewModel.isLoading)
                    
                    // DÜZENLE — Sheet kapanır, seçimler korunur
                    Button(action: onEdit) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Düzenle")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(16)
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        
        // MARK: - Helpers
        
        private var formattedDate: String {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.locale = Locale(identifier: "tr_TR")
            let display = DateFormatter()
            display.dateFormat = "d MMMM EEEE"
            display.locale = Locale(identifier: "tr_TR")
            let str = DateManager.toString(viewModel.selectedDate)
            return df.date(from: str).map { display.string(from: $0) } ?? str
        }
        
        private func summaryRow(
            icon: String,
            label: String,
            value: String,
            valueColor: Color = .primary
        ) -> some View {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
                    .frame(width: 36)
                
                Text(label)
                    .foregroundColor(.secondary)
                    .frame(width: 70, alignment: .leading)
                
                Spacer()
                
                Text(value)
                    .fontWeight(.semibold)
                    .foregroundColor(valueColor)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
    }
}

#Preview {
    SelectAppointmentView()
        .environmentObject(AppointmentsViewModel())
}
