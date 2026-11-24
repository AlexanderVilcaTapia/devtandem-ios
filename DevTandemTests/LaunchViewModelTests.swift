//
//  LaunchViewModelTests.swift
//  DevTandemTests
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation
import Testing
@testable import DevTandem

@MainActor
struct LaunchViewModelTests {

    let log = CallLog()
    let auth: FakeAuthService
    let profiles: FakeProfileRepository
    let viewModel: LaunchViewModel
    let outcomes: OutcomeRecorder

    /// Guarda los resultados que recibiría el router.
    @MainActor
    final class OutcomeRecorder {
        var values: [LaunchViewModel.Outcome] = []
    }

    private static let profile = UserProfile(
        name: "Diego Mamani",
        email: "diego@ejemplo.com",
        createdAt: Date(timeIntervalSince1970: 1_700_000_000),
        details: .junior(JuniorProfile(experience: .noExperience, technologies: ["Swift"],
                                       githubURL: "https://github.com/diego", availability: nil))
    )

    private static let user = AuthUser(uid: "uid-diego", email: "diego@ejemplo.com")

    init() {
        auth = FakeAuthService(log: log)
        profiles = FakeProfileRepository(log: log)
        let recorder = OutcomeRecorder()
        outcomes = recorder
        viewModel = LaunchViewModel(accountService: AccountService(auth: auth, profiles: profiles)) {
            recorder.values.append($0)
        }
    }

    @Test("Sin sesión guardada va al Login sin aviso")
    func withoutSession() async {
        await viewModel.start()
        #expect(outcomes.values == [.signedOut(notice: nil)])
    }

    @Test("Con sesión y perfil va al Inicio")
    func withProfile() async {
        auth.restoredUserResult = Self.user
        profiles.fetchResult = .success(Self.profile)

        await viewModel.start()
        #expect(outcomes.values == [.signedIn(Self.profile)])
    }

    @Test("Con sesión sin perfil va al Login con el aviso")
    func withoutProfile() async {
        auth.restoredUserResult = Self.user
        profiles.fetchResult = .failure(.notFound)

        await viewModel.start()
        #expect(outcomes.values == [.signedOut(notice: .profileMissing)])
        #expect(log.entries.contains("auth.signOut"))
    }

    @Test("Con falla de red se queda en la pantalla de error sin cerrar la sesión", arguments: [
        (RemoteDataError.network, AccountError.network),
        (RemoteDataError.timeout, AccountError.timeout),
        (RemoteDataError.permissionDenied, AccountError.permissionDenied)
    ])
    func networkFailure(fetchError: RemoteDataError, expected: AccountError) async {
        auth.restoredUserResult = Self.user
        profiles.fetchResult = .failure(fetchError)

        await viewModel.start()
        #expect(viewModel.state == .failed(expected))
        #expect(outcomes.values.isEmpty)
        #expect(!log.entries.contains("auth.signOut"))
    }

    @Test("Reintentar tras recuperar la conexión entra al Inicio")
    func retryAfterFailure() async {
        auth.restoredUserResult = Self.user
        profiles.fetchResult = .failure(.network)
        await viewModel.start()

        profiles.fetchResult = .success(Self.profile)
        await viewModel.retry()

        #expect(outcomes.values == [.signedIn(Self.profile)])
    }

    @Test("Llamar start dos veces consulta la sesión una sola vez")
    func startOnlyOnce() async {
        await viewModel.start()
        await viewModel.start()

        #expect(log.entries.filter { $0 == "auth.restoredUser" }.count == 1)
    }

    @Test("Cerrar sesión desde la pantalla de error va al Login")
    func signOutFromError() async {
        auth.restoredUserResult = Self.user
        profiles.fetchResult = .failure(.timeout)
        await viewModel.start()

        viewModel.signOut()
        #expect(outcomes.values == [.signedOut(notice: nil)])
    }

    @Test("Si cerrar sesión falla, se muestra el error y no se sale")
    func signOutFails() async {
        auth.restoredUserResult = Self.user
        profiles.fetchResult = .failure(.timeout)
        await viewModel.start()
        auth.signOutError = .unexpected(code: 17995)

        viewModel.signOut()
        #expect(viewModel.signOutError == .unexpected(code: 17995))
        #expect(viewModel.isShowingSignOutError)
        #expect(outcomes.values.isEmpty)
    }
}
