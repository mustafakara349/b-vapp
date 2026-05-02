//
//  FirestoreManager.swift
//  b&vapp
//
//  Created by Mustafa KARA on 29.03.2026.
//

import Foundation
import Firebase
import FirebaseFirestore

class FirestoreManager {

    static let shared = FirestoreManager()
    private let db = Firestore.firestore()
    private init() {}

    // MARK: - Fetch Collection

    /// Birden fazla whereField koşulu destekler.
    func fetchCollection<T: Codable>(
        _ collection: String,
        whereFields: [(field: String, value: Any)] = [],
        orderBy: String? = nil,
        descending: Bool = true
    ) async throws -> [T] {
        var query: Query = db.collection(collection)
        for condition in whereFields {
            query = query.whereField(condition.field, isEqualTo: condition.value)
        }
        if let order = orderBy {
            query = query.order(by: order, descending: descending)
        }
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: T.self) }
    }

    // MARK: - Fetch Single Document

    func fetchDocument<T: Codable>(
        _ collection: String,
        documentId: String
    ) async throws -> T? {
        let doc = try await db.collection(collection).document(documentId).getDocument()
        return try? doc.data(as: T.self)
    }

    // MARK: - Add Document (otomatik ID)

    func addDocument(
        _ collection: String,
        data: [String: Any]
    ) async throws -> String {
        let ref = try await db.collection(collection).addDocument(data: data)
        return ref.documentID
    }

    // MARK: - Update Document
    /// `updatedAt` alanı otomatik olarak `Timestamp()` ile güncellenir.
    func updateDocument(
        _ collection: String,
        documentId: String,
        data: [String: Any]
    ) async throws {
        var updateData = data
        updateData["updatedAt"] = Timestamp()
        try await db.collection(collection).document(documentId).updateData(updateData)
    }

    // MARK: - Delete Document

    func deleteDocument(
        _ collection: String,
        documentId: String
    ) async throws {
        try await db.collection(collection).document(documentId).delete()
    }

    // MARK: - Set Document (özel ID)

    func setDocument(
        _ collection: String,
        documentId: String,
        data: [String: Any],
        merge: Bool = false
    ) async throws {
        try await db.collection(collection).document(documentId).setData(data, merge: merge)
    }
}
