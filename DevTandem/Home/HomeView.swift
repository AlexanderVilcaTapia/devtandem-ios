//
//  HomeView.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import SwiftUI

/// Pantalla principal después del login: pestaña "Inicio" con el panel del rol y pestaña "Perfil".
struct HomeView: View {
    let viewModel: HomeViewModel

    var body: some View {
        TabView {
            NavigationStack {
                dashboard
                    .navigationTitle("Inicio")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Inicio", systemImage: "house.fill")
            }

            NavigationStack {
                ProfileView(viewModel: viewModel)
                    .navigationTitle("Perfil")
            }
            .tabItem {
                Label("Perfil", systemImage: "person.crop.circle")
            }
        }
        .tint(viewModel.profile.role.tint)
    }

    @ViewBuilder
    private var dashboard: some View {
        switch viewModel.profile.details {
        case .client(let client):
            ClientDashboardView(name: viewModel.profile.name, client: client)
        case .junior(let junior):
            JuniorDashboardView(name: viewModel.profile.name, junior: junior)
        case .mentor(let mentor):
            MentorDashboardView(name: viewModel.profile.name, mentor: mentor)
        }
    }
}

#if DEBUG
private extension HomeView {
    static func preview(_ profile: UserProfile) -> HomeView {
        HomeView(viewModel: HomeViewModel(profile: profile, accountService: .preview(), onSignedOut: {}))
    }
}

#Preview("Inicio · cliente") {
    HomeView.preview(.previewClient)
}

#Preview("Inicio · junior") {
    HomeView.preview(.previewJunior)
}

#Preview("Inicio · mentor") {
    HomeView.preview(.previewMentor)
}

#Preview("Inicio · mentor · oscuro") {
    HomeView.preview(.previewMentor)
        .preferredColorScheme(.dark)
}
#endif
