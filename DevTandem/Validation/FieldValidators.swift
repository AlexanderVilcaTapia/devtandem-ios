//
//  FieldValidators.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation

/// Validaciones y normalizaciones de un solo campo. Son funciones puras (sin UI ni Firebase):
/// reciben el texto tal cual lo escribió el usuario y devuelven el valor listo para guardar,
/// o lanzan el `ValidationError` correspondiente.
nonisolated enum FieldValidators {

    static let minimumPasswordLength = 8
    static let maximumTechnologies = 15
    static let maximumTechnologyLength = 30
    static let maximumNameLength = 80
    static let maximumCompanyLength = 100
    static let maximumInviteCodeLength = 40
    static let gitHubProfilePrefix = "https://github.com/"

    // Los límites coinciden con las reglas de Realtime Database (firebase/database.rules.json).
    // Si la app aceptara algo que la regla rechaza, el guardado daría permission_denied y,
    // para un mentor, se confundiría con un código de invitación inválido.
    //
    // Los largos se miden en unidades UTF-16: nunca dan menos que los caracteres visibles ni que
    // los puntos de código, así que la app nunca es más permisiva que la regla.
    // (La documentación de Firebase no dice en qué unidad cuenta `length`.)
    static func textLength(_ text: String) -> Int {
        text.utf16.count
    }

    // MARK: - Texto obligatorio

    /// Recorta espacios y saltos de línea; si queda vacío, lanza `error`.
    static func requiredText(_ raw: String, emptyError error: ValidationError) throws(ValidationError) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw error }
        return trimmed
    }

    /// Devuelve la opción elegida en un menú o lanza `error` si no se eligió ninguna.
    static func requiredSelection<Option>(_ option: Option?, missingError error: ValidationError) throws(ValidationError) -> Option {
        guard let option else { throw error }
        return option
    }

    static func normalizedName(_ raw: String) throws(ValidationError) -> String {
        let name = try requiredText(raw, emptyError: .emptyName)
        guard textLength(name) <= maximumNameLength else {
            throw .nameTooLong(maximum: maximumNameLength)
        }
        return name
    }

    static func normalizedCompany(_ raw: String) throws(ValidationError) -> String {
        let company = try requiredText(raw, emptyError: .emptyCompany)
        guard textLength(company) <= maximumCompanyLength else {
            throw .companyTooLong(maximum: maximumCompanyLength)
        }
        return company
    }

    // MARK: - Correo

    /// Formato pragmático `usuario@dominio.ext`: sin espacios, una sola arroba,
    /// dominio con al menos un punto y extensión de 2 o más letras. Se guarda en minúsculas.
    private static let emailPattern = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*\\.[A-Za-z]{2,}$"

    static func normalizedEmail(_ raw: String) throws(ValidationError) -> String {
        let email = try requiredText(raw, emptyError: .emptyEmail).lowercased()
        guard matches(email, pattern: emailPattern),
              !email.contains(".."),
              !email.hasPrefix("."),
              !email.contains(".@"),
              !email.contains("@.")
        else { throw .invalidEmail }
        return email
    }

    // MARK: - Contraseña

    /// Reglas del registro: mínimo 8 caracteres, al menos una letra y al menos un dígito.
    /// La contraseña no se recorta: los espacios son parte de ella.
    /// Si incumple varias reglas, se informa la primera (largo, letra, número).
    static func validateNewPassword(_ password: String) throws(ValidationError) {
        guard !password.isEmpty else { throw .emptyPassword }
        guard password.count >= minimumPasswordLength else {
            throw .passwordTooShort(minimum: minimumPasswordLength)
        }
        guard password.contains(where: \.isLetter) else { throw .passwordMissingLetter }
        guard password.contains(where: { $0.isASCII && $0.isNumber }) else { throw .passwordMissingNumber }
    }

    static func validatePasswordConfirmation(_ confirmation: String, matches password: String) throws(ValidationError) {
        guard !confirmation.isEmpty else { throw .emptyConfirmPassword }
        guard confirmation == password else { throw .passwordMismatch }
    }

    /// En el login solo se exige que no esté vacía: las reglas de fortaleza son del registro.
    static func validateLoginPassword(_ password: String) throws(ValidationError) {
        guard !password.isEmpty else { throw .emptyPassword }
    }

    // MARK: - Tecnologías

    /// Separa por comas, recorta, quita vacíos y duplicados (sin distinguir mayúsculas),
    /// conservando el orden y la forma de la primera aparición. No valida límites.
    static func parseTechnologies(_ raw: String) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for piece in raw.split(separator: ",", omittingEmptySubsequences: true) {
            let technology = piece.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !technology.isEmpty else { continue }
            let key = technology.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(technology)
        }
        return result
    }

    /// Lista de tecnologías válida: al menos 1, máximo 15, cada una de hasta 30 caracteres.
    static func validatedTechnologies(_ raw: String) throws(ValidationError) -> [String] {
        let technologies = parseTechnologies(raw)
        guard !technologies.isEmpty else { throw .emptyTechnologies }
        guard technologies.count <= maximumTechnologies else {
            throw .tooManyTechnologies(maximum: maximumTechnologies)
        }
        if let tooLong = technologies.first(where: { textLength($0) > maximumTechnologyLength }) {
            throw .technologyTooLong(name: tooLong, maximum: maximumTechnologyLength)
        }
        return technologies
    }

    // MARK: - GitHub

    /// Reglas de nombres de usuario de GitHub: 1 a 39 caracteres, letras, números y guiones,
    /// sin guion al inicio ni al final y sin dos guiones seguidos.
    private static let gitHubUsernamePattern = "^[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}$"

    /// Acepta `usuario`, `@usuario`, `github.com/usuario`, `www.github.com/usuario` y las mismas
    /// formas con `http://` o `https://`, con o sin `/` final. Rechaza rutas de repositorio
    /// y otros dominios. Devuelve siempre `https://github.com/usuario`, respetando mayúsculas.
    static func normalizedGitHubURL(_ raw: String) throws(ValidationError) -> String {
        var remainder = try requiredText(raw, emptyError: .emptyGitHub)
        var hadScheme = false

        for scheme in ["https://", "http://"] where remainder.lowercased().hasPrefix(scheme) {
            remainder = String(remainder.dropFirst(scheme.count))
            hadScheme = true
            break
        }
        if remainder.lowercased().hasPrefix("www.") {
            remainder = String(remainder.dropFirst("www.".count))
        }

        let username: String
        if remainder.lowercased().hasPrefix("github.com/") {
            var path = String(remainder.dropFirst("github.com/".count))
            if path.hasSuffix("/") {
                path.removeLast()
            }
            username = path
        } else if hadScheme {
            // Tenía http(s):// pero no es github.com.
            throw .invalidGitHub
        } else if remainder.hasPrefix("@") {
            username = String(remainder.dropFirst())
        } else {
            username = remainder
        }

        guard matches(username, pattern: gitHubUsernamePattern) else { throw .invalidGitHub }
        return gitHubProfilePrefix + username
    }

    // MARK: - Código de invitación

    /// Solo letras A–Z sin tildes, números, guion y guion bajo: el mismo formato que exige la regla.
    /// Así el código tampoco puede romper la ruta `inviteCodes/{código}` que consulta la regla.
    private static let inviteCodePattern = "^[A-Z0-9_-]+$"

    /// Se guarda recortado y en mayúsculas. Que el código exista lo valida la regla de
    /// Realtime Database al guardar el perfil.
    static func normalizedInviteCode(_ raw: String) throws(ValidationError) -> String {
        let code = try requiredText(raw, emptyError: .emptyInviteCode).uppercased()
        guard textLength(code) <= maximumInviteCodeLength,
              matches(code, pattern: inviteCodePattern)
        else { throw .invalidInviteCodeFormat(maximum: maximumInviteCodeLength) }
        return code
    }

    // MARK: - Utilidades

    /// Coincidencia de toda la cadena con una expresión regular (motor ICU de Foundation).
    private static func matches(_ text: String, pattern: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }
}
