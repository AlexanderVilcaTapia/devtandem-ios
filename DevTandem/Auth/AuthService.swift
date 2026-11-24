//
//  AuthService.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation
import FirebaseAuth
import os

/// Usuario autenticado, sin exponer tipos de Firebase al resto de la app.
nonisolated struct AuthUser: Equatable {
    let uid: String
    let email: String?
}

/// Operaciones de autenticación con correo y contraseña.
/// Todas las fallas llegan como `AccountError`, ya traducidas al español.
protocol AuthService: AnyObject {
    /// uid del usuario con sesión abierta, o nil si no hay sesión.
    var currentUserID: String? { get }

    /// Crea la cuenta. Firebase deja la sesión abierta con el usuario nuevo.
    func createAccount(email: String, password: String) async throws(AccountError) -> AuthUser
    func signIn(email: String, password: String) async throws(AccountError) -> AuthUser
    func sendPasswordReset(email: String) async throws(AccountError)
    /// Borra el usuario con sesión abierta. Se usa para el rollback del registro.
    func deleteCurrentUser() async throws(AccountError)
    func signOut() throws(AccountError)
}

/// Implementación con Firebase Authentication.
final class FirebaseAuthService: AuthService {

    private let logger = Logger(subsystem: "com.devtandem.app", category: "AuthService")

    /// Se obtiene en cada uso (no en el init) para no tocar Firebase antes de `FirebaseApp.configure()`.
    private var auth: Auth { Auth.auth() }

    var currentUserID: String? { auth.currentUser?.uid }

    func createAccount(email: String, password: String) async throws(AccountError) -> AuthUser {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            return AuthUser(uid: result.user.uid, email: result.user.email)
        } catch {
            throw translate(error, operation: "createAccount")
        }
    }

    func signIn(email: String, password: String) async throws(AccountError) -> AuthUser {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            return AuthUser(uid: result.user.uid, email: result.user.email)
        } catch {
            throw translate(error, operation: "signIn")
        }
    }

    func sendPasswordReset(email: String) async throws(AccountError) {
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            throw translate(error, operation: "sendPasswordReset")
        }
    }

    func deleteCurrentUser() async throws(AccountError) {
        guard let user = auth.currentUser else {
            // Sin sesión no se puede borrar la cuenta: para el rollback cuenta como fallo.
            logger.error("deleteCurrentUser sin usuario con sesión abierta")
            throw .unexpected(code: AuthErrorCode.nullUser.rawValue)
        }
        do {
            try await user.delete()
        } catch {
            throw translate(error, operation: "deleteCurrentUser")
        }
    }

    func signOut() throws(AccountError) {
        do {
            try auth.signOut()
        } catch {
            throw translate(error, operation: "signOut")
        }
    }

    /// Traduce el error y registra solo la operación y el código: nunca correo, contraseña ni códigos.
    private func translate(_ error: Error, operation: String) -> AccountError {
        let nsError = error as NSError
        logger.error("\(operation, privacy: .public) falló: \(nsError.domain, privacy: .public) \(nsError.code, privacy: .public)")
        return AccountError.fromAuthError(error)
    }
}
