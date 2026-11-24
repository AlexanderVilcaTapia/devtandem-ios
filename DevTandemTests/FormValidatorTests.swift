//
//  FormValidatorTests.swift
//  DevTandemTests
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation
import Testing
@testable import DevTandem

struct FormValidatorTests {

    // MARK: - Formularios de prueba

    /// Campos comunes válidos, con espacios y mayúsculas para comprobar la normalización.
    private func baseForm(role: UserRole) -> RegistrationForm {
        var form = RegistrationForm()
        form.name = "  Ana Torres "
        form.email = " Ana@Empresa.com "
        form.password = "clave1234"
        form.confirmPassword = "clave1234"
        form.role = role
        return form
    }

    private func validClientForm() -> RegistrationForm {
        var form = baseForm(role: .client)
        form.company = " Bodega Ana "
        form.industry = .retail
        form.projectType = .ecommerce
        return form
    }

    private func validJuniorForm() -> RegistrationForm {
        var form = baseForm(role: .junior)
        form.juniorExperience = .oneToTwoYears
        form.juniorTechnologies = "Swift, Firebase, swift"
        form.juniorGitHub = "github.com/anatorres"
        form.juniorAvailability = .tenToTwentyHours
        return form
    }

    private func validMentorForm() -> RegistrationForm {
        var form = baseForm(role: .mentor)
        form.mentorExperience = .fiveToEightYears
        form.mentorTechnologies = "Kotlin"
        form.mentorGitHub = "@anatorres"
        form.inviteCode = " mentor2026 "
        return form
    }

    /// Valida un formulario que debe fallar y devuelve los errores.
    private func errors(of form: RegistrationForm) -> [ValidationError] {
        do {
            _ = try FormValidator.validateRegistration(form)
            Issue.record("Se esperaba que la validación fallara")
            return []
        } catch {
            return error.errors
        }
    }

    // MARK: - Registro válido

    @Test("Cliente válido: datos normalizados y bloque client")
    func validClient() throws {
        let result = try FormValidator.validateRegistration(validClientForm())
        #expect(result.name == "Ana Torres")
        #expect(result.email == "ana@empresa.com")
        #expect(result.password == "clave1234")
        #expect(result.role == .client)
        #expect(result.details == .client(ClientProfile(
            company: "Bodega Ana",
            industry: .retail,
            projectType: .ecommerce,
            companySize: nil
        )))
    }

    @Test("El tamaño de empresa opcional se conserva si se eligió")
    func clientCompanySize() throws {
        var form = validClientForm()
        form.companySize = .small
        let result = try FormValidator.validateRegistration(form)
        guard case .client(let client) = result.details else {
            Issue.record("Se esperaba un perfil de cliente")
            return
        }
        #expect(client.companySize == .small)
    }

    @Test("Junior válido: tecnologías sin duplicados y GitHub normalizado")
    func validJunior() throws {
        let result = try FormValidator.validateRegistration(validJuniorForm())
        #expect(result.details == .junior(JuniorProfile(
            experience: .oneToTwoYears,
            technologies: ["Swift", "Firebase"],
            githubURL: "https://github.com/anatorres",
            availability: .tenToTwentyHours
        )))
    }

    @Test("Mentor válido: código en mayúsculas y disponibilidad opcional en nil")
    func validMentor() throws {
        let result = try FormValidator.validateRegistration(validMentorForm())
        #expect(result.details == .mentor(MentorProfile(
            experience: .fiveToEightYears,
            technologies: ["Kotlin"],
            githubURL: "https://github.com/anatorres",
            inviteCode: "MENTOR2026",
            availability: nil
        )))
    }

    @Test("makeProfile arma el perfil con la fecha indicada")
    func makeProfile() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let result = try FormValidator.validateRegistration(validMentorForm())
        let profile = result.makeProfile(createdAt: date)
        #expect(profile.name == "Ana Torres")
        #expect(profile.email == "ana@empresa.com")
        #expect(profile.createdAt == date)
        #expect(profile.role == .mentor)
        #expect(profile.details == result.details)
    }

    @Test("Solo se validan los campos del rol elegido")
    func ignoresOtherRoleSections() throws {
        var form = validClientForm()
        form.juniorGitHub = "no válido!"
        form.mentorTechnologies = ""
        form.inviteCode = ""
        _ = try FormValidator.validateRegistration(form)
    }

    // MARK: - Registro con errores

    @Test("Formulario vacío de cliente: todos los errores en el orden de la pantalla")
    func emptyClientForm() {
        var form = RegistrationForm()
        form.role = .client
        #expect(errors(of: form) == [
            .emptyName, .emptyEmail, .emptyPassword, .emptyConfirmPassword,
            .emptyCompany, .missingIndustry, .missingProjectType
        ])
    }

    @Test("Formulario vacío de junior")
    func emptyJuniorForm() {
        var form = RegistrationForm()
        form.role = .junior
        #expect(errors(of: form) == [
            .emptyName, .emptyEmail, .emptyPassword, .emptyConfirmPassword,
            .missingExperience, .emptyTechnologies, .emptyGitHub
        ])
    }

    @Test("Formulario vacío de mentor: también exige el código de invitación")
    func emptyMentorForm() {
        var form = RegistrationForm()
        form.role = .mentor
        #expect(errors(of: form) == [
            .emptyName, .emptyEmail, .emptyPassword, .emptyConfirmPassword,
            .missingExperience, .emptyTechnologies, .emptyGitHub, .emptyInviteCode
        ])
    }

    @Test("Un solo campo inválido produce un solo error")
    func singleError() {
        var form = validJuniorForm()
        form.juniorGitHub = "github.com/ana/repo"
        #expect(errors(of: form) == [.invalidGitHub])
    }

    @Test("Nombre y empresa demasiado largos se informan en el orden de la pantalla")
    func tooLongClientFields() {
        var form = validClientForm()
        form.name = String(repeating: "a", count: 81)
        form.company = String(repeating: "b", count: 101)
        #expect(errors(of: form) == [.nameTooLong(maximum: 80), .companyTooLong(maximum: 100)])
    }

    @Test("Un código de invitación con caracteres no permitidos no llega a Firebase")
    func invalidInviteCodeFormat() {
        var form = validMentorForm()
        form.inviteCode = "mentor.2026"
        #expect(errors(of: form) == [.invalidInviteCodeFormat(maximum: 40)])
    }

    @Test("Contraseña débil y confirmación distinta se informan juntas")
    func passwordErrors() {
        var form = validClientForm()
        form.password = "corta1"
        form.confirmPassword = "otra"
        #expect(errors(of: form) == [.passwordTooShort(minimum: 8), .passwordMismatch])
    }

    @Test("El error del formulario muestra el primer mensaje y lista todos los campos")
    func formErrorDescription() throws {
        var form = validMentorForm()
        form.email = "ana@"
        form.inviteCode = ""
        let error = try #require(throws: FormValidationError.self) {
            try FormValidator.validateRegistration(form)
        }
        #expect(error.errors == [.invalidEmail, .emptyInviteCode])
        #expect(error.fields == [.email, .inviteCode])
        #expect(error.localizedDescription == ValidationError.invalidEmail.errorDescription)
    }

    // MARK: - Login

    @Test("Login válido: correo normalizado y contraseña sin cambios")
    func validLogin() throws {
        let credentials = try FormValidator.validateLogin(email: " Ana@Empresa.com ", password: " abc ")
        #expect(credentials == LoginCredentials(email: "ana@empresa.com", password: " abc "))
    }

    @Test("Login no exige las reglas de fortaleza del registro")
    func loginAcceptsShortPassword() throws {
        _ = try FormValidator.validateLogin(email: "ana@empresa.com", password: "123")
    }

    @Test("Login vacío informa correo y contraseña")
    func emptyLogin() throws {
        let error = try #require(throws: FormValidationError.self) {
            try FormValidator.validateLogin(email: "", password: "")
        }
        #expect(error.errors == [.emptyEmail, .emptyPassword])
    }

    @Test("Login con correo inválido")
    func loginInvalidEmail() throws {
        let error = try #require(throws: FormValidationError.self) {
            try FormValidator.validateLogin(email: "ana@empresa", password: "clave1234")
        }
        #expect(error.errors == [.invalidEmail])
    }

    // MARK: - Recuperar contraseña

    @Test("Recuperar contraseña devuelve el correo normalizado")
    func validPasswordReset() throws {
        #expect(try FormValidator.validatePasswordReset(email: " Ana@Empresa.com") == "ana@empresa.com")
    }

    @Test("Recuperar contraseña con correo vacío o inválido", arguments: [
        ("", ValidationError.emptyEmail),
        ("ana@", ValidationError.invalidEmail)
    ])
    func invalidPasswordReset(email: String, expected: ValidationError) throws {
        let error = try #require(throws: FormValidationError.self) {
            try FormValidator.validatePasswordReset(email: email)
        }
        #expect(error.errors == [expected])
    }
}
