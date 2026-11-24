//
//  AppRouter.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import UIKit
import SwiftUI
import os

/// Dueño de la ventana: decide la pantalla raíz (arranque, login o inicio) y hace las transiciones.
/// Comparte un único `AccountService` con todas las pantallas.
final class AppRouter {

    private let window: UIWindow
    private let accountService: AccountService
    private let logger = Logger(subsystem: "com.devtandem.app", category: "AppRouter")

    init(window: UIWindow, accountService: AccountService = AccountService()) {
        self.window = window
        self.accountService = accountService
    }

    /// Muestra la pantalla de arranque, que restaura la sesión y avisa el destino.
    func start() {
        let viewModel = LaunchViewModel(accountService: accountService) { [weak self] outcome in
            self?.handle(outcome)
        }
        setRoot(UIHostingController(rootView: LaunchView(viewModel: viewModel)), animated: false)
        window.makeKeyAndVisible()
    }

    private func handle(_ outcome: LaunchViewModel.Outcome) {
        switch outcome {
        case .signedIn(let profile):
            showHome(profile)
        case .signedOut(let notice):
            showLogin(notice: notice)
        }
    }

    // MARK: - Pantallas

    /// Login del Storyboard (con su UINavigationController y el registro).
    private func showLogin(notice: AccountError? = nil) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let navigation = storyboard.instantiateInitialViewController() as? UINavigationController,
              let login = navigation.viewControllers.first as? LoginViewController
        else {
            logger.fault("Main.storyboard no tiene un UINavigationController inicial con LoginViewController")
            assertionFailure("Main.storyboard no tiene un UINavigationController inicial con LoginViewController")
            setRoot(UIHostingController(rootView: StartupFailureView()), animated: true)
            return
        }
        login.accountService = accountService
        login.onLoginSucceeded = { [weak self] profile in
            self?.showHome(profile)
        }
        if let notice {
            login.showStartupError(notice)
        }
        setRoot(navigation, animated: true)
    }

    private func showHome(_ profile: UserProfile) {
        let viewModel = HomeViewModel(profile: profile, accountService: accountService) { [weak self] in
            self?.showLogin()
        }
        setRoot(UIHostingController(rootView: HomeView(viewModel: viewModel)), animated: true)
    }

    // MARK: - Transición

    /// Cambia la raíz con un fundido de 0,3 s, o sin animación si está activado "Reducir movimiento".
    private func setRoot(_ controller: UIViewController, animated: Bool) {
        // Una alerta presentada sobre la raíz anterior quedaría huérfana en la ventana.
        if let presented = window.rootViewController?.presentedViewController {
            presented.dismiss(animated: false)
        }

        guard animated, window.rootViewController != nil, !UIAccessibility.isReduceMotionEnabled else {
            window.rootViewController = controller
            return
        }
        UIView.transition(
            with: window,
            duration: 0.3,
            options: [.transitionCrossDissolve, .allowAnimatedContent]
        ) {
            UIView.performWithoutAnimation {
                self.window.rootViewController = controller
            }
        }
    }
}

/// Se muestra solo si el Storyboard no tiene el Login esperado (error de configuración del proyecto).
private struct StartupFailureView: View {
    var body: some View {
        ContentUnavailableView(
            "No se pudo abrir el inicio de sesión",
            systemImage: "exclamationmark.triangle",
            description: Text("Contacta al administrador de DevTándem.")
        )
    }
}
