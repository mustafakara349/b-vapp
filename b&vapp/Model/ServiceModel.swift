//
//  ServiceModel.swift
//  b&vapp
//
//  Created by Mustafa KARA on 17.03.2026.
//

import Foundation

struct Service: Identifiable {
    let id = UUID()
    let name: String
    let price: Int
    let duration: Int
    let imageName: String
}
