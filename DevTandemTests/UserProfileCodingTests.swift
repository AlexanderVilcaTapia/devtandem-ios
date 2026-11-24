//
//  UserProfileCodingTests.swift
//  DevTandemTests
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation
import Testing
@testable import DevTandem

/// Comprueba que `UserProfile` produce y lee exactamente el JSON del contrato de `/users/{uid}`.
struct UserProfileCodingTests {

    // MARK: - Datos de prueba

    /// Segundos enteros, para que la ida y vuelta en milisegundos sea exacta.
    static let createdAt = Date(timeIntervalSince1970: 1_700_000_000)

    static let client = UserProfile(
        name: "Ana Torres",
        email: "ana@empresa.com",
        createdAt: createdAt,
        details: .client(ClientProfile(
            company: "Bodega Ana",
            industry: .retail,
            projectType: .ecommerce,
            companySize: .micro
        ))
    )

    static let junior = UserProfile(
        name: "Luis Quispe",
        email: "luis@correo.com",
        createdAt: createdAt,
        details: .junior(JuniorProfile(
            experience: .lessThanOneYear,
            technologies: ["Swift", "Firebase"],
            githubURL: "https://github.com/luisq",
            availability: nil
        ))
    )

    static let mentor = UserProfile(
        name: "María Rojas",
        email: "maria@correo.com",
        createdAt: createdAt,
        details: .mentor(MentorProfile(
            experience: .moreThanEightYears,
            technologies: ["Kotlin", "Swift"],
            githubURL: "https://github.com/mrojas",
            inviteCode: "MENTOR2026",
            availability: .fiveToTenHours
        ))
    )

    // MARK: - Utilidades

    /// Codifica el perfil y lo devuelve como diccionario para revisar las claves.
    private func jsonObject(_ profile: UserProfile) throws -> [String: Any] {
        let data = try JSONEncoder().encode(profile)
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? [String: Any])
    }

    private func decode(_ json: String) throws -> UserProfile {
        try JSONDecoder().decode(UserProfile.self, from: Data(json.utf8))
    }

    // MARK: - Ida y vuelta

    @Test("Codificar y decodificar devuelve el mismo perfil", arguments: [client, junior, mentor])
    func roundTrip(profile: UserProfile) throws {
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
        #expect(decoded == profile)
        #expect(decoded.role == profile.role)
    }

    // MARK: - Claves del contrato

    @Test("Cliente: claves comunes, rol y solo el bloque client")
    func clientKeys() throws {
        let json = try jsonObject(Self.client)
        #expect(Set(json.keys) == ["name", "email", "role", "createdAt", "client"])
        #expect(json["role"] as? String == "client")

        let block = try #require(json["client"] as? [String: Any])
        #expect(Set(block.keys) == ["company", "industry", "projectType", "companySize"])
        #expect(block["industry"] as? String == "retail")
        #expect(block["projectType"] as? String == "ecommerce")
        #expect(block["companySize"] as? String == "micro")
    }

    @Test("Junior: los opcionales en nil no aparecen en el JSON")
    func juniorOmitsNilOptionals() throws {
        let json = try jsonObject(Self.junior)
        #expect(Set(json.keys) == ["name", "email", "role", "createdAt", "junior"])
        #expect(json["role"] as? String == "junior")

        let block = try #require(json["junior"] as? [String: Any])
        #expect(Set(block.keys) == ["experience", "technologies", "githubURL"])
        #expect(block["experience"] as? String == "lessThanOneYear")
        #expect(block["technologies"] as? [String] == ["Swift", "Firebase"])
        #expect(block["githubURL"] as? String == "https://github.com/luisq")
    }

    @Test("Mentor: incluye inviteCode y la disponibilidad elegida")
    func mentorKeys() throws {
        let json = try jsonObject(Self.mentor)
        #expect(Set(json.keys) == ["name", "email", "role", "createdAt", "mentor"])
        #expect(json["role"] as? String == "mentor")

        let block = try #require(json["mentor"] as? [String: Any])
        #expect(Set(block.keys) == ["experience", "technologies", "githubURL", "inviteCode", "availability"])
        #expect(block["inviteCode"] as? String == "MENTOR2026")
        #expect(block["availability"] as? String == "fiveToTenHours")
    }

    @Test("Un opcional ausente en el JSON se decodifica como nil")
    func decodesMissingOptional() throws {
        let profile = try decode("""
        {"name":"Ana","email":"ana@empresa.com","role":"client","createdAt":1700000000000,
         "client":{"company":"Bodega","industry":"food","projectType":"landingPage"}}
        """)
        guard case .client(let client) = profile.details else {
            Issue.record("Se esperaba un perfil de cliente")
            return
        }
        #expect(client.companySize == nil)
        #expect(client.industry == .food)
    }

    // MARK: - createdAt en milisegundos

    @Test("createdAt se guarda como entero en milisegundos")
    func createdAtIsMilliseconds() throws {
        let profile = UserProfile(
            name: "Ana",
            email: "ana@empresa.com",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000.123),
            details: Self.client.details
        )
        let json = try jsonObject(profile)
        let number = try #require(json["createdAt"] as? NSNumber)
        #expect(number.int64Value == 1_700_000_000_123)
    }

    @Test("createdAt en milisegundos (como ServerValue.timestamp) se lee como Date")
    func decodesMillisecondsTimestamp() throws {
        let profile = try decode("""
        {"name":"Luis","email":"luis@correo.com","role":"junior","createdAt":1700000000500,
         "junior":{"experience":"noExperience","technologies":["Swift"],"githubURL":"https://github.com/luis"}}
        """)
        #expect(abs(profile.createdAt.timeIntervalSince1970 - 1_700_000_000.5) < 0.000_001)
    }

    @Test("milliseconds(from:) redondea al milisegundo más cercano")
    func millisecondsRounding() {
        #expect(UserProfile.milliseconds(from: Date(timeIntervalSince1970: 1.0004)) == 1_000)
        #expect(UserProfile.milliseconds(from: Date(timeIntervalSince1970: 1.0006)) == 1_001)
    }

    // MARK: - Errores de decodificación

    @Test("Si falta el bloque del rol, la decodificación falla")
    func missingRoleBlockFails() {
        #expect(throws: DecodingError.self) {
            try decode("""
            {"name":"María","email":"maria@correo.com","role":"mentor","createdAt":1700000000000}
            """)
        }
    }

    @Test("Un bloque de otro rol no reemplaza al del rol declarado")
    func mismatchedBlockFails() {
        #expect(throws: DecodingError.self) {
            try decode("""
            {"name":"María","email":"maria@correo.com","role":"mentor","createdAt":1700000000000,
             "client":{"company":"Bodega","industry":"food","projectType":"landingPage"}}
            """)
        }
    }

    @Test("Un rol desconocido hace fallar la decodificación")
    func unknownRoleFails() {
        #expect(throws: DecodingError.self) {
            try decode("""
            {"name":"X","email":"x@correo.com","role":"admin","createdAt":1700000000000}
            """)
        }
    }

    @Test("Un valor de opción desconocido hace fallar la decodificación")
    func unknownOptionFails() {
        #expect(throws: DecodingError.self) {
            try decode("""
            {"name":"Ana","email":"ana@empresa.com","role":"client","createdAt":1700000000000,
             "client":{"company":"Bodega","industry":"mining","projectType":"landingPage"}}
            """)
        }
    }

    // MARK: - Rol derivado

    @Test("El rol se deriva del bloque de datos")
    func roleDerivedFromDetails() {
        #expect(Self.client.role == .client)
        #expect(Self.junior.role == .junior)
        #expect(Self.mentor.role == .mentor)
    }
}
