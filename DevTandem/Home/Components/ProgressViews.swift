//
//  ProgressViews.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import SwiftUI

/// Anillo de avance con el porcentaje al centro. Se llena con una animación al aparecer,
/// salvo que esté activado "Reducir movimiento".
struct ProgressRing: View {
    /// Avance entre 0 y 1.
    let progress: Double
    let label: String
    var tint: Color = .brandGreen

    @State private var shownProgress: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title) private var diameter: CGFloat = 88
    @ScaledMetric(relativeTo: .title) private var lineWidth: CGFloat = 10

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: shownProgress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(clamped, format: .percent.precision(.fractionLength(0)))
                .font(.headline)
                .monospacedDigit()
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(Text(clamped, format: .percent.precision(.fractionLength(0))))
        .onAppear { fill() }
        .onChange(of: progress) { fill() }
    }

    private func fill() {
        if reduceMotion {
            shownProgress = clamped
        } else {
            withAnimation(.easeOut(duration: 0.9)) {
                shownProgress = clamped
            }
        }
    }
}

/// Barra de avance horizontal, con la misma animación que `ProgressRing`.
struct ProgressBar: View {
    /// Avance entre 0 y 1.
    let progress: Double
    let label: String
    var tint: Color = .accent

    @State private var shownProgress: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 8

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        Capsule()
            .fill(tint.opacity(0.2))
            .frame(height: height)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(tint)
                        .frame(width: proxy.size.width * shownProgress)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(Text(clamped, format: .percent.precision(.fractionLength(0))))
            .onAppear { fill() }
            .onChange(of: progress) { fill() }
    }

    private func fill() {
        if reduceMotion {
            shownProgress = clamped
        } else {
            withAnimation(.easeOut(duration: 0.9)) {
                shownProgress = clamped
            }
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        ProgressRing(progress: 0.66, label: "Avance")
        ProgressBar(progress: 0.4, label: "Hitos completados")
    }
    .padding()
}
