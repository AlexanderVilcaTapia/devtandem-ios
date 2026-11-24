//
//  AccountServiceTests.swift
//  DevTandemTests
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation
import Testing
@testable import DevTandem

// MARK: - Dobles falsos

/// Registro compartido de llamadas, para comprobar el orden entre los tres servicios.
@MainActor
final class CallLog {
    var entries: [String] = []
}

@MainActor
final class FakeAuthService: AuthService {
    let log: CallLog
    var createResult: Result<AuthUser, AccountError> = .success(AuthUser(uid: "uid-nuevo", email: "ana@empresa.com"))
    var signInResult: Result<AuthUser, AccountError> = .success(AuthUser(uid: "uid-ana", email: "ana@empresa.com"))
    var resetError: AccountError?
    var deleteError: AccountError?
    var signOutError: AccountError?
    private(set) var receivedResetEmail: String?

    init(log: CallLog) { self.log = log }

    var restoredUserResult: AuthUser?

    var currentUserID: String? { restoredUserResult?.uid }

    func restoredUser() async -> AuthUser? {
        log.entries.append("auth.restoredUser")
        return restoredUserResult
    }

    func createAccount(email: String, password: String) async throws(AccountError) -> AuthUser {
        log.entries.append("auth.createAccount")
        switch createResult {
        case .success(let user): return user
        case .failure(let error): throw error
        }
    }

    func signIn(email: String, password: String) async throws(AccountError) -> AuthUser {
        log.entries.append("auth.signIn")
        switch signInResult {
        case .success(let user): return user
        case .failure(let error): throw error
        }
    }

    func sendPasswordReset(email: String) async throws(AccountError) {
        log.entries.append("auth.sendPasswordReset")
        receivedResetEmail = email
        if let resetError { throw resetError }
    }

    func deleteCurrentUser() async throws(AccountError) {
        log.entries.append("auth.deleteCurrentUser")
        if let deleteError { throw deleteError }
    }

    func signOut() throws(AccountError) {
        log.entries.append("auth.signOut")
        if let signOutError { throw signOutError }
    }
}

@MainActor
final class FakeProfileRepository: ProfileRepository {
    let log: CallLog
    var saveError: RemoteDataError?
    var fetchResult: Result<UserProfile, RemoteDataError> = .failure(.notFound)
    private(set) var saved: [(uid: String, profile: UserProfile)] = []

    init(log: CallLog) { self.log = log }

    func save(_ profile: UserProfile, uid: String) async throws(RemoteDataError) {
        log.entries.append("profiles.save")
        if let saveError { throw saveError }
        saved.append((uid, profile))
    }

    func fetchProfile(uid: String) async throws(RemoteDataError) -> UserProfile {
        log.entries.append("profiles.fetch")
        switch fetchResult {
        case .success(let profile): return profile
        case .failure(let error): throw error
        }
    }

    func discardPendingWrites() {
        log.entries.append("profiles.discardPendingWrites")
    }
}

// MARK: - Pruebas

@MainActor
struct AccountServiceTests {

    let log = CallLog()
    let auth: FakeAuthService
    let profiles: FakeProfileRepository
    let service: AccountService

    init() {
        auth = FakeAuthService(log: log)
        profiles = FakeProfileRepository(log: log)
        service = AccountService(auth: auth, profiles: profiles)
    }

    // MARK: Datos

    private func registration(role: UserRole) throws -> ValidatedRegistration {
        var form = RegistrationForm()
        form.name = "Ana Torres"
        form.email = "ana@empresa.com"
        form.password = "clave1234"
        form.confirmPassword = "clave1234"
        form.role = role
        switch role {
        case .client:
            form.company = "Bodega Ana"
            form.industry = .retail
            form.projectType = .ecommerce
        case .junior:
            form.juniorExperience = .noExperience
            form.juniorTechnologies = "Swift"
            form.juniorGitHub = "anatorres"
        case .mentor:
            form.mentorExperience = .moreThanEightYears
            form.mentorTechnologies = "Swift"
            form.mentorGitHub = "anatorres"
            form.inviteCode = "mentor2026"
        }
        return try FormValidator.validateRegistration(form)
    }

    private static let storedProfile = UserProfile(
        name: "Ana Torres",
        email: "ana@empresa.com",
        createdAt: Date(timeIntervalSince1970: 1_700_000_000),
        details: .junior(JuniorProfile(
            experience: .noExperience,
            technologies: ["Swift"],
            githubURL: "https://github.com/anatorres",
            availability: nil
        ))
    )

    private let credentials = LoginCredentials(email: "ana@empresa.com", password: "clave1234")

    // MARK: Registro

    @Test("Registro de cliente: crea la cuenta y guarda el perfil con su uid")
    func registerClient() async throws {
        let profile = try await service.register(try registration(role: .client))

        #expect(log.entries == ["auth.createAccount", "profiles.save"])
        #expect(profiles.saved.count == 1)
        #expect(profiles.saved.first?.uid == "uid-nuevo")
        #expect(profiles.saved.first?.profile == profile)
        #expect(profile.role == .client)
    }

    @Test("Registro de mentor: crea la cuenta y guarda el código normalizado en el perfil")
    func registerMentor() async throws {
        let profile = try await service.register(try registration(role: .mentor))
        #expect(log.entries == ["auth.createAccount", "profiles.save"])
        guard case .mentor(let mentor) = profile.details else {
            Issue.record("Se esperaba un perfil de mentor")
            return
        }
        #expect(mentor.inviteCode == "MENTOR2026")
    }

    @Test("Mentor rechazado por la regla: rollback y error de código de invitación")
    func mentorRejectedByRules() async throws {
        profiles.saveError = .permissionDenied
        let registration = try registration(role: .mentor)

        await #expect(throws: AccountError.invalidInviteCode) {
            try await service.register(registration)
        }
        #expect(log.entries == [
            "auth.createAccount", "profiles.save",
            "profiles.discardPendingWrites", "auth.deleteCurrentUser"
        ])
    }

    @Test("Cliente o junior rechazado por la regla: no se confunde con un código inválido",
          arguments: [UserRole.client, .junior])
    func nonMentorRejectedByRules(role: UserRole) async throws {
        profiles.saveError = .permissionDenied
        let registration = try registration(role: role)

        await #expect(throws: AccountError.profileSaveFailed) {
            try await service.register(registration)
        }
        #expect(log.entries.contains("auth.deleteCurrentUser"))
    }

    @Test("Mentor con falla de red o timeout: se informa el guardado, no el código",
          arguments: [RemoteDataError.network, .timeout, .unexpected(code: 9999)])
    func mentorOtherSaveFailures(saveError: RemoteDataError) async throws {
        profiles.saveError = saveError
        let registration = try registration(role: .mentor)

        await #expect(throws: AccountError.profileSaveFailed) {
            try await service.register(registration)
        }
    }

    @Test("Mentor rechazado y rollback fallido: la cuenta queda incompleta")
    func mentorRejectedAndRollbackFails() async throws {
        profiles.saveError = .permissionDenied
        auth.deleteError = .network
        let registration = try registration(role: .mentor)

        await #expect(throws: AccountError.registrationIncomplete) {
            try await service.register(registration)
        }
        #expect(log.entries.last == "auth.signOut")
    }

    @Test("Si falla la creación de la cuenta, no se guarda nada")
    func createAccountFails() async throws {
        auth.createResult = .failure(.emailAlreadyInUse)
        let registration = try registration(role: .client)

        await #expect(throws: AccountError.emailAlreadyInUse) {
            try await service.register(registration)
        }
        #expect(log.entries == ["auth.createAccount"])
    }

    @Test("Si falla el guardado, se descarta la escritura y se borra la cuenta (rollback)",
          arguments: [RemoteDataError.network, .timeout, .permissionDenied, .unexpected(code: 9999)])
    func rollbackOnSaveFailure(saveError: RemoteDataError) async throws {
        profiles.saveError = saveError
        let registration = try registration(role: .client)

        await #expect(throws: AccountError.profileSaveFailed) {
            try await service.register(registration)
        }
        #expect(log.entries == [
            "auth.createAccount", "profiles.save",
            "profiles.discardPendingWrites", "auth.deleteCurrentUser"
        ])
    }

    @Test("Si también falla el borrado, se cierra la sesión y la cuenta queda incompleta")
    func rollbackFails() async throws {
        profiles.saveError = .timeout
        auth.deleteError = .network
        let registration = try registration(role: .junior)

        await #expect(throws: AccountError.registrationIncomplete) {
            try await service.register(registration)
        }
        #expect(log.entries == [
            "auth.createAccount", "profiles.save",
            "profiles.discardPendingWrites", "auth.deleteCurrentUser", "auth.signOut"
        ])
    }

    @Test("Aunque falle el cierre de sesión tras un rollback fallido, el error es registrationIncomplete")
    func rollbackAndSignOutFail() async throws {
        profiles.saveError = .network
        auth.deleteError = .network
        auth.signOutError = .unexpected(code: 17995)
        let registration = try registration(role: .client)

        await #expect(throws: AccountError.registrationIncomplete) {
            try await service.register(registration)
        }
    }

    // MARK: Login

    @Test("Login correcto devuelve el perfil guardado")
    func loginSuccess() async throws {
        profiles.fetchResult = .success(Self.storedProfile)
        let profile = try await service.login(credentials)

        #expect(profile == Self.storedProfile)
        #expect(log.entries == ["auth.signIn", "profiles.fetch"])
    }

    @Test("Credenciales incorrectas: no se lee ningún perfil")
    func loginInvalidCredentials() async {
        auth.signInResult = .failure(.invalidCredentials)
        await #expect(throws: AccountError.invalidCredentials) {
            try await service.login(credentials)
        }
        #expect(log.entries == ["auth.signIn"])
    }

    @Test("Usuario sin perfil o con perfil incompleto: se cierra la sesión",
          arguments: [RemoteDataError.notFound, .incomplete])
    func loginWithoutProfile(fetchError: RemoteDataError) async {
        profiles.fetchResult = .failure(fetchError)
        await #expect(throws: AccountError.profileMissing) {
            try await service.login(credentials)
        }
        #expect(log.entries == ["auth.signIn", "profiles.fetch", "auth.signOut"])
    }

    @Test("Si no se puede leer el perfil, se informa el motivo y se cierra la sesión", arguments: [
        (RemoteDataError.network, AccountError.network),
        (RemoteDataError.timeout, AccountError.timeout),
        (RemoteDataError.permissionDenied, AccountError.permissionDenied),
        (RemoteDataError.unexpected(code: 7), AccountError.unexpected(code: 7))
    ])
    func loginFetchFails(fetchError: RemoteDataError, expected: AccountError) async {
        profiles.fetchResult = .failure(fetchError)
        await #expect(throws: expected) {
            try await service.login(credentials)
        }
        #expect(log.entries.last == "auth.signOut")
    }

    // MARK: Recuperación y cierre de sesión

    @Test("Recuperar contraseña envía el correo recibido")
    func passwordReset() async throws {
        try await service.sendPasswordReset(email: "ana@empresa.com")
        #expect(auth.receivedResetEmail == "ana@empresa.com")
    }

    @Test("Un error al recuperar la contraseña se propaga")
    func passwordResetFails() async {
        auth.resetError = .tooManyRequests
        await #expect(throws: AccountError.tooManyRequests) {
            try await service.sendPasswordReset(email: "ana@empresa.com")
        }
    }

    @Test("Cerrar sesión delega en AuthService y propaga su error")
    func signOut() throws {
        try service.signOut()
        #expect(log.entries == ["auth.signOut"])

        auth.signOutError = .unexpected(code: 17995)
        #expect(throws: AccountError.unexpected(code: 17995)) {
            try service.signOut()
        }
    }
}
