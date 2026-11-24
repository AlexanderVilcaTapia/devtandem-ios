//
//  FormValidator.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation

/// Registro ya validado y normalizado, listo para crear la cuenta y el perfil.
nonisolated struct ValidatedRegistration: Equatable {
    let name: String
    let email: String
    let password: String
    let details: RoleDetails

    var role: UserRole { details.role }

    /// Perfil a guardar en `/users/{uid}`. `createdAt` lo decide quien guarda (Parte C1).
    func makeProfile(createdAt: Date) -> UserProfile {
        UserProfile(name: name, email: email, createdAt: createdAt, details: details)
    }
}

/// Credenciales del login ya validadas (correo normalizado).
nonisolated struct LoginCredentials: Equatable {
    let email: String
    let password: String
}

/// Valida formularios completos. Revisa todos los campos y lanza `FormValidationError`
/// con todos los errores, en el orden en que aparecen en la pantalla.
nonisolated enum FormValidator {

    // MARK: - Registro

    static func validateRegistration(_ form: RegistrationForm) throws(FormValidationError) -> ValidatedRegistration {
        var errors: [ValidationError] = []

        var name = ""
        do throws(ValidationError) {
            name = try FieldValidators.normalizedName(form.name)
        } catch {
            errors.append(error)
        }

        var email = ""
        do throws(ValidationError) {
            email = try FieldValidators.normalizedEmail(form.email)
        } catch {
            errors.append(error)
        }

        do throws(ValidationError) {
            try FieldValidators.validateNewPassword(form.password)
        } catch {
            errors.append(error)
        }

        do throws(ValidationError) {
            try FieldValidators.validatePasswordConfirmation(form.confirmPassword, matches: form.password)
        } catch {
            errors.append(error)
        }

        let details: RoleDetails?
        switch form.role {
        case .client:
            details = validateClient(form, errors: &errors)
        case .junior:
            details = validateJunior(form, errors: &errors)
        case .mentor:
            details = validateMentor(form, errors: &errors)
        }

        guard errors.isEmpty, let details else {
            throw FormValidationError(errors: errors)
        }
        return ValidatedRegistration(name: name, email: email, password: form.password, details: details)
    }

    // MARK: - Login y recuperación

    static func validateLogin(email rawEmail: String, password: String) throws(FormValidationError) -> LoginCredentials {
        var errors: [ValidationError] = []

        var email = ""
        do throws(ValidationError) {
            email = try FieldValidators.normalizedEmail(rawEmail)
        } catch {
            errors.append(error)
        }

        do throws(ValidationError) {
            try FieldValidators.validateLoginPassword(password)
        } catch {
            errors.append(error)
        }

        guard errors.isEmpty else { throw FormValidationError(errors: errors) }
        return LoginCredentials(email: email, password: password)
    }

    /// Para "¿Olvidaste tu contraseña?": solo hace falta un correo válido. Devuelve el correo normalizado.
    static func validatePasswordReset(email rawEmail: String) throws(FormValidationError) -> String {
        do throws(ValidationError) {
            return try FieldValidators.normalizedEmail(rawEmail)
        } catch {
            throw FormValidationError(errors: [error])
        }
    }

    // MARK: - Secciones por rol
    // Cada una agrega sus errores a `errors` y devuelve nil si alguno de sus campos falló.

    private static func validateClient(_ form: RegistrationForm, errors: inout [ValidationError]) -> RoleDetails? {
        let initialCount = errors.count

        var company = ""
        do throws(ValidationError) {
            company = try FieldValidators.requiredText(form.company, emptyError: .emptyCompany)
        } catch {
            errors.append(error)
        }

        var industry: ClientIndustry?
        do throws(ValidationError) {
            industry = try FieldValidators.requiredSelection(form.industry, missingError: .missingIndustry)
        } catch {
            errors.append(error)
        }

        var projectType: ProjectType?
        do throws(ValidationError) {
            projectType = try FieldValidators.requiredSelection(form.projectType, missingError: .missingProjectType)
        } catch {
            errors.append(error)
        }

        guard errors.count == initialCount, let industry, let projectType else { return nil }
        return .client(ClientProfile(
            company: company,
            industry: industry,
            projectType: projectType,
            companySize: form.companySize
        ))
    }

    private static func validateJunior(_ form: RegistrationForm, errors: inout [ValidationError]) -> RoleDetails? {
        let initialCount = errors.count

        var experience: JuniorExperience?
        do throws(ValidationError) {
            experience = try FieldValidators.requiredSelection(form.juniorExperience, missingError: .missingExperience)
        } catch {
            errors.append(error)
        }

        var technologies: [String] = []
        do throws(ValidationError) {
            technologies = try FieldValidators.validatedTechnologies(form.juniorTechnologies)
        } catch {
            errors.append(error)
        }

        var githubURL = ""
        do throws(ValidationError) {
            githubURL = try FieldValidators.normalizedGitHubURL(form.juniorGitHub)
        } catch {
            errors.append(error)
        }

        guard errors.count == initialCount, let experience else { return nil }
        return .junior(JuniorProfile(
            experience: experience,
            technologies: technologies,
            githubURL: githubURL,
            availability: form.juniorAvailability
        ))
    }

    private static func validateMentor(_ form: RegistrationForm, errors: inout [ValidationError]) -> RoleDetails? {
        let initialCount = errors.count

        var experience: MentorExperience?
        do throws(ValidationError) {
            experience = try FieldValidators.requiredSelection(form.mentorExperience, missingError: .missingExperience)
        } catch {
            errors.append(error)
        }

        var technologies: [String] = []
        do throws(ValidationError) {
            technologies = try FieldValidators.validatedTechnologies(form.mentorTechnologies)
        } catch {
            errors.append(error)
        }

        var githubURL = ""
        do throws(ValidationError) {
            githubURL = try FieldValidators.normalizedGitHubURL(form.mentorGitHub)
        } catch {
            errors.append(error)
        }

        var inviteCode = ""
        do throws(ValidationError) {
            inviteCode = try FieldValidators.normalizedInviteCode(form.inviteCode)
        } catch {
            errors.append(error)
        }

        guard errors.count == initialCount, let experience else { return nil }
        return .mentor(MentorProfile(
            experience: experience,
            technologies: technologies,
            githubURL: githubURL,
            inviteCode: inviteCode,
            availability: form.mentorAvailability
        ))
    }
}
