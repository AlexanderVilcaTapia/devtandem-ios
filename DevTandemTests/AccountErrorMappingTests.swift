//
//  AccountErrorMappingTests.swift
//  DevTandemTests
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation
import Testing
@testable import DevTandem

/// Traducción de los NSError de Firebase a errores de la app. Los NSError se arman a mano
/// con los dominios y códigos reales de Firebase 13.2.0, sin red.
struct AccountErrorMappingTests {

    private static let authDomain = "FIRAuthErrorDomain"

    // MARK: - Firebase Authentication

    @Test("Códigos de Firebase Auth traducidos", arguments: [
        (17004, AccountError.invalidCredentials),   // invalidCredential
        (17009, AccountError.invalidCredentials),   // wrongPassword
        (17011, AccountError.invalidCredentials),   // userNotFound
        (17007, AccountError.emailAlreadyInUse),
        (17008, AccountError.invalidEmail),
        (17026, AccountError.weakPassword),
        (17020, AccountError.network),              // networkError
        (17010, AccountError.tooManyRequests),
        (17005, AccountError.userDisabled),
        (17006, AccountError.emailSignInDisabled)   // operationNotAllowed
    ])
    func authCodes(code: Int, expected: AccountError) {
        let error = NSError(domain: Self.authDomain, code: code)
        #expect(AccountError.fromAuthError(error) == expected)
    }

    @Test("Un código de Auth sin traducción propia es inesperado y conserva el número")
    func unknownAuthCode() {
        let error = NSError(domain: Self.authDomain, code: 17999) // internalError
        #expect(AccountError.fromAuthError(error) == .unexpected(code: 17999))
    }

    @Test("Un error de otro dominio no se confunde con uno de Auth")
    func otherDomain() {
        let error = NSError(domain: "OtroDominio", code: 17004)
        #expect(AccountError.fromAuthError(error) == .unexpected(code: 17004))
    }

    // MARK: - Realtime Database

    @Test("Escritura rechazada por las reglas")
    func databasePermissionDenied() {
        let error = NSError(domain: "com.firebase", code: 1)
        #expect(RemoteDataError.fromDatabaseError(error) == .permissionDenied)
    }

    @Test("Servicio no disponible cuenta como problema de red")
    func databaseUnavailable() {
        let error = NSError(domain: "com.firebase", code: 2)
        #expect(RemoteDataError.fromDatabaseError(error) == .network)
    }

    @Test("getData sin conexión")
    func getDataOffline() {
        let error = NSError(domain: "com.firebase.core", code: 1,
                            userInfo: [NSLocalizedFailureReasonErrorKey: "Client is offline."])
        #expect(RemoteDataError.fromDatabaseError(error) == .network)
    }

    @Test("getData rechazado por las reglas")
    func getDataPermissionDenied() {
        let error = NSError(domain: "com.firebase.core", code: 1,
                            userInfo: [NSLocalizedFailureReasonErrorKey: "permission_denied"])
        #expect(RemoteDataError.fromDatabaseError(error) == .permissionDenied)
    }

    @Test("Errores de URLSession cuentan como red")
    func urlError() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        #expect(RemoteDataError.fromDatabaseError(error) == .network)
    }

    @Test("Otros errores de la base son inesperados")
    func unknownDatabaseError() {
        #expect(RemoteDataError.fromDatabaseError(NSError(domain: "com.firebase", code: 3)) == .unexpected(code: 3))
        #expect(RemoteDataError.fromDatabaseError(NSError(domain: "x", code: 42)) == .unexpected(code: 42))
    }

    // MARK: - Mensajes

    static let allErrors: [AccountError] = [
        .invalidCredentials, .emailAlreadyInUse, .invalidEmail, .weakPassword, .network, .timeout,
        .tooManyRequests, .userDisabled, .emailSignInDisabled, .invalidInviteCode, .permissionDenied,
        .profileSaveFailed, .registrationIncomplete, .profileMissing, .unexpected(code: 17999)
    ]

    @Test("Todos los errores tienen mensaje y ninguno promete un canal de contacto", arguments: allErrors)
    func messages(error: AccountError) throws {
        let message = try #require(error.errorDescription)
        #expect(!message.isEmpty)
        #expect(!message.localizedCaseInsensitiveContains("escríbenos"))
    }

    @Test("El error inesperado muestra su código")
    func unexpectedShowsCode() {
        #expect(AccountError.unexpected(code: 17999).errorDescription?.contains("17999") == true)
    }

    @Test("Campos marcados por error de cuenta")
    func fields() {
        #expect(AccountError.emailAlreadyInUse.field == .email)
        #expect(AccountError.invalidEmail.field == .email)
        #expect(AccountError.weakPassword.field == .password)
        #expect(AccountError.invalidInviteCode.field == .inviteCode)
        #expect(AccountError.invalidCredentials.field == nil)
        #expect(AccountError.network.field == nil)
    }
}
