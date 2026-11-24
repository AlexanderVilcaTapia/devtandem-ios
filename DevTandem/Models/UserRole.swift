//
//  UserRole.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 17/11/26.
//

import Foundation

/// Rol del usuario dentro de DevTándem.
/// El `rawValue` es la clave estable que se guarda en Firebase; `title` es el texto de la UI.
/// Es `nonisolated` porque el target aísla todo a MainActor por defecto y este tipo es un dato puro
/// que también se usa fuera del hilo principal (tests, callbacks de Firebase).
nonisolated enum UserRole: String, CaseIterable, Codable {
    case client
    case junior
    case mentor

    var title: String {
        switch self {
        case .client: return "Cliente"
        case .junior: return "Junior"
        case .mentor: return "Mentor senior"
        }
    }
}
