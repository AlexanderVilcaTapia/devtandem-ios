//
//  Theme.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import SwiftUI

/// Colores de fondo de las pantallas SwiftUI. Son colores del sistema: se adaptan solos al modo oscuro.
/// Los colores de marca (`.accent`, `.brandGreen`, `.onAccent`) los genera Xcode desde Assets.xcassets.
extension Color {
    /// Fondo de la pantalla (gris claro en modo claro, negro en modo oscuro).
    static let screenBackground = Color(uiColor: .systemGroupedBackground)
    /// Fondo de las tarjetas, un nivel por encima del fondo de la pantalla.
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
}

/// Presentación de cada rol: ícono y color.
extension UserRole {
    /// Nombre del SF Symbol que representa al rol.
    var symbolName: String {
        switch self {
        case .client: return "building.2.fill"
        case .junior: return "chevron.left.forwardslash.chevron.right"
        case .mentor: return "checkmark.seal.fill"
        }
    }

    /// Color del rol: azul de marca para el cliente, verde de marca para el junior e índigo para el mentor.
    var tint: Color {
        switch self {
        case .client: return .accent
        case .junior: return .brandGreen
        case .mentor: return .indigo
        }
    }
}
