//
//  ProfileView.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import SwiftUI

/// Pestaña "Perfil": datos reales de la cuenta y del rol, y el botón para cerrar sesión.
struct ProfileView: View {
    @Bindable var viewModel: HomeViewModel

    private var profile: UserProfile { viewModel.profile }

    var body: some View {
        List {
            Section {
                ProfileHeader(name: profile.name, role: profile.role)
                    .padding(.vertical, 4)
            }

            Section("Cuenta") {
                LabeledContent("Correo", value: profile.email)
                LabeledContent("Rol", value: profile.role.title)
                LabeledContent("Miembro desde", value: viewModel.memberSince)
            }

            roleSection

            Section {
                Button(role: .destructive) {
                    viewModel.requestSignOut()
                } label: {
                    HStack {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                        Spacer()
                        if viewModel.isSigningOut {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isSigningOut)
            } footer: {
                Text("Los pagos de DevTándem son simulados: no se mueve dinero real.")
            }
        }
        .confirmationDialog("¿Cerrar sesión?", isPresented: $viewModel.isConfirmingSignOut, titleVisibility: .visible) {
            Button("Cerrar sesión", role: .destructive) {
                viewModel.signOut()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Tendrás que ingresar de nuevo con tu correo y contraseña.")
        }
        .alert(
            "No se pudo cerrar la sesión",
            isPresented: $viewModel.isShowingSignOutError,
            presenting: viewModel.signOutError
        ) { _ in
            Button("Aceptar", role: .cancel) {}
        } message: { error in
            Text(error.errorDescription ?? "Inténtalo de nuevo.")
        }
    }

    // MARK: Datos del rol

    @ViewBuilder
    private var roleSection: some View {
        switch profile.details {
        case .client(let client):
            Section("Empresa") {
                LabeledContent("Nombre", value: client.company)
                LabeledContent("Rubro", value: client.industry.title)
                LabeledContent("Tipo de proyecto", value: client.projectType.title)
                if let size = client.companySize {
                    LabeledContent("Tamaño", value: size.title)
                }
            }
        case .junior(let junior):
            Section("Perfil de junior") {
                LabeledContent("Experiencia", value: junior.experience.title)
                if let availability = junior.availability {
                    LabeledContent("Disponibilidad", value: availability.title)
                }
                GitHubLink(urlString: junior.githubURL)
                technologiesRow(junior.technologies, tint: UserRole.junior.tint)
            }
        case .mentor(let mentor):
            Section("Perfil de mentor") {
                LabeledContent("Experiencia", value: mentor.experience.title)
                if let availability = mentor.availability {
                    LabeledContent("Revisión semanal", value: availability.title)
                }
                GitHubLink(urlString: mentor.githubURL)
                technologiesRow(mentor.technologies, tint: UserRole.mentor.tint)
            }
        }
    }

    private func technologiesRow(_ technologies: [String], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tecnologías")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TagCloud(tags: technologies, tint: tint)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
private extension ProfileView {
    static func preview(_ profile: UserProfile) -> some View {
        NavigationStack {
            ProfileView(viewModel: HomeViewModel(profile: profile, accountService: .preview(), onSignedOut: {}))
                .navigationTitle("Perfil")
        }
    }
}

#Preview("Perfil · cliente") {
    ProfileView.preview(.previewClient)
}

#Preview("Perfil · junior · oscuro") {
    ProfileView.preview(.previewJunior)
        .preferredColorScheme(.dark)
}

#Preview("Perfil · mentor · XXXL") {
    ProfileView.preview(.previewMentor)
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
