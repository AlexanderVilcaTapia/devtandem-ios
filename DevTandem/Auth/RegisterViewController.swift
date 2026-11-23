//
//  RegisterViewController.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 17/11/26.
//

import UIKit

/// Pantalla de registro: campos comunes y una sección que cambia según el rol elegido.
/// En la Parte A solo hay interfaz; el registro real se conecta en la Parte B2.
final class RegisterViewController: FormViewController {

    /// Correo escrito en el login, recibido por el segue.
    var prefilledEmail: String?

    // MARK: - Outlets: comunes

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var nameField: PaddedTextField!
    @IBOutlet private weak var emailField: PaddedTextField!
    @IBOutlet private weak var passwordField: PaddedTextField!
    @IBOutlet private weak var confirmPasswordField: PaddedTextField!
    @IBOutlet private weak var roleSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var registerButton: UIButton!

    // MARK: - Outlets: secciones por rol

    @IBOutlet private weak var clientSection: UIStackView!
    @IBOutlet private weak var juniorSection: UIStackView!
    @IBOutlet private weak var mentorSection: UIStackView!

    // Cliente
    @IBOutlet private weak var companyField: PaddedTextField!
    @IBOutlet private weak var industryButton: UIButton!
    @IBOutlet private weak var projectTypeButton: UIButton!
    @IBOutlet private weak var companySizeButton: UIButton!

    // Junior
    @IBOutlet private weak var juniorExperienceButton: UIButton!
    @IBOutlet private weak var juniorTechnologiesField: PaddedTextField!
    @IBOutlet private weak var juniorGithubField: PaddedTextField!
    @IBOutlet private weak var juniorAvailabilityButton: UIButton!

    // Mentor
    @IBOutlet private weak var mentorExperienceButton: UIButton!
    @IBOutlet private weak var mentorTechnologiesField: PaddedTextField!
    @IBOutlet private weak var mentorGithubField: PaddedTextField!
    @IBOutlet private weak var inviteCodeField: PaddedTextField!
    @IBOutlet private weak var mentorAvailabilityButton: UIButton!

    // MARK: - Selecciones de los menús

    private var selectedIndustry: ClientIndustry?
    private var selectedProjectType: ProjectType?
    private var selectedCompanySize: CompanySize?
    private var selectedJuniorExperience: JuniorExperience?
    private var selectedJuniorAvailability: WeeklyAvailability?
    private var selectedMentorExperience: MentorExperience?
    private var selectedMentorAvailability: ReviewAvailability?

    // MARK: - Ciclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Registro"
        navigationItem.largeTitleDisplayMode = .never

        keyboardScrollView = scrollView
        scrollView.keyboardDismissMode = .interactive

        configureRoleControl()
        configureFieldTraits()
        configureFields([
            nameField, emailField, passwordField, confirmPasswordField,
            companyField,
            juniorTechnologiesField, juniorGithubField,
            mentorTechnologiesField, mentorGithubField, inviteCodeField
        ])
        passwordField.enablePasswordToggle()
        confirmPasswordField.enablePasswordToggle()
        configureMenus()

        if let prefilledEmail, !prefilledEmail.isEmpty {
            emailField.text = prefilledEmail
        }
        errorLabel.text = nil
        errorLabel.isHidden = true
        errorLabel.alpha = 0

        showSection(for: selectedRole, animated: false)
        configureAccessibilityIdentifiers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func formDidRequestSubmit() {
        registerTapped(registerButton)
    }

    // MARK: - Acciones

    @IBAction private func roleChanged(_ sender: UISegmentedControl) {
        view.endEditing(true)
        clearErrors(in: errorLabel)
        showSection(for: selectedRole, animated: true)
    }

    @IBAction private func registerTapped(_ sender: UIButton) {
        view.endEditing(true)
        // La validación y el registro con Firebase se conectan en la Parte B2.
    }

    @IBAction private func backToLoginTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Rol

    private var selectedRole: UserRole {
        let roles = UserRole.allCases
        let index = roleSegmentedControl.selectedSegmentIndex
        return roles.indices.contains(index) ? roles[index] : .client
    }

    private func configureRoleControl() {
        roleSegmentedControl.removeAllSegments()
        for (index, role) in UserRole.allCases.enumerated() {
            roleSegmentedControl.insertSegment(withTitle: role.title, at: index, animated: false)
        }
        roleSegmentedControl.selectedSegmentIndex = 0
        roleSegmentedControl.selectedSegmentTintColor = AppColor.accent
        roleSegmentedControl.setTitleTextAttributes([.foregroundColor: AppColor.onAccent], for: .selected)
    }

    /// Muestra solo la sección del rol elegido; las otras se ocultan y colapsan.
    private func showSection(for role: UserRole, animated: Bool) {
        let sections: [(UIStackView, UserRole)] = [
            (clientSection, .client),
            (juniorSection, .junior),
            (mentorSection, .mentor)
        ]
        let apply = {
            for (section, sectionRole) in sections {
                let shouldHide = sectionRole != role
                // Solo se asigna si cambia: reasignar el mismo valor a un arranged subview
                // deja al UIStackView con un estado de "oculto" inconsistente.
                if section.isHidden != shouldHide {
                    section.isHidden = shouldHide
                }
            }
        }
        if animated {
            // Un fundido sobre el scroll view evita animar isHidden de stacks anidados,
            // que deja las secciones encimadas.
            UIView.transition(
                with: scrollView,
                duration: 0.25,
                options: [.transitionCrossDissolve, .allowUserInteraction]
            ) {
                apply()
                self.view.layoutIfNeeded()
            }
        } else {
            apply()
        }
    }

    // MARK: - Campos de texto

    /// Placeholders y rasgos del teclado de cada campo, definidos por código.
    private func configureFieldTraits() {
        nameField.configure(placeholder: "Nombre completo", capitalization: .words, contentType: .name)
        emailField.configure(placeholder: "Correo electrónico", keyboard: .emailAddress, contentType: .emailAddress)
        passwordField.configure(placeholder: "Contraseña", contentType: .newPassword, isSecure: true)
        confirmPasswordField.configure(placeholder: "Confirmar contraseña", contentType: .newPassword, isSecure: true)

        companyField.configure(placeholder: "Nombre de la empresa", capitalization: .words, contentType: .organizationName)

        juniorTechnologiesField.configure(placeholder: "Tecnologías (separadas por comas)")
        juniorGithubField.configure(placeholder: "Enlace de GitHub (https://github.com/usuario)", keyboard: .URL, contentType: .URL)

        mentorTechnologiesField.configure(placeholder: "Tecnologías (separadas por comas)")
        mentorGithubField.configure(placeholder: "Enlace de GitHub (https://github.com/usuario)", keyboard: .URL, contentType: .URL)
        inviteCodeField.configure(placeholder: "Código de invitación", capitalization: .allCharacters)
    }

    // MARK: - Menús desplegables

    private func configureMenus() {
        configureMenu(for: industryButton, placeholder: "Rubro de la empresa") { [weak self] (option: ClientIndustry) in
            self?.selectedIndustry = option
        }
        configureMenu(for: projectTypeButton, placeholder: "Tipo de proyecto que buscas") { [weak self] (option: ProjectType) in
            self?.selectedProjectType = option
        }
        configureMenu(for: companySizeButton, placeholder: "Tamaño de la empresa (opcional)") { [weak self] (option: CompanySize) in
            self?.selectedCompanySize = option
        }
        configureMenu(for: juniorExperienceButton, placeholder: "Tiempo de experiencia") { [weak self] (option: JuniorExperience) in
            self?.selectedJuniorExperience = option
        }
        configureMenu(for: juniorAvailabilityButton, placeholder: "Disponibilidad semanal (opcional)") { [weak self] (option: WeeklyAvailability) in
            self?.selectedJuniorAvailability = option
        }
        configureMenu(for: mentorExperienceButton, placeholder: "Años de experiencia") { [weak self] (option: MentorExperience) in
            self?.selectedMentorExperience = option
        }
        configureMenu(for: mentorAvailabilityButton, placeholder: "Disponibilidad semanal de revisión (opcional)") { [weak self] (option: ReviewAvailability) in
            self?.selectedMentorAvailability = option
        }
    }

    /// Convierte un botón en un menú desplegable con las opciones del enum.
    private func configureMenu<Option: FormOption>(
        for button: UIButton,
        placeholder: String,
        onSelect: @escaping (Option) -> Void
    ) {
        var configuration = button.configuration ?? UIButton.Configuration.gray()
        configuration.title = placeholder
        configuration.image = UIImage(systemName: "chevron.up.chevron.down")
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 8
        configuration.baseForegroundColor = .secondaryLabel
        button.configuration = configuration

        let actions = Option.allCases.map { option in
            UIAction(title: option.title) { [weak button] _ in
                button?.configuration?.title = option.title
                button?.configuration?.baseForegroundColor = .label
                onSelect(option)
            }
        }
        button.menu = UIMenu(children: actions)
        button.showsMenuAsPrimaryAction = true
        // El título lo actualizamos nosotros; así se conserva el placeholder hasta que el usuario elija.
        button.changesSelectionAsPrimaryAction = false
    }

    // MARK: - Accesibilidad / pruebas de UI

    private func configureAccessibilityIdentifiers() {
        nameField.accessibilityIdentifier = "register.nameField"
        emailField.accessibilityIdentifier = "register.emailField"
        passwordField.accessibilityIdentifier = "register.passwordField"
        confirmPasswordField.accessibilityIdentifier = "register.confirmPasswordField"
        roleSegmentedControl.accessibilityIdentifier = "register.roleSegmentedControl"
        companyField.accessibilityIdentifier = "register.companyField"
        industryButton.accessibilityIdentifier = "register.industryButton"
        projectTypeButton.accessibilityIdentifier = "register.projectTypeButton"
        companySizeButton.accessibilityIdentifier = "register.companySizeButton"
        juniorExperienceButton.accessibilityIdentifier = "register.juniorExperienceButton"
        juniorTechnologiesField.accessibilityIdentifier = "register.juniorTechnologiesField"
        juniorGithubField.accessibilityIdentifier = "register.juniorGithubField"
        juniorAvailabilityButton.accessibilityIdentifier = "register.juniorAvailabilityButton"
        mentorExperienceButton.accessibilityIdentifier = "register.mentorExperienceButton"
        mentorTechnologiesField.accessibilityIdentifier = "register.mentorTechnologiesField"
        mentorGithubField.accessibilityIdentifier = "register.mentorGithubField"
        inviteCodeField.accessibilityIdentifier = "register.inviteCodeField"
        mentorAvailabilityButton.accessibilityIdentifier = "register.mentorAvailabilityButton"
        errorLabel.accessibilityIdentifier = "register.errorLabel"
        registerButton.accessibilityIdentifier = "register.registerButton"
    }
}
