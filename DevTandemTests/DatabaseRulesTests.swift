//
//  DatabaseRulesTests.swift
//  DevTandemTests
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation
import Testing
@testable import DevTandem

/// Comprueba que firebase/database.rules.json siga alineado con la app: cada `rawValue` de los enums
/// aparece en su regla y los límites son los mismos que usa `FieldValidators`.
/// Si se agrega una opción a un enum y no se regeneran las reglas, esta prueba falla.
struct DatabaseRulesTests {

    /// Ruta del archivo de reglas, a partir de la ubicación de este archivo de pruebas.
    private static let rulesURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()      // DevTandemTests/
        .deletingLastPathComponent()      // raíz del repositorio
        .appendingPathComponent("firebase/database.rules.json")

    /// Nodo `/users/$uid` de las reglas.
    private func profileRules() throws -> [String: Any] {
        let data = try Data(contentsOf: Self.rulesURL)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let rules = try #require(json["rules"] as? [String: Any])
        let users = try #require(rules["users"] as? [String: Any])
        return try #require(users["$uid"] as? [String: Any])
    }

    /// Texto de `.validate` en una ruta dentro de `/users/$uid` (por ejemplo `["client", "industry"]`).
    private func validateRule(at path: [String]) throws -> String {
        var node = try profileRules()
        for key in path {
            node = try #require(node[key] as? [String: Any], "No existe la regla \(path.joined(separator: "/"))")
        }
        return try #require(node[".validate"] as? String)
    }

    /// Exige exactamente las opciones del enum, en su orden: `/^(a|b|c)$/`.
    private func expectOptions<Option: RawRepresentable & CaseIterable>(
        _ type: Option.Type, at path: [String]
    ) throws where Option.RawValue == String {
        let rule = try validateRule(at: path)
        let rawValues = Option.allCases.map(\.rawValue)
        let alternation = "/^(" + rawValues.joined(separator: "|") + ")$/"
        #expect(rule.contains(alternation), "La regla \(path) no coincide con \(Option.self): se esperaba \(alternation)")
        for rawValue in rawValues {
            #expect(rule.contains(rawValue), "Falta \(rawValue) de \(Option.self) en \(path)")
        }
    }

    @Test("El archivo de reglas existe y es JSON válido")
    func fileIsValidJSON() throws {
        let data = try Data(contentsOf: Self.rulesURL)
        _ = try JSONSerialization.jsonObject(with: data)
    }

    @Test("Cada rawValue de los enums aparece en su regla")
    func enumsMatchRules() throws {
        try expectOptions(UserRole.self, at: ["role"])
        try expectOptions(ClientIndustry.self, at: ["client", "industry"])
        try expectOptions(ProjectType.self, at: ["client", "projectType"])
        try expectOptions(CompanySize.self, at: ["client", "companySize"])
        try expectOptions(JuniorExperience.self, at: ["junior", "experience"])
        try expectOptions(WeeklyAvailability.self, at: ["junior", "availability"])
        try expectOptions(MentorExperience.self, at: ["mentor", "experience"])
        try expectOptions(ReviewAvailability.self, at: ["mentor", "availability"])
    }

    @Test("Cada rol tiene su bloque en las reglas")
    func everyRoleHasBlock() throws {
        let rules = try profileRules()
        for role in UserRole.allCases {
            #expect(rules[role.rawValue] is [String: Any], "Falta el bloque \(role.rawValue)")
        }
    }

    @Test("Los límites de las reglas son los mismos que valida la app")
    func limitsMatchValidators() throws {
        #expect(try validateRule(at: ["name"]).contains("length <= \(FieldValidators.maximumNameLength)"))
        #expect(try validateRule(at: ["client", "company"]).contains("length <= \(FieldValidators.maximumCompanyLength)"))
        #expect(try validateRule(at: ["mentor", "inviteCode"]).contains("length <= \(FieldValidators.maximumInviteCodeLength)"))
        for role in ["junior", "mentor"] {
            #expect(try validateRule(at: [role, "technologies"]).contains("!newData.hasChild('\(FieldValidators.maximumTechnologies)')"))
            #expect(try validateRule(at: [role, "technologies", "$index"]).contains("length <= \(FieldValidators.maximumTechnologyLength)"))
            #expect(try validateRule(at: [role, "githubURL"]).contains("beginsWith('\(FieldValidators.gitHubProfilePrefix)')"))
        }
    }

    @Test("El código de invitación se valida contra /inviteCodes en la regla")
    func inviteCodeCheckedInRules() throws {
        let rule = try validateRule(at: ["mentor", "inviteCode"])
        #expect(rule.contains("root.child('inviteCodes/' + newData.val()).val() == true"))
    }
}
