//
//  LoginViewController.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 9/11/26.
//

import UIKit

/// Pantalla de inicio de sesión: login con Firebase, "Recordar mi correo" y recuperación de contraseña.
final class LoginViewController: FormViewController {

    private static let showRegisterSegueID = "showRegister"

    // MARK: - Dependencias

    /// Se crea al primer uso: la pantalla sale del Storyboard y no recibe dependencias en el init.
    lazy var accountService = AccountService()
    var rememberedEmailStore = RememberedEmailStore()

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
        controlsDisabledWhileLoading = [loginButton, forgotPasswordButton, createAccountButton, rememberEmailSwitch]

        configureForgotPasswordFont()
        rememberEmailSwitch.accessibilityLabel = "Recordar mi correo"
        loadRememberedEmail()

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

    // MARK: - Login

    @IBAction private func loginTapped(_ sender: UIButton) {
        view.endEditing(true)
        guard !isLoading else { return }
        clearErrors(in: errorLabel)

        let credentials: LoginCredentials
        do throws(FormValidationError) {
            credentials = try FormValidator.validateLogin(
                email: emailField.text ?? "",
                password: passwordField.text ?? ""
            )
        } catch {
            showValidationError(error)
            return
        }

        let remember = rememberEmailSwitch.isOn
        setLoading(true, on: loginButton, loadingTitle: "Ingresando…")
        Task { [weak self] in
            guard let self else { return }
            let result: Result<UserProfile, AccountError>
            do throws(AccountError) {
                result = .success(try await self.accountService.login(credentials))
            } catch {
                result = .failure(error)
            }
            // Primero se quita la carga: con los campos deshabilitados, showError no podría enfocarlos.
            self.setLoading(false, on: self.loginButton, loadingTitle: "")

            switch result {
            case .success(let profile):
                // "Recordar mi correo" solo se aplica tras un login exitoso.
                self.rememberedEmailStore.update(email: credentials.email, remember: remember)
                self.passwordField.text = nil
                self.showWelcome(profile)
            case .failure(let error):
                self.showAccountError(error)
            }
        }
    }

    /// Provisional hasta la Parte D, que llevará a la pantalla de inicio de cada rol.
    private func showWelcome(_ profile: UserProfile) {
        presentInfoAlert(
            title: "Sesión iniciada",
            message: "Hola, \(profile.name). Ingresaste como \(profile.role.title)."
        )
    }

    // MARK: - Recuperar contraseña

    @IBAction private func forgotPasswordTapped(_ sender: UIButton) {
        view.endEditing(true)
        guard !isLoading else { return }
        clearErrors(in: errorLabel)

        let email: String
        do throws(FormValidationError) {
            email = try FormValidator.validatePasswordReset(email: emailField.text ?? "")
        } catch {
            showValidationError(error)
            return
        }

        let alert = UIAlertController(
            title: "Recuperar contraseña",
            message: "Te enviaremos un enlace a \(email) para restablecer tu contraseña.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Enviar", style: .default) { [weak self] _ in
            self?.sendPasswordReset(to: email)
        })
        present(alert, animated: true)
    }

    private func sendPasswordReset(to email: String) {
        setLoading(true, on: forgotPasswordButton, loadingTitle: "Enviando…")
        Task { [weak self] in
            guard let self else { return }
            let failure: AccountError?
            do throws(AccountError) {
                try await self.accountService.sendPasswordReset(email: email)
                failure = nil
            } catch {
                failure = error
            }
            self.setLoading(false, on: self.forgotPasswordButton, loadingTitle: "")

            if let failure {
                self.showAccountError(failure)
            } else {
                // Mensaje neutro: con la protección contra enumeración, Firebase no avisa si el correo no existe.
                self.presentInfoAlert(
                    title: "Revisa tu correo",
                    message: "Si existe una cuenta con ese correo, te enviamos un enlace para restablecer tu contraseña."
                )
            }
        }
    }

    // MARK: - Recordar mi correo

    private func loadRememberedEmail() {
        if let email = rememberedEmailStore.rememberedEmail {
            emailField.text = email
            rememberEmailSwitch.isOn = true
        } else {
            rememberEmailSwitch.isOn = false
        }
    }

    // MARK: - Errores

    private func showValidationError(_ error: FormValidationError) {
        let fields = error.fields.compactMap(textField(for:))
        showError(error.localizedDescription, in: errorLabel, invalidFields: fields)
    }

    private func showAccountError(_ error: AccountError) {
        let fields = error.field.flatMap(textField(for:)).map { [$0] } ?? []
        showError(error.localizedDescription, in: errorLabel, invalidFields: fields)
    }

    private func textField(for field: FormField) -> PaddedTextField? {
        switch field {
        case .email: return emailField
        case .password: return passwordField
        default: return nil
        }
    }

    private func presentInfoAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Aceptar", style: .default))
        present(alert, animated: true)
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
