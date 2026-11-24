//
//  ValidationError.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation

/// Campo del formulario al que apunta un error, para que la UI lo marque en rojo.
/// Los campos de junior y mentor comparten caso (`githubURL`, `technologies`, `experience`):
/// solo una de las dos secciones está visible a la vez.
nonisolated enum FormField: Equatable, Hashable {
    case name
    case email
    case password
    case confirmPassword
    case company
    case industry
    case projectType
    case experience
    case technologies
    case githubURL
    case inviteCode
}

/// Un error de validación de un campo, con su mensaje en español.
nonisolated enum ValidationError: LocalizedError, Equatable {
    case emptyName
    case nameTooLong(maximum: Int)
    case emptyEmail
    case invalidEmail
    case emptyPassword
    case passwordTooShort(minimum: Int)
    case passwordMissingLetter
    case passwordMissingNumber
    case emptyConfirmPassword
    case passwordMismatch
    case emptyCompany
    case companyTooLong(maximum: Int)
    case missingIndustry
    case missingProjectType
    case missingExperience
    case emptyTechnologies
    case tooManyTechnologies(maximum: Int)
    case technologyTooLong(name: String, maximum: Int)
    case emptyGitHub
    case invalidGitHub
    case emptyInviteCode
    case invalidInviteCodeFormat(maximum: Int)

    /// Campo que hay que marcar en la UI.
    var field: FormField {
        switch self {
        case .emptyName, .nameTooLong:
            return .name
        case .emptyEmail, .invalidEmail:
            return .email
        case .emptyPassword, .passwordTooShort, .passwordMissingLetter, .passwordMissingNumber:
            return .password
        case .emptyConfirmPassword, .passwordMismatch:
            return .confirmPassword
        case .emptyCompany, .companyTooLong:
            return .company
        case .missingIndustry:
            return .industry
        case .missingProjectType:
            return .projectType
        case .missingExperience:
            return .experience
        case .emptyTechnologies, .tooManyTechnologies, .technologyTooLong:
            return .technologies
        case .emptyGitHub, .invalidGitHub:
            return .githubURL
        case .emptyInviteCode, .invalidInviteCodeFormat:
            return .inviteCode
        }
    }

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Ingresa tu nombre."
        case .nameTooLong(let maximum):
            return "El nombre admite hasta \(maximum) caracteres."
        case .emptyEmail:
            return "Ingresa tu correo electrónico."
        case .invalidEmail:
            return "Ingresa un correo válido, por ejemplo nombre@empresa.com."
        case .emptyPassword:
            return "Ingresa tu contraseña."
        case .passwordTooShort(let minimum):
            return "La contraseña debe tener al menos \(minimum) caracteres."
        case .passwordMissingLetter:
            return "La contraseña debe incluir al menos una letra."
        case .passwordMissingNumber:
            return "La contraseña debe incluir al menos un número."
        case .emptyConfirmPassword:
            return "Confirma tu contraseña."
        case .passwordMismatch:
            return "Las contraseñas no coinciden."
        case .emptyCompany:
            return "Ingresa el nombre de tu empresa."
        case .companyTooLong(let maximum):
            return "El nombre de la empresa admite hasta \(maximum) caracteres."
        case .missingIndustry:
            return "Elige el rubro de tu empresa."
        case .missingProjectType:
            return "Elige el tipo de proyecto que buscas."
        case .missingExperience:
            return "Elige tu tiempo de experiencia."
        case .emptyTechnologies:
            return "Ingresa al menos una tecnología, separadas por comas."
        case .tooManyTechnologies(let maximum):
            return "Ingresa como máximo \(maximum) tecnologías."
        case .technologyTooLong(let name, let maximum):
            return "\"\(name)\" es demasiado largo: cada tecnología admite hasta \(maximum) caracteres."
        case .emptyGitHub:
            return "Ingresa tu usuario o enlace de GitHub."
        case .invalidGitHub:
            return "Ingresa un usuario de GitHub válido o un enlace como https://github.com/usuario."
        case .emptyInviteCode:
            return "Ingresa tu código de invitación de mentor."
        case .invalidInviteCodeFormat(let maximum):
            return "El código de invitación solo admite letras sin tildes, números, guiones y guiones bajos (hasta \(maximum) caracteres)."
        }
    }
}

/// Resultado fallido de validar un formulario completo: todos los errores, en el orden de los campos.
/// La UI muestra el mensaje del primero y marca todos los campos de `fields`.
nonisolated struct FormValidationError: LocalizedError, Equatable {
    /// Nunca está vacío: solo se lanza cuando hay al menos un error.
    let errors: [ValidationError]

    var fields: [FormField] { errors.map(\.field) }

    var errorDescription: String? { errors.first?.errorDescription }
}
