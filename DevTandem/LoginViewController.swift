//
//  LoginViewController.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 9/11/26.
//

import UIKit

/// Pantalla de inicio de sesión.
/// En la Parte A solo hay interfaz y navegación; la autenticación se conecta en la Parte B2.
final class LoginViewController: FormViewController {

    private static let showRegisterSegueID = "showRegister"

    // MARK: - Outlets

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var emailField: PaddedTextField!
    @IBOutlet private weak var passwordField: PaddedTextField!
    @IBOutlet private weak var rememberEmailSwitch: UISwitch!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var loginButton: UIButton!
    @IBOutlet private weak var forgotPasswordButton: UIButton!
    @IBOutlet private weak var createAccountButton: UIButton!

    // MARK: - Ciclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backButtonTitle = "Volver"

        keyboardScrollView = scrollView
        scrollView.keyboardDismissMode = .interactive

        emailField.configure(placeholder: "Correo electrónico", keyboard: .emailAddress, contentType: .emailAddress)
        passwordField.configure(placeholder: "Contraseña", contentType: .password, isSecure: true)
        configureFields([emailField, passwordField])
        passwordField.enablePasswordToggle()

        configureForgotPasswordFont()
        rememberEmailSwitch.accessibilityLabel = "Recordar mi correo"

        errorLabel.text = nil
        errorLabel.isHidden = true
        errorLabel.alpha = 0
        configureAccessibilityIdentifiers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func formDidRequestSubmit() {
        loginTapped(loginButton)
    }

    // MARK: - Acciones

    @IBAction private func loginTapped(_ sender: UIButton) {
        view.endEditing(true)
        // La validación y el login con Firebase se conectan en la Parte B2.
    }

    @IBAction private func forgotPasswordTapped(_ sender: UIButton) {
        view.endEditing(true)
        // El envío del correo de recuperación se conecta en la Parte B2.
    }

    // MARK: - Navegación

    /// Pasa el correo ya escrito a la pantalla de registro para no obligar a escribirlo dos veces.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == Self.showRegisterSegueID,
              let destination = segue.destination as? RegisterViewController
        else { return }
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        destination.prefilledEmail = email
    }

    // MARK: - Apariencia

    /// El enlace "¿Olvidaste tu contraseña?" va en tamaño pequeño (footnote).
    private func configureForgotPasswordFont() {
        guard var configuration = forgotPasswordButton.configuration else { return }
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .footnote)
            return outgoing
        }
        forgotPasswordButton.configuration = configuration
    }

    // MARK: - Accesibilidad / pruebas de UI

    private func configureAccessibilityIdentifiers() {
        emailField.accessibilityIdentifier = "login.emailField"
        passwordField.accessibilityIdentifier = "login.passwordField"
        rememberEmailSwitch.accessibilityIdentifier = "login.rememberEmailSwitch"
        errorLabel.accessibilityIdentifier = "login.errorLabel"
        loginButton.accessibilityIdentifier = "login.loginButton"
        forgotPasswordButton.accessibilityIdentifier = "login.forgotPasswordButton"
        createAccountButton.accessibilityIdentifier = "login.createAccountButton"
    }
}
