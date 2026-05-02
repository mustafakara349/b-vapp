//
//  AuthManager.swift
//  b&vapp
//
//  Created by Mustafa KARA on 10.03.2026.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthManager: ObservableObject {

    static let shared = AuthManager()

    private let auth = Auth.auth()
    private let db   = Firestore.firestore()

    @Published var currentUserId: String?
    @Published var isCheckingAuth: Bool = true
    /// Kayıt sonrası onboarding için — ProfilePhotoOnboardingView gösterilince false yapılır
    @Published var isNewlyRegistered: Bool = false

    private var authListener: AuthStateDidChangeListenerHandle?

    private init() {
        listenAuthState()
    }

    // MARK: - Auth State Listener

    private func listenAuthState() {
        authListener = auth.addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                self.currentUserId = user?.uid
                self.isCheckingAuth = false
            }
        }
    }

    // MARK: - Kullanıcı Kaydı

    func signUp(
        email: String,
        password: String,
        name: String,
        surname: String,
        phone: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        auth.createUser(withEmail: email, password: password) { result, error in

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let userId = result?.user.uid else { return }

            let now = Timestamp()
            let userData: [String: Any] = [
                "email": email,
                "name": name,
                "surname": surname,
                "phone": phone,
                "profileImageUrl": "",
                "role": "customer",
                "isActive": true,
                "createdAt": now,
                "updatedAt": now
            ]

            self.db.collection("users").document(userId).setData(userData) { err in
                if let err = err {
                    completion(.failure(err))
                } else {
                    // Kayıt başarılı → onboarding ekranı gösterilecek
                    DispatchQueue.main.async {
                        self.isNewlyRegistered = true
                    }
                    completion(.success(userId))
                }
            }
        }
    }

    // MARK: - Giriş Yapma

    func signIn(
        email: String,
        password: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        auth.signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let uid = result?.user.uid else { return }
            completion(.success(uid))
        }
    }

    // MARK: - Çıkış

    func signOut() throws {
        try auth.signOut()
    }

    // MARK: - Kullanıcı Bilgisi Güncelleme

    func updateUserProfile(
        name: String,
        surname: String,
        phone: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let userId = currentUserId else {
            completion(.failure(NSError(domain: "", code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "Kullanıcı bulunamadı."])))
            return
        }

        let data: [String: Any] = [
            "name": name,
            "surname": surname,
            "phone": phone,
            "updatedAt": Timestamp()
        ]

        db.collection("users").document(userId).updateData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Şifre Güncelleme

    func updatePassword(
        currentPassword: String,
        newPassword: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let user = auth.currentUser, let email = user.email else {
            completion(.failure(NSError(domain: "", code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "Kullanıcı bulunamadı."])))
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)

        user.reauthenticate(with: credential) { _, error in
            if error != nil {
                completion(.failure(NSError(domain: "", code: -1,
                                           userInfo: [NSLocalizedDescriptionKey: "Mevcut şifre hatalı."])))
                return
            }

            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
}
