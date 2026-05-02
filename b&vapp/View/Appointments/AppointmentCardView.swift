//
//  AppointmentCardView.swift
//  b&vapp
//
//  Created by Mustafa KARA on 13.03.2026.
//

import SwiftUI

struct AppointmentCardView: View {

    let appointment: Appointment
    var onCancel: (() -> Void)? = nil
    var onDirections: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // MARK: Üst Kısım
            HStack(spacing: 12) {

                // Hizmet ikonu
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: serviceIcon)
                        .font(.title3)
                        .foregroundColor(.yellow)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(appointment.serviceName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let barberName = appointment.barberName, !barberName.isEmpty {
                        Text(barberName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("₺\(appointment.price)")
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)

                    Text(appointment.statusLabel)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                }
            }

            Divider()

            // MARK: Tarih & Saat
            HStack(spacing: 6) {
                Image(systemName: "clock")
                Text(appointment.formattedDate)
                    .font(.subheadline)
            }
            .foregroundColor(.secondary)

            // MARK: Konum
            HStack(spacing: 6) {
                Image(systemName: "location")
                Text("B&V Coffee Barber – Tarsus/Mersin")
                    .font(.subheadline)
            }
            .foregroundColor(.secondary)

            // MARK: Butonlar
            HStack(spacing: 12) {
                Button { onCancel?() } label: {
                    Text("İptal Et")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red.opacity(0.6), lineWidth: 1)
                        )
                }

                Button { onDirections?() } label: {
                    Text("Yol Tarifi")
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.yellow)
                        .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemGray6))
        )
    }

    private var serviceIcon: String {
        let name = appointment.serviceName.lowercased()
        if name.contains("sakal") { return "mustache" }
        if name.contains("cilt") || name.contains("bakım") { return "sparkles" }
        if name.contains("boya") { return "paintbrush" }
        return "scissors"
    }
}
