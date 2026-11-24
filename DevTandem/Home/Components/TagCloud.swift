//
//  TagCloud.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import SwiftUI

/// Chips de texto que se acomodan en filas según el ancho disponible (por ejemplo, las tecnologías).
struct TagCloud: View {
    let tags: [String]
    var tint: Color = .accent

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(Array(tags.enumerated()), id: \.offset) { _, tag in
                Text(tag)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .foregroundStyle(tint)
                    .background(tint.opacity(0.15), in: Capsule())
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tags.joined(separator: ", "))
    }
}

/// Layout que coloca las vistas una tras otra y salta de fila cuando no caben.
/// Una vista más ancha que el espacio disponible (texto muy grande) recibe ese ancho y se ajusta.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(maxWidth: proposal.width, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(maxWidth: bounds.width, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let frame = arrangement.frames[index]
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private struct Arrangement {
        var frames: [CGRect]
        var size: CGSize
    }

    private func arrange(maxWidth: CGFloat?, subviews: Subviews) -> Arrangement {
        let limit = maxWidth ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            var size = subview.sizeThatFits(.unspecified)
            if size.width > limit {
                size = subview.sizeThatFits(ProposedViewSize(width: limit, height: nil))
            }
            if x > 0 && x + size.width > limit {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            usedWidth = max(usedWidth, x - spacing)
        }

        let height = frames.isEmpty ? 0 : y + rowHeight
        return Arrangement(frames: frames, size: CGSize(width: usedWidth, height: height))
    }
}

#Preview {
    TagCloud(tags: ["Swift", "SwiftUI", "Firebase", "Kotlin", "React", "Node.js", "PostgreSQL"], tint: .brandGreen)
        .padding()
}

#Preview("XXXL") {
    TagCloud(tags: ["Swift", "SwiftUI", "Firebase", "Kotlin"])
        .padding()
        .environment(\.dynamicTypeSize, .accessibility3)
}
