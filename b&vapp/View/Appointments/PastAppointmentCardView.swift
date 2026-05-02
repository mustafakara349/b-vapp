//
//  PastAppointmentCardView.swift
//  b&vapp
//
//  Created by Mustafa KARA on 13.03.2026.
//

import SwiftUI

struct PastAppointmentCardView: View {

    let appointment: Appointment

    var body: some View {

        HStack(spacing: 14) {

            // Hizmet ikonu
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow.opacity(0.12))
                    .frame(width: 50, height: 50)
                Image(systemName: serviceIcon)
                    .font(.title3)
                    .foregroundColor(.yellow)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.serviceName)
                    .font(.headline)
                    .foregroundColor(.primary)

                if let barberName = appointment.barberName, !barberName.isEmpty {
                    Text(barberName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(appointment.shortDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("₺\(appointment.price)")
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)

                statusBadge
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }

    private var statusBadge: some View {
        let isCancelled = appointment.isCancelled
        return Text(isCancelled ? "İptal" : "Tamamlandı")
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(isCancelled ? Color.red.opacity(0.12) : Color.green.opacity(0.12))
            .foregroundColor(isCancelled ? .red : .green)
            .cornerRadius(6)
    }

    private var serviceIcon: String {
        let name = appointment.serviceName.lowercased()
        if name.contains("sakal") { return "mustache" }
        if name.contains("cilt") || name.contains("bakım") { return "sparkles" }
        if name.contains("boya") { return "paintbrush" }
        return "scissors"
    }
}
