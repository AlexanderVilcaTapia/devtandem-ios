//
//  SampleBadge.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import SwiftUI

/// Etiqueta "Muestra" para el contenido de ejemplo. El borde punteado sugiere que es un borrador.
struct SampleBadge: View {
    var body: some View {
        Text("Muestra")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .overlay(
                Capsule().strokeBorder(.secondary, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
            )
            .accessibilityLabel("Contenido de muestra")
    }
}

/// Aviso fijo arriba de los paneles: explica qué datos son de ejemplo.
struct SampleNotice: View {
    var body: some View {
        Label {
            Text("Vista previa: los proyectos, pagos y revisiones son datos de muestra. Los pagos en DevTándem son simulados.")
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview("Etiqueta y aviso") {
    VStack(spacing: 16) {
        SampleBadge()
        SampleNotice()
    }
    .padding()
}
