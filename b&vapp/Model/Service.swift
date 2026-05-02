//
//  Service.swift
//  b&vapp
//
//  Created by Mustafa KARA on 17.03.2026.
//

import Foundation
import FirebaseFirestore

struct Service: Identifiable, Codable {

    @DocumentID var id: String?

    var name: String
    var description: String
    var category: String        // "hair", vb.
    var duration: Int           // dakika
    var price: Int
    var imageUrl: String        // URL String
    var isActive: Bool

    var createdAt: Date?
    var updatedAt: Date?
}
