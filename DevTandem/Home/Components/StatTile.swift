//
//  StatTile.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import SwiftUI

/// Indicador con ícono, valor grande y descripción.
struct StatTile: View {
    let value: String
    let label: String
    let systemImage: String
    var tint: Color = .accent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
            Text(value)
                .font(.title2.weight(.bold))
                .monospacedDigit()
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    HStack {
        StatTile(value: "12", label: "Revisiones esta semana", systemImage: "checklist")
        StatTile(value: "3 h", label: "Tiempo medio", systemImage: "clock", tint: .brandGreen)
    }
    .padding()
}
