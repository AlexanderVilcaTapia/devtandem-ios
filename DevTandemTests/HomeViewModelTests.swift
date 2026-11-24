//
//  HomeViewModelTests.swift
//  DevTandemTests
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation
import Testing
@testable import DevTandem

@MainActor
struct HomeViewModelTests {

    let log = CallLog()
    let auth: FakeAuthService
    let viewModel: HomeViewModel
    /// Cuántas veces se avisó que la sesión se cerró.
    let signedOutCount: Counter

    /// Contador de referencia para comprobar el aviso desde el closure.
    @MainActor
    final class Counter {
        var value = 0
    }

    private static let profile = UserProfile(
        name: "Rosa Quispe",
        email: "rosa@ejemplo.com",
        createdAt: Date(timeIntervalSince1970: 1_700_000_000),
        details: .client(ClientProfile(company: "Panadería Santa Rosita", industry: .food,
                                       projectType: .ecommerce, companySize: nil))
    )

    init() {
        auth = FakeAuthService(log: log)
        let service = AccountService(auth: auth, profiles: FakeProfileRepository(log: log))
        let counter = Counter()
        signedOutCount = counter
        viewModel = HomeViewModel(profile: Self.profile, accountService: service) {
            counter.value += 1
        }
    }

    @Test("Pedir cerrar sesión solo muestra la confirmación")
    func requestShowsConfirmation() {
        viewModel.requestSignOut()

        #expect(viewModel.isConfirmingSignOut)
        #expect(log.entries.isEmpty)
        #expect(signedOutCount.value == 0)
    }

    @Test("Cerrar sesión con éxito avisa una vez y no deja error")
    func signOutSucceeds() {
        viewModel.signOut()

        #expect(log.entries == ["auth.signOut"])
        #expect(signedOutCount.value == 1)
        #expect(viewModel.signOutError == nil)
        #expect(!viewModel.isSigningOut)
    }

    @Test("Si falla, el error queda visible y no se vuelve al Login")
    func signOutFails() {
        auth.signOutError = .unexpected(code: 17995)
        viewModel.signOut()

        #expect(viewModel.signOutError == .unexpected(code: 17995))
        #expect(viewModel.isShowingSignOutError)
        #expect(signedOutCount.value == 0)
        #expect(!viewModel.isSigningOut)
    }

    @Test("Cerrar la alerta limpia el error")
    func dismissingAlertClearsError() {
        auth.signOutError = .network
        viewModel.signOut()
        viewModel.isShowingSignOutError = false

        #expect(viewModel.signOutError == nil)
    }

    @Test("Tras un fallo se puede reintentar y salir")
    func retryAfterFailure() {
        auth.signOutError = .network
        viewModel.signOut()
        auth.signOutError = nil
        viewModel.signOut()

        #expect(log.entries == ["auth.signOut", "auth.signOut"])
        #expect(signedOutCount.value == 1)
        #expect(viewModel.signOutError == nil)
    }
}

struct ProfileHeaderInitialsTests {

    @Test("Iniciales de las dos primeras palabras del nombre", arguments: [
        ("Rosa Quispe Huamán", "RQ"),
        ("diego mamani", "DM"),
        ("Lucía", "L"),
        ("  Ana   María  ", "AM"),
        ("Ñusta Ávila", "ÑÁ")
    ])
    func initials(name: String, expected: String) {
        #expect(ProfileHeader.initials(from: name) == expected)
    }

    @Test("Sin letras devuelve un signo de pregunta", arguments: ["", "   ", "123"])
    func noLetters(name: String) {
        #expect(ProfileHeader.initials(from: name) == "?")
    }
}
