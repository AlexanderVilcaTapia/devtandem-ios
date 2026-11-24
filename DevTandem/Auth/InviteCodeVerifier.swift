//
//  InviteCodeVerifier.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation
import FirebaseDatabase
import os

/// Comprueba si un código de invitación de mentor es válido.
///
/// ⚠️ CAMBIO PREVISTO EN LA PARTE C2. El orden de la verificación va a cambiar.
/// - **Hoy (B2):** `AccountService` llama a este verificador **antes** de crear la cuenta. Lee
///   `/inviteCodes/{CÓDIGO}` sin sesión; funciona porque la base está en modo de prueba.
/// - **En C2:** las reglas no van a dejar que los clientes lean `/inviteCodes`. La validación pasa al
///   **guardado del perfil**: una regla en `/users/{uid}` exige que `mentor/inviteCode` exista en
///   `/inviteCodes`. Si no existe, el guardado falla con permission_denied y `AccountService` hace el
///   rollback (borra la cuenta recién creada) y muestra `AccountError.invalidInviteCode`.
///   Entonces esta verificación previa se elimina o se reemplaza.
///
/// Limitación conocida: los códigos son reutilizables y no se marcan como usados.
protocol InviteCodeVerifier: AnyObject {
    /// `code` ya viene normalizado (recortado y en mayúsculas) por `FieldValidators`.
    func isValid(_ code: String) async throws(AccountError) -> Bool
}

/// Implementación con Realtime Database: el código es válido si `/inviteCodes/{CÓDIGO}` vale `true`.
final class RealtimeInviteCodeVerifier: InviteCodeVerifier {

    private let logger = Logger(subsystem: "com.devtandem.app", category: "InviteCodeVerifier")

    /// Caracteres que Realtime Database no admite en una clave. Pasarlos a `child(_:)` hace caer la app.
    private static let forbiddenKeyCharacters = CharacterSet(charactersIn: ".#$[]/").union(.controlCharacters)

    func isValid(_ code: String) async throws(AccountError) -> Bool {
        guard !code.isEmpty, code.rangeOfCharacter(from: Self.forbiddenKeyCharacters) == nil else {
            return false
        }

        do {
            let snapshot = try await Database.database().reference(withPath: "inviteCodes").child(code).getData()
            return snapshot.value as? Bool == true
        } catch {
            // Nunca se registra el código: solo el dominio y el número del error.
            let nsError = error as NSError
            logger.error("isValid falló: \(nsError.domain, privacy: .public) \(nsError.code, privacy: .public)")
            switch RemoteDataError.fromDatabaseError(error) {
            case .network, .timeout:
                throw .network
            case .permissionDenied:
                throw .permissionDenied
            case .notFound, .incomplete:
                return false
            case .unexpected(let code):
                throw .unexpected(code: code)
            }
        }
    }
}
