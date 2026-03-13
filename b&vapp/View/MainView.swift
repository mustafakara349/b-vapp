//
//  MainView.swift
//  b&vapp
//
//  Created by Mustafa KARA on 5.03.2026.
//

import SwiftUI

struct MainView: View {
    
    var body: some View {
        
        TabView() {
            
            MainContentView()
                .tag(0)
                .tabItem {
                    Image(systemName: "house")
                    Text("Ana Sayfa")
                }
            
            AppointmentsView()
                .tag(1)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Randevular")
                }
            
            ServicesView()
                .tag(2)
                .tabItem {
                    Image(systemName: "scissors")
                    Text("Hizmetler")
                }

            ProfileView()
                .tag(3)
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profil")
                }
        }
    }
}

        
#Preview {
    MainView()
}
