//
//  DetailRow.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import SwiftUI

/// Fila "dato: valor" con ícono. Con textos de accesibilidad, el valor pasa debajo del dato.
struct DetailRow: View {
    let title: String
    let value: String
    let systemImage: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 24

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
        layout {
            Label {
                Text(title)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(.accent)
                    .frame(width: iconWidth)
            }
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 8)
            }
            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 12) {
        DetailRow(title: "Rubro", value: "Gastronomía", systemImage: "tag")
        DetailRow(title: "Tipo de proyecto", value: "E-commerce", systemImage: "cart")
    }
    .padding()
}

#Preview("XXXL") {
    VStack(spacing: 12) {
        DetailRow(title: "Rubro", value: "Gastronomía", systemImage: "tag")
    }
    .padding()
    .environment(\.dynamicTypeSize, .accessibility3)
}
