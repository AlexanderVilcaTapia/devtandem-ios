//
//  AdaptiveStack.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import SwiftUI

/// Fila que se convierte en columna con los tamaños de texto de accesibilidad,
/// para que nada se corte cuando el usuario agranda la letra.
struct AdaptiveStack<Content: View>: View {
    private let spacing: CGFloat
    private let content: Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
            : AnyLayout(HStackLayout(alignment: .top, spacing: spacing))
        layout {
            content
        }
    }
}

#Preview {
    AdaptiveStack {
        StatTile(value: "2", label: "Proyectos", systemImage: "folder")
        StatTile(value: "S/ 900", label: "En custodia", systemImage: "lock")
    }
    .padding()
}
