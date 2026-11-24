//
//  ClientDashboardView.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import SwiftUI

/// Panel de inicio del cliente: datos reales de su empresa y proyectos de muestra con pagos en custodia.
struct ClientDashboardView: View {
    let name: String
    let client: ClientProfile
    var projects: [SampleProject] = SampleData.clientProjects

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ProfileHeader(name: name, role: .client, greeting: "Hola,")
                companyCard
                SampleNotice()
                summaryCard

                SectionHeader(title: "Tus proyectos", subtitle: "Avance por hitos y estado del pago")
                ForEach(projects) { project in
                    ProjectCard(project: project)
                }

                EscrowExplainerCard()
            }
            .padding()
        }
        .background(Color.screenBackground)
    }

    // MARK: Datos reales

    private var companyCard: some View {
        Card("Tu empresa", systemImage: "building.2") {
            Text(client.company)
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            DetailRow(title: "Rubro", value: client.industry.title, systemImage: "tag")
            DetailRow(title: "Tipo de proyecto", value: client.projectType.title, systemImage: "square.stack.3d.up")
            if let size = client.companySize {
                DetailRow(title: "Tamaño", value: size.title, systemImage: "person.3")
            }
        }
    }

    // MARK: Muestra

    private var summaryCard: some View {
        let inEscrow = projects
            .flatMap(\.milestones)
            .filter { $0.status != .released }
            .reduce(Decimal(0)) { $0 + $1.amount }
        let released = projects
            .flatMap(\.milestones)
            .filter { $0.status == .released }
            .reduce(Decimal(0)) { $0 + $1.amount }

        return Card("Resumen", systemImage: "chart.pie", isSample: true) {
            AdaptiveStack {
                StatTile(value: "\(projects.count)", label: "Proyectos activos", systemImage: "folder.fill")
                StatTile(value: SampleData.soles(inEscrow), label: "En custodia", systemImage: "lock.fill", tint: .orange)
                StatTile(value: SampleData.soles(released), label: "Liberado", systemImage: "checkmark.circle.fill", tint: .brandGreen)
            }
        }
    }
}

/// Tarjeta de un proyecto de muestra: equipo, avance e hitos con su estado de pago.
private struct ProjectCard: View {
    let project: SampleProject

    private var releasedCount: Int {
        project.milestones.filter { $0.status == .released }.count
    }

    var body: some View {
        Card(project.name, systemImage: "folder.fill", isSample: true) {
            Text("Junior: \(project.juniorName) · Mentor: \(project.mentorName)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ProgressBar(progress: project.progress, label: "Avance de \(project.name)", tint: .brandGreen)
            Text("\(releasedCount) de \(project.milestones.count) hitos liberados · Total \(SampleData.soles(project.totalAmount))")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            ForEach(project.milestones) { milestone in
                MilestoneRow(milestone: milestone)
            }
        }
    }
}

/// Fila de un hito: estado del pago (ícono y texto), título y monto.
private struct MilestoneRow: View {
    let milestone: SampleMilestone

    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 24

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: milestone.status.symbolName)
                .foregroundStyle(milestone.status.tint)
                .frame(width: iconWidth)
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.subheadline.weight(.medium))
                AdaptiveStack(spacing: 4) {
                    Text(milestone.status.title)
                        .foregroundStyle(milestone.status.tint)
                    Text(SampleData.soles(milestone.amount))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .font(.footnote)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Explica la custodia por hitos. No es de muestra: describe cómo funciona el producto.
private struct EscrowExplainerCard: View {
    var body: some View {
        Card("¿Cómo funciona la custodia?", systemImage: "lock.shield") {
            step(1, "Depositas el monto del hito y queda retenido en custodia.")
            step(2, "El junior entrega y un mentor senior revisa el código.")
            step(3, "Cuando apruebas el hito, el pago se libera al junior.")
            Text("En esta versión los pagos son simulados: no se mueve dinero real.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(number)")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Color.onAccent)
                .frame(minWidth: 22, minHeight: 22)
                .background(Color.accent, in: Circle())
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Paso \(number): \(text)")
    }
}

extension EscrowStatus {
    /// Naranja mientras el dinero está retenido, azul en revisión y verde cuando se liberó.
    var tint: Color {
        switch self {
        case .funded: return .orange
        case .inReview: return .accent
        case .released: return .brandGreen
        }
    }
}

#if DEBUG
private extension ClientDashboardView {
    @ViewBuilder
    static var preview: some View {
        let profile = UserProfile.previewClient
        if case .client(let client) = profile.details {
            NavigationStack {
                ClientDashboardView(name: profile.name, client: client)
                    .navigationTitle("Inicio")
                    .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            Text("El perfil de vista previa no es de cliente.")
        }
    }
}

#Preview("Cliente") {
    ClientDashboardView.preview
}

#Preview("Cliente · oscuro") {
    ClientDashboardView.preview
        .preferredColorScheme(.dark)
}

#Preview("Cliente · XXXL") {
    ClientDashboardView.preview
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
