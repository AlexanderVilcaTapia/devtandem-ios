//
//  AccountService.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation
import os

/// Casos de uso de la cuenta: registro con rollback, login con verificación del perfil,
/// recuperación de contraseña y cierre de sesión. Las pantallas solo hablan con esta clase.
/// Depende de protocolos, así que en los tests se arma con dobles falsos, sin red.
final class AccountService {

    private let auth: AuthService
    private let profiles: ProfileRepository
    private let logger = Logger(subsystem: "com.devtandem.app", category: "AccountService")

    init(
        auth: AuthService = FirebaseAuthService(),
        profiles: ProfileRepository = RealtimeProfileRepository()
    ) {
        self.auth = auth
        self.profiles = profiles
    }

    // MARK: - Registro

    /// 1. Crea la cuenta en Authentication.
    /// 2. Guarda el perfil en `/users/{uid}`. Las reglas de Realtime Database validan la estructura y,
    ///    para un mentor, que `mentor/inviteCode` exista en `/inviteCodes` (los clientes no pueden leerlo).
    /// 3. Si el guardado falla: descarta la escritura pendiente y borra la cuenta (rollback).
    ///    Si el borrado también falla, cierra la sesión y lanza `registrationIncomplete`.
    ///
    /// Si un mentor recibe `permissionDenied`, se informa `invalidInviteCode`. La app ya valida antes
    /// todo lo demás que exigen las reglas (formato, largos, opciones), así que el código es la única
    /// causa esperable. Costo: un código inválido crea y borra un usuario en Authentication.
    ///
    /// Devuelve el perfil guardado. Su `createdAt` es la hora local; en la base queda la del servidor.
    func register(_ registration: ValidatedRegistration) async throws(AccountError) -> UserProfile {
        let user = try await auth.createAccount(email: registration.email, password: registration.password)
        let profile = registration.makeProfile(createdAt: Date())

        do throws(RemoteDataError) {
            try await profiles.save(profile, uid: user.uid)
        } catch {
            logger.error("No se guardó el perfil (\(String(describing: error), privacy: .public)); se hace el rollback")
            try await rollbackNewAccount()
            if registration.role == .mentor, error == .permissionDenied {
                throw .invalidInviteCode
            }
            throw .profileSaveFailed
        }
        return profile
    }

    /// Lanza `registrationIncomplete` si no se pudo borrar la cuenta recién creada.
    private func rollbackNewAccount() async throws(AccountError) {
        profiles.discardPendingWrites()
        do throws(AccountError) {
            try await auth.deleteCurrentUser()
            logger.info("Rollback correcto: se borró la cuenta recién creada")
        } catch {
            logger.fault("Rollback fallido: la cuenta quedó sin perfil (\(String(describing: error), privacy: .public))")
            signOutQuietly()
            throw .registrationIncomplete
        }
    }

    // MARK: - Login

    /// Inicia sesión y lee el perfil. Si el perfil no existe, está incompleto o no se pudo leer,
    /// cierra la sesión: no se queda nadie con sesión abierta sin perfil.
    func login(_ credentials: LoginCredentials) async throws(AccountError) -> UserProfile {
        let user = try await auth.signIn(email: credentials.email, password: credentials.password)

        do throws(RemoteDataError) {
            return try await profiles.fetchProfile(uid: user.uid)
        } catch {
            logger.error("No se pudo leer el perfil tras el login (\(String(describing: error), privacy: .public))")
            signOutQuietly()
            switch error {
            case .notFound, .incomplete:
                throw .profileMissing
            case .network:
                throw .network
            case .timeout:
                throw .timeout
            case .permissionDenied:
                throw .permissionDenied
            case .unexpected(let code):
                throw .unexpected(code: code)
            }
        }
    }

    // MARK: - Otras operaciones

    func sendPasswordReset(email: String) async throws(AccountError) {
        try await auth.sendPasswordReset(email: email)
    }

    func signOut() throws(AccountError) {
        try auth.signOut()
    }

    /// Cierra la sesión cuando ya hay otro error que mostrar: si falla, solo se registra.
    private func signOutQuietly() {
        do throws(AccountError) {
            try auth.signOut()
        } catch {
            logger.error("No se pudo cerrar la sesión (\(String(describing: error), privacy: .public))")
        }
    }
}
