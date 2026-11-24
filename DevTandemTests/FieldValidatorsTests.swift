//
//  FieldValidatorsTests.swift
//  DevTandemTests
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation
import Testing
@testable import DevTandem

struct FieldValidatorsTests {

    // MARK: - Nombre y texto obligatorio

    @Test("El nombre se recorta")
    func nameIsTrimmed() throws {
        #expect(try FieldValidators.normalizedName("  Ana Torres \n") == "Ana Torres")
    }

    @Test("Un nombre vacío o solo con espacios es un error", arguments: ["", "   ", "\n\t"])
    func emptyName(raw: String) {
        #expect(throws: ValidationError.emptyName) {
            try FieldValidators.normalizedName(raw)
        }
    }

    @Test("Una selección vacía de menú lanza el error indicado")
    func requiredSelection() throws {
        let missing: ClientIndustry? = nil
        #expect(throws: ValidationError.missingIndustry) {
            try FieldValidators.requiredSelection(missing, missingError: .missingIndustry)
        }
        #expect(try FieldValidators.requiredSelection(ClientIndustry.food, missingError: .missingIndustry) == .food)
    }

    // MARK: - Correo

    @Test("Correos válidos se normalizan a minúsculas y sin espacios", arguments: [
        ("ana@empresa.com", "ana@empresa.com"),
        ("  Ana.Torres@Empresa.COM ", "ana.torres@empresa.com"),
        ("luis+test@correo.edu.pe", "luis+test@correo.edu.pe"),
        ("a_b-c@sub-dominio.io", "a_b-c@sub-dominio.io")
    ])
    func validEmails(raw: String, expected: String) throws {
        #expect(try FieldValidators.normalizedEmail(raw) == expected)
    }

    @Test("Correos con formato inválido", arguments: [
        "ana", "ana@", "@empresa.com", "ana@empresa", "ana@empresa.c",
        "ana empresa@correo.com", "ana@@empresa.com", "ana..t@empresa.com",
        ".ana@empresa.com", "ana.@empresa.com", "ana@.empresa.com", "ana@empresa..com"
    ])
    func invalidEmails(raw: String) {
        #expect(throws: ValidationError.invalidEmail) {
            try FieldValidators.normalizedEmail(raw)
        }
    }

    @Test("Un correo vacío tiene su propio mensaje")
    func emptyEmail() {
        #expect(throws: ValidationError.emptyEmail) {
            try FieldValidators.normalizedEmail("   ")
        }
    }

    // MARK: - Contraseña

    @Test("Contraseñas que cumplen las reglas", arguments: ["clave123", "ñandú2026", "  espacio 1", "A1b2C3d4"])
    func validPasswords(password: String) throws {
        try FieldValidators.validateNewPassword(password)
    }

    @Test("Contraseñas que incumplen una regla", arguments: [
        ("", ValidationError.emptyPassword),
        ("abc1", ValidationError.passwordTooShort(minimum: 8)),
        ("1234567", ValidationError.passwordTooShort(minimum: 8)),
        ("abcdefgh", ValidationError.passwordMissingNumber),
        ("12345678", ValidationError.passwordMissingLetter),
        ("!!!!!!!!", ValidationError.passwordMissingLetter)
    ])
    func invalidPasswords(password: String, expected: ValidationError) {
        #expect(throws: expected) {
            try FieldValidators.validateNewPassword(password)
        }
    }

    @Test("La confirmación debe ser idéntica y no estar vacía")
    func passwordConfirmation() throws {
        try FieldValidators.validatePasswordConfirmation("clave123", matches: "clave123")
        #expect(throws: ValidationError.passwordMismatch) {
            try FieldValidators.validatePasswordConfirmation("Clave123", matches: "clave123")
        }
        #expect(throws: ValidationError.passwordMismatch) {
            try FieldValidators.validatePasswordConfirmation("clave123 ", matches: "clave123")
        }
        #expect(throws: ValidationError.emptyConfirmPassword) {
            try FieldValidators.validatePasswordConfirmation("", matches: "clave123")
        }
    }

    @Test("En el login solo se exige que la contraseña no esté vacía")
    func loginPassword() throws {
        try FieldValidators.validateLoginPassword("abc")
        #expect(throws: ValidationError.emptyPassword) {
            try FieldValidators.validateLoginPassword("")
        }
    }

    // MARK: - Tecnologías

    @Test("Separa por comas, recorta y quita vacías y duplicadas conservando el orden")
    func parseTechnologies() {
        #expect(FieldValidators.parseTechnologies(" Swift, kotlin ,, swift ,Kotlin,SwiftUI ") == ["Swift", "kotlin", "SwiftUI"])
        #expect(FieldValidators.parseTechnologies("React Native") == ["React Native"])
        #expect(FieldValidators.parseTechnologies(" , ,") == [])
    }

    @Test("Lista vacía de tecnologías", arguments: ["", "   ", ",,", " , "])
    func emptyTechnologies(raw: String) {
        #expect(throws: ValidationError.emptyTechnologies) {
            try FieldValidators.validatedTechnologies(raw)
        }
    }

    @Test("Máximo 15 tecnologías")
    func technologiesLimit() throws {
        let fifteen = (1...15).map { "Tec\($0)" }.joined(separator: ",")
        #expect(try FieldValidators.validatedTechnologies(fifteen).count == 15)

        let sixteen = (1...16).map { "Tec\($0)" }.joined(separator: ",")
        #expect(throws: ValidationError.tooManyTechnologies(maximum: 15)) {
            try FieldValidators.validatedTechnologies(sixteen)
        }
    }

    @Test("Cada tecnología admite hasta 30 caracteres")
    func technologyLength() throws {
        let thirty = String(repeating: "a", count: 30)
        let thirtyOne = String(repeating: "b", count: 31)
        #expect(try FieldValidators.validatedTechnologies(thirty) == [thirty])
        #expect(throws: ValidationError.technologyTooLong(name: thirtyOne, maximum: 30)) {
            try FieldValidators.validatedTechnologies("Swift, \(thirtyOne)")
        }
    }

    // MARK: - GitHub

    @Test("Formas aceptadas de GitHub se guardan como https://github.com/usuario", arguments: [
        ("octocat", "https://github.com/octocat"),
        ("@octocat", "https://github.com/octocat"),
        ("  octocat  ", "https://github.com/octocat"),
        ("github.com/octocat", "https://github.com/octocat"),
        ("www.github.com/octocat", "https://github.com/octocat"),
        ("http://github.com/octocat", "https://github.com/octocat"),
        ("https://github.com/octocat/", "https://github.com/octocat"),
        ("HTTPS://WWW.GitHub.com/Octo-Cat", "https://github.com/Octo-Cat"),
        ("a", "https://github.com/a"),
        (String(repeating: "a", count: 39), "https://github.com/" + String(repeating: "a", count: 39))
    ])
    func validGitHub(raw: String, expected: String) throws {
        #expect(try FieldValidators.normalizedGitHubURL(raw) == expected)
    }

    @Test("Usuarios o enlaces de GitHub inválidos", arguments: [
        "-octocat", "octocat-", "octo--cat", "octo_cat", "octo cat", "octo.cat",
        String(repeating: "a", count: 40),
        "github.com/octocat/repo", "https://github.com/octocat/repo/",
        "https://gitlab.com/octocat", "gitlab.com/octocat", "https://github.com/",
        "github.com", "github.com/octocat?tab=repositories", "@"
    ])
    func invalidGitHub(raw: String) {
        #expect(throws: ValidationError.invalidGitHub) {
            try FieldValidators.normalizedGitHubURL(raw)
        }
    }

    @Test("GitHub vacío tiene su propio mensaje")
    func emptyGitHub() {
        #expect(throws: ValidationError.emptyGitHub) {
            try FieldValidators.normalizedGitHubURL("  ")
        }
    }

    // MARK: - Código de invitación

    @Test("El código de invitación se recorta y pasa a mayúsculas")
    func inviteCode() throws {
        #expect(try FieldValidators.normalizedInviteCode("  mentor2026 ") == "MENTOR2026")
        #expect(throws: ValidationError.emptyInviteCode) {
            try FieldValidators.normalizedInviteCode(" ")
        }
    }

    // MARK: - Límites alineados con las reglas de Realtime Database

    @Test("El nombre admite hasta 80 unidades UTF-16")
    func nameLength() throws {
        let eighty = String(repeating: "é", count: 80)
        #expect(try FieldValidators.normalizedName(eighty) == eighty)
        #expect(throws: ValidationError.nameTooLong(maximum: 80)) {
            try FieldValidators.normalizedName(String(repeating: "a", count: 81))
        }
        // Un emoji ocupa 2 unidades UTF-16: 41 emojis son 82 y superan el límite.
        #expect(throws: ValidationError.nameTooLong(maximum: 80)) {
            try FieldValidators.normalizedName(String(repeating: "😀", count: 41))
        }
    }

    @Test("La empresa admite hasta 100 caracteres y no puede estar vacía")
    func companyLength() throws {
        let hundred = String(repeating: "b", count: 100)
        #expect(try FieldValidators.normalizedCompany("  \(hundred) ") == hundred)
        #expect(throws: ValidationError.companyTooLong(maximum: 100)) {
            try FieldValidators.normalizedCompany(String(repeating: "b", count: 101))
        }
        #expect(throws: ValidationError.emptyCompany) {
            try FieldValidators.normalizedCompany("   ")
        }
    }

    @Test("Una tecnología con emojis se mide en unidades UTF-16")
    func technologyLengthUTF16() {
        let sixteenEmojis = String(repeating: "😀", count: 16) // 32 unidades
        #expect(throws: ValidationError.technologyTooLong(name: sixteenEmojis, maximum: 30)) {
            try FieldValidators.validatedTechnologies(sixteenEmojis)
        }
    }

    @Test("Códigos de invitación con formato válido", arguments: [
        ("MENTOR2026", "MENTOR2026"),
        (" mentor-2026 ", "MENTOR-2026"),
        ("a_b", "A_B"),
        (String(repeating: "x", count: 40), String(repeating: "X", count: 40))
    ])
    func validInviteCodeFormats(raw: String, expected: String) throws {
        #expect(try FieldValidators.normalizedInviteCode(raw) == expected)
    }

    @Test("Códigos de invitación con formato inválido", arguments: [
        "MENTOR.2026", "MEN/TOR", "MEN TOR", "#MENTOR", "MEN$TOR", "[MENTOR]",
        "ÑANDÚ", "código", String(repeating: "x", count: 41)
    ])
    func invalidInviteCodeFormats(raw: String) {
        #expect(throws: ValidationError.invalidInviteCodeFormat(maximum: 40)) {
            try FieldValidators.normalizedInviteCode(raw)
        }
    }

    // MARK: - Mensajes

    @Test("Cada error trae un mensaje en español y apunta a su campo")
    func messagesAndFields() throws {
        let cases: [(ValidationError, FormField)] = [
            (.emptyName, .name), (.nameTooLong(maximum: 80), .name),
            (.emptyEmail, .email), (.invalidEmail, .email),
            (.companyTooLong(maximum: 100), .company),
            (.invalidInviteCodeFormat(maximum: 40), .inviteCode),
            (.emptyPassword, .password), (.passwordTooShort(minimum: 8), .password),
            (.passwordMissingLetter, .password), (.passwordMissingNumber, .password),
            (.emptyConfirmPassword, .confirmPassword), (.passwordMismatch, .confirmPassword),
            (.emptyCompany, .company), (.missingIndustry, .industry), (.missingProjectType, .projectType),
            (.missingExperience, .experience), (.emptyTechnologies, .technologies),
            (.tooManyTechnologies(maximum: 15), .technologies),
            (.technologyTooLong(name: "X", maximum: 30), .technologies),
            (.emptyGitHub, .githubURL), (.invalidGitHub, .githubURL), (.emptyInviteCode, .inviteCode)
        ]
        for (error, field) in cases {
            #expect(error.field == field)
            let message = try #require(error.errorDescription)
            #expect(!message.isEmpty)
            #expect(error.localizedDescription == message)
        }
        #expect(ValidationError.passwordTooShort(minimum: 8).errorDescription == "La contraseña debe tener al menos 8 caracteres.")
    }
}
