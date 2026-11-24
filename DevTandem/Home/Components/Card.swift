//
//  Card.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import SwiftUI

/// Tarjeta con esquinas redondeadas, un título opcional y la etiqueta "Muestra" si su contenido es de ejemplo.
struct Card<Content: View>: View {
    private let title: String?
    private let systemImage: String?
    private let isSample: Bool
    private let content: Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        _ title: String? = nil,
        systemImage: String? = nil,
        isSample: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isSample = isSample
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if title != nil || isSample {
                header
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    /// Con textos de accesibilidad, el título y la etiqueta van uno debajo del otro.
    private var header: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
        return layout {
            if let title {
                Group {
                    if let systemImage {
                        Label(title, systemImage: systemImage)
                    } else {
                        Text(title)
                    }
                }
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            }
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 0)
            }
            if isSample {
                SampleBadge()
            }
        }
    }
}

#Preview("Tarjetas") {
    ScrollView {
        VStack(spacing: 16) {
            Card("Tu empresa", systemImage: "building.2") {
                Text("Bodega Los Andes")
            }
            Card("Proyectos", systemImage: "folder", isSample: true) {
                Text("Contenido de ejemplo")
            }
        }
        .padding()
    }
    .background(Color.screenBackground)
}

#Preview("Tarjetas · oscuro · XXXL") {
    ScrollView {
        VStack(spacing: 16) {
            Card("Proyectos", systemImage: "folder", isSample: true) {
                Text("Contenido de ejemplo")
            }
        }
        .padding()
    }
    .background(Color.screenBackground)
    .preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .accessibility3)
}
