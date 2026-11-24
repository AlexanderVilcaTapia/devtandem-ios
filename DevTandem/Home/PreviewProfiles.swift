//
//  PreviewProfiles.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

#if DEBUG
import Foundation

/// Perfiles ficticios para los #Preview de Xcode. Solo existen en compilaciones de depuración.
extension UserProfile {
    static let previewClient = UserProfile(
        name: "Rosa Quispe Huamán",
        email: "rosa@ejemplo.com",
        createdAt: Date(timeIntervalSince1970: 1_790_000_000),
        details: .client(ClientProfile(
            company: "Panadería Santa Rosita",
            industry: .food,
            projectType: .ecommerce,
            companySize: .micro
        ))
    )

    static let previewJunior = UserProfile(
        name: "Diego Mamani",
        email: "diego@ejemplo.com",
        createdAt: Date(timeIntervalSince1970: 1_790_000_000),
        details: .junior(JuniorProfile(
            experience: .lessThanOneYear,
            technologies: ["Swift", "SwiftUI", "Firebase", "Git"],
            githubURL: "https://github.com/diego-ejemplo",
            availability: .tenToTwentyHours
        ))
    )

    static let previewMentor = UserProfile(
        name: "Lucía Paredes",
        email: "lucia@ejemplo.com",
        createdAt: Date(timeIntervalSince1970: 1_790_000_000),
        details: .mentor(MentorProfile(
            experience: .moreThanEightYears,
            technologies: ["Swift", "Kotlin", "Node.js", "PostgreSQL"],
            githubURL: "https://github.com/lucia-ejemplo",
            inviteCode: "EJEMPLO",
            availability: .fiveToTenHours
        ))
    )
}

/// Servicio de autenticación que no toca Firebase, para que los #Preview no dependan de la red
/// ni de `FirebaseApp.configure()`. Cerrar sesión siempre funciona; lo demás falla.
final class PreviewAuthService: AuthService {
    var currentUserID: String? { "uid-vista-previa" }

    func restoredUser() async -> AuthUser? { nil }

    func createAccount(email: String, password: String) async throws(AccountError) -> AuthUser {
        throw .unexpected(code: -1)
    }

    func signIn(email: String, password: String) async throws(AccountError) -> AuthUser {
        throw .unexpected(code: -1)
    }

    func sendPasswordReset(email: String) async throws(AccountError) {}

    func deleteCurrentUser() async throws(AccountError) {}

    func signOut() throws(AccountError) {}
}

/// Repositorio de perfiles sin Firebase, para los #Preview.
final class PreviewProfileRepository: ProfileRepository {
    func save(_ profile: UserProfile, uid: String) async throws(RemoteDataError) {}

    func fetchProfile(uid: String) async throws(RemoteDataError) -> UserProfile {
        throw .notFound
    }

    func discardPendingWrites() {}
}

extension AccountService {
    /// `AccountService` para los #Preview: no usa Firebase.
    static func preview() -> AccountService {
        AccountService(auth: PreviewAuthService(), profiles: PreviewProfileRepository())
    }
}
#endif
