//
//  LaunchView.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import SwiftUI

/// Pantalla de arranque: logo y "Cargando tu cuenta…" mientras se restaura la sesión.
/// Si falla la conexión, muestra el error con "Reintentar" y "Cerrar sesión".
struct LaunchView: View {
    @Bindable var viewModel: LaunchViewModel

    @ScaledMetric(relativeTo: .largeTitle) private var logoSize: CGFloat = 96

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    brand
                    switch viewModel.state {
                    case .loading:
                        ProgressView("Cargando tu cuenta…")
                            .controlSize(.large)
                    case .failed(let error):
                        errorContent(error)
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color.screenBackground)
        .task {
            await viewModel.start()
        }
        .onChange(of: viewModel.state) { _, newState in
            if case .failed(let error) = newState {
                AccessibilityNotification.Announcement(error.errorDescription ?? "No pudimos cargar tu cuenta.").post()
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

    private var brand: some View {
        VStack(spacing: 12) {
            Image(.logo)
                .resizable()
                .scaledToFit()
                .frame(width: logoSize, height: logoSize)
                .accessibilityHidden(true)
            Text("DevTándem")
                .font(.largeTitle.weight(.bold))
            Text("Talento junior, respaldo senior")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }

    private func errorContent(_ error: AccountError) -> some View {
        VStack(spacing: 16) {
            Label("No pudimos cargar tu cuenta", systemImage: "wifi.exclamationmark")
                .font(.headline)
                .foregroundStyle(.orange)
            Text(error.errorDescription ?? "Ocurrió un error inesperado.")
                .font(.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task { await viewModel.retry() }
            } label: {
                Text("Reintentar")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("Cerrar sesión", role: .destructive) {
                viewModel.requestSignOut()
            }
        }
        .frame(maxWidth: 420)
    }
}

#if DEBUG
#Preview("Arranque · cargando") {
    LaunchView(viewModel: LaunchViewModel(accountService: .preview(), onFinished: { _ in }))
}
#endif
