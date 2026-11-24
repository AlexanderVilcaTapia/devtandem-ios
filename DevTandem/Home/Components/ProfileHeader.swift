//
//  ProfileHeader.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import SwiftUI

/// Encabezado con las iniciales en un círculo, el saludo, el nombre y el rol como insignia.
struct ProfileHeader: View {
    let name: String
    let role: UserRole
    var greeting: String?

    @ScaledMetric(relativeTo: .largeTitle) private var avatarSize: CGFloat = 60
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 14))
        layout {
            Text(Self.initials(from: name))
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.onAccent)
                .frame(width: avatarSize, height: avatarSize)
                .background(role.tint.gradient, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                if let greeting {
                    Text(greeting)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(name)
                    .font(.title2.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                RoleBadge(role: role)
            }
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// Iniciales de las dos primeras palabras del nombre ("Ana María Torres" → "AM"). "?" si no hay letras.
    nonisolated static func initials(from name: String) -> String {
        let letters = name
            .split(whereSeparator: { $0.isWhitespace })
            .prefix(2)
            .compactMap { $0.first(where: { $0.isLetter }) }
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }
}

/// Insignia con el ícono y el nombre del rol.
struct RoleBadge: View {
    let role: UserRole

    var body: some View {
        Label(role.title, systemImage: role.symbolName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(role.tint)
            .background(role.tint.opacity(0.15), in: Capsule())
            .accessibilityLabel("Rol: \(role.title)")
    }
}

#Preview("Roles") {
    VStack(alignment: .leading, spacing: 24) {
        ProfileHeader(name: "Rosa Quispe Huamán", role: .client, greeting: "Hola,")
        ProfileHeader(name: "Diego Mamani", role: .junior, greeting: "Hola,")
        ProfileHeader(name: "Lucía Paredes", role: .mentor, greeting: "Hola,")
    }
    .padding()
}

#Preview("Oscuro · XXXL") {
    ProfileHeader(name: "Lucía Paredes", role: .mentor, greeting: "Hola,")
        .padding()
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility3)
}
