//
//  Barber.swift
//  b&vapp
//
//  Created by Mustafa KARA on 14.03.2026.
//

import Foundation
import FirebaseFirestore

struct Barber: Identifiable, Codable {

    @DocumentID var id: String?

    var userId: String
    var fullName: String
    var description: String
    var workingDays: [String]   // ["monday","tuesday",...]
    var isActive: Bool
    var isAvailable: Bool
    var rating: Double
    var reviewCount: Int

    var createdAt: Date?
    var updatedAt: Date?

    // MARK: - Helpers

    /// "Baran Vural" → "BV"
    var initials: String {
        let parts = fullName.split(separator: " ")
        return parts.prefix(2).compactMap { $0.first }.map(String.init).joined()
    }
}
