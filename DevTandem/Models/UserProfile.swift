//
//  UserProfile.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation

/// Perfil de un usuario tal como se guarda en Realtime Database, en `/users/{uid}`.
///
/// JSON que produce (contrato de datos):
/// ```
/// name, email, role ("client" | "junior" | "mentor"), createdAt (milisegundos desde 1970)
/// client: { company, industry, projectType, companySize? }
/// junior: { experience, technologies[], githubURL, availability? }
/// mentor: { experience, technologies[], githubURL, inviteCode, availability? }
/// ```
/// El rol no se guarda aparte en Swift: se deriva de `details`, así que el rol y el bloque
/// de datos de ese rol siempre coinciden.
nonisolated struct UserProfile: Codable, Equatable {
    let name: String
    let email: String
    let createdAt: Date
    let details: RoleDetails

    var role: UserRole { details.role }

    init(name: String, email: String, createdAt: Date, details: RoleDetails) {
        self.name = name
        self.email = email
        self.createdAt = createdAt
        self.details = details
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case name, email, role, createdAt, client, junior, mentor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)

        // Se lee como Double para aceptar enteros (como los de ServerValue.timestamp()) y decimales.
        let milliseconds = try container.decode(Double.self, forKey: .createdAt)
        createdAt = Date(timeIntervalSince1970: milliseconds / 1000)

        // Un rol desconocido lanza DecodingError.dataCorrupted; si falta el bloque del rol, keyNotFound.
        let role = try container.decode(UserRole.self, forKey: .role)
        switch role {
        case .client:
            details = .client(try container.decode(ClientProfile.self, forKey: .client))
        case .junior:
            details = .junior(try container.decode(JuniorProfile.self, forKey: .junior))
        case .mentor:
            details = .mentor(try container.decode(MentorProfile.self, forKey: .mentor))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encode(role, forKey: .role)
        try container.encode(Self.milliseconds(from: createdAt), forKey: .createdAt)

        switch details {
        case .client(let client):
            try container.encode(client, forKey: .client)
        case .junior(let junior):
            try container.encode(junior, forKey: .junior)
        case .mentor(let mentor):
            try container.encode(mentor, forKey: .mentor)
        }
    }

    /// Milisegundos enteros desde 1970, el mismo formato que usa Firebase para sus marcas de tiempo.
    /// Se redondea al milisegundo: una fecha con más precisión no vuelve idéntica al decodificar.
    static func milliseconds(from date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000).rounded())
    }
}

/// Datos propios de cada rol. Solo existe uno a la vez.
nonisolated enum RoleDetails: Equatable {
    case client(ClientProfile)
    case junior(JuniorProfile)
    case mentor(MentorProfile)

    var role: UserRole {
        switch self {
        case .client: return .client
        case .junior: return .junior
        case .mentor: return .mentor
        }
    }
}

// MARK: - Bloques por rol
// El Codable sintetizado omite del JSON las propiedades opcionales en nil (encodeIfPresent)
// y las acepta ausentes al decodificar (decodeIfPresent).

nonisolated struct ClientProfile: Codable, Equatable {
    let company: String
    let industry: ClientIndustry
    let projectType: ProjectType
    let companySize: CompanySize?
}

nonisolated struct JuniorProfile: Codable, Equatable {
    let experience: JuniorExperience
    let technologies: [String]
    let githubURL: String
    let availability: WeeklyAvailability?
}

nonisolated struct MentorProfile: Codable, Equatable {
    let experience: MentorExperience
    let technologies: [String]
    let githubURL: String
    let inviteCode: String
    let availability: ReviewAvailability?
}
