//
//  AccountError.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation
import FirebaseAuth

/// Error de las operaciones de cuenta (registro, login, recuperación, perfil), con su mensaje en español.
/// Las pantallas solo ven este tipo: los errores de Firebase se traducen antes de llegar a la UI.
nonisolated enum AccountError: LocalizedError, Equatable {
    case invalidCredentials
    case emailAlreadyInUse
    case invalidEmail
    case weakPassword
    case network
    case timeout
    case tooManyRequests
    case userDisabled
    case emailSignInDisabled
    case invalidInviteCode
    case permissionDenied
    /// Falló el guardado del perfil y se borró la cuenta recién creada (rollback correcto).
    case profileSaveFailed
    /// Falló el guardado del perfil y también el borrado de la cuenta: quedó una cuenta sin perfil.
    case registrationIncomplete
    /// La cuenta existe en Authentication pero no tiene perfil, o el perfil está incompleto.
    case profileMissing
    case unexpected(code: Int)

    /// Campo del formulario que hay que marcar, si el error corresponde a uno.
    var field: FormField? {
        switch self {
        case .emailAlreadyInUse, .invalidEmail:
            return .email
        case .weakPassword:
            return .password
        case .invalidInviteCode:
            return .inviteCode
        default:
            return nil
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Correo o contraseña incorrectos."
        case .emailAlreadyInUse:
            return "Ya existe una cuenta con ese correo. Inicia sesión o recupera tu contraseña."
        case .invalidEmail:
            return "El correo no es válido."
        case .weakPassword:
            return "La contraseña es demasiado débil. Usa al menos 8 caracteres con letras y números."
        case .network:
            return "Sin conexión. Revisa tu internet e intenta de nuevo."
        case .timeout:
            return "El servidor tardó demasiado en responder. Revisa tu conexión e intenta de nuevo."
        case .tooManyRequests:
            return "Demasiados intentos. Espera unos minutos e intenta de nuevo."
        case .userDisabled:
            return "Esta cuenta está deshabilitada. Contacta al administrador de DevTándem."
        case .emailSignInDisabled:
            return "El inicio de sesión con correo no está habilitado en Firebase. Contacta al administrador de DevTándem."
        case .invalidInviteCode:
            return "El código de invitación no es válido."
        case .permissionDenied:
            return "No tienes permiso para realizar esta acción."
        case .profileSaveFailed:
            return "No se pudo guardar tu perfil. No se creó la cuenta; intenta de nuevo."
        case .registrationIncomplete:
            return "No se pudo completar el registro y la cuenta quedó incompleta. Contacta al administrador de DevTándem para eliminarla."
        case .profileMissing:
            return "Tu cuenta existe pero no tiene un perfil completo. Contacta al administrador de DevTándem o regístrate con otro correo."
        case .unexpected(let code):
            return "Ocurrió un error inesperado (código \(code)). Intenta de nuevo."
        }
    }

    // MARK: - Traducción de errores de Firebase Authentication

    /// Traduce un error de Firebase Authentication. Los errores de Auth son `NSError` con dominio
    /// `AuthErrors.domain` ("FIRAuthErrorDomain") y un código de `AuthErrorCode`.
    ///
    /// `invalidCredential`, `wrongPassword` y `userNotFound` comparten mensaje: con la protección
    /// contra enumeración de correos activa, Firebase responde `invalidCredential` en los tres casos,
    /// y así la app tampoco revela si el correo está registrado.
    static func fromAuthError(_ error: Error) -> AccountError {
        let nsError = error as NSError
        guard nsError.domain == AuthErrors.domain,
              let code = AuthErrorCode(rawValue: nsError.code)
        else {
            return .unexpected(code: nsError.code)
        }

        switch code {
        case .invalidCredential, .wrongPassword, .userNotFound:
            return .invalidCredentials
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .invalidEmail:
            return .invalidEmail
        case .weakPassword:
            return .weakPassword
        case .networkError:
            return .network
        case .tooManyRequests:
            return .tooManyRequests
        case .userDisabled:
            return .userDisabled
        case .operationNotAllowed:
            return .emailSignInDisabled
        default:
            return .unexpected(code: nsError.code)
        }
    }
}
