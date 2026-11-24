//
//  HomeViewModel.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation
import Observation

/// Estado y acciones de la pantalla de inicio: el perfil con sesión abierta y el cierre de sesión
/// (con confirmación y error visible).
@MainActor
@Observable
final class HomeViewModel {
    let profile: UserProfile

    /// Muestra el diálogo "¿Cerrar sesión?".
    var isConfirmingSignOut = false
    private(set) var isSigningOut = false
    /// Error del último intento de cerrar sesión; se muestra en una alerta.
    var signOutError: AccountError?

    /// Para enlazar la alerta: al cerrarla se limpia el error.
    var isShowingSignOutError: Bool {
        get { signOutError != nil }
        set { if !newValue { signOutError = nil } }
    }

    @ObservationIgnored private let accountService: AccountService
    @ObservationIgnored private let onSignedOut: () -> Void

    init(profile: UserProfile, accountService: AccountService, onSignedOut: @escaping () -> Void) {
        self.profile = profile
        self.accountService = accountService
        self.onSignedOut = onSignedOut
    }

    /// Fecha de registro en formato largo según el idioma del dispositivo.
    var memberSince: String {
        profile.createdAt.formatted(date: .long, time: .omitted)
    }

    /// Pide confirmación antes de cerrar la sesión.
    func requestSignOut() {
        guard !isSigningOut else { return }
        isConfirmingSignOut = true
    }

    /// Cierra la sesión. Si sale bien, avisa para volver al Login; si falla, deja el error visible.
    func signOut() {
        guard !isSigningOut else { return }
        isSigningOut = true
        signOutError = nil

        do throws(AccountError) {
            try accountService.signOut()
        } catch {
            isSigningOut = false
            signOutError = error
            return
        }

        isSigningOut = false
        onSignedOut()
    }
}
