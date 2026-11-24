//
//  LaunchViewModel.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation
import Observation

/// Decide, al abrir la app, si hay una sesión guardada con perfil válido.
/// - Sin sesión: Login.
/// - Sesión y perfil: Inicio del rol.
/// - Sesión sin perfil: `AccountService` cierra la sesión y se va al Login con el aviso.
/// - Red, timeout, permiso o error inesperado: se queda en esta pantalla con "Reintentar" y
///   "Cerrar sesión", sin cerrar la sesión por su cuenta.
@MainActor
@Observable
final class LaunchViewModel {

    enum State: Equatable {
        case loading
        case failed(AccountError)
    }

    /// Resultado que recibe quien decide la pantalla raíz.
    enum Outcome: Equatable {
        /// Ir al Login, con un error para mostrar si la sesión se cerró por un problema del perfil.
        case signedOut(notice: AccountError?)
        case signedIn(UserProfile)
    }

    private(set) var state: State = .loading
    var isConfirmingSignOut = false
    /// Error al cerrar sesión desde la pantalla de error; se muestra en una alerta.
    var signOutError: AccountError?

    var isShowingSignOutError: Bool {
        get { signOutError != nil }
        set { if !newValue { signOutError = nil } }
    }

    @ObservationIgnored private let accountService: AccountService
    @ObservationIgnored private let onFinished: (Outcome) -> Void
    @ObservationIgnored private var hasStarted = false
    @ObservationIgnored private var isLoading = false

    init(accountService: AccountService, onFinished: @escaping (Outcome) -> Void) {
        self.accountService = accountService
        self.onFinished = onFinished
    }

    /// Primera carga. Llamarla otra vez (por ejemplo, si la vista reaparece) no repite la consulta.
    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        await load()
    }

    func retry() async {
        await load()
    }

    func requestSignOut() {
        isConfirmingSignOut = true
    }

    func signOut() {
        do throws(AccountError) {
            try accountService.signOut()
        } catch {
            signOutError = error
            return
        }
        onFinished(.signedOut(notice: nil))
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        state = .loading
        defer { isLoading = false }

        do throws(AccountError) {
            if let profile = try await accountService.restoreSession() {
                onFinished(.signedIn(profile))
            } else {
                onFinished(.signedOut(notice: nil))
            }
        } catch {
            if error == .profileMissing {
                onFinished(.signedOut(notice: error))
            } else {
                state = .failed(error)
            }
        }
    }
}
