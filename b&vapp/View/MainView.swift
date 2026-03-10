//
//  MainView.swift
//  b&vapp
//
//  Created by Mustafa KARA on 5.03.2026.
//

import SwiftUI

struct MainView: View {
    @State private var goToMain = false

    var body: some View {
        VStack {
            Text("Main View")
                .padding()
            
            Button {
                do {
                    try AuthManager.shared.signOut()
                    goToMain = true
                } catch {
                    print("Çıkış yapılırken hata oluştu: \(error.localizedDescription)")
                }
            } label: {
                Text("Çıkış Yap")
                    .font(.largeTitle)
            }
        }.navigationDestination(isPresented: $goToMain) {
            WelcomeView()
        }
    }
}

#Preview {
    MainView()
}
