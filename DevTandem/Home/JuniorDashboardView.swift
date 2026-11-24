//
//  JuniorDashboardView.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import SwiftUI

/// Panel de inicio del junior: su perfil real y, de muestra, su progreso, la próxima entrega
/// con el comentario del mentor y proyectos recomendados según sus tecnologías.
struct JuniorDashboardView: View {
    let name: String
    let junior: JuniorProfile
    var progress: SampleJuniorProgress = SampleData.juniorProgress

    private var recommended: [SampleOpportunity] {
        SampleData.recommendedOpportunities(for: junior.technologies)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ProfileHeader(name: name, role: .junior, greeting: "Hola,")
                profileCard
                SampleNotice()
                progressCard
                nextDeliveryCard

                SectionHeader(title: "Proyectos recomendados", subtitle: "Según las tecnologías de tu perfil")
                ForEach(recommended) { opportunity in
                    OpportunityCard(opportunity: opportunity, profileTechnologies: junior.technologies)
                }
            }
            .padding()
        }
        .background(Color.screenBackground)
    }

    // MARK: Datos reales

    private var profileCard: some View {
        Card("Tu perfil", systemImage: "person.text.rectangle") {
            DetailRow(title: "Experiencia", value: junior.experience.title, systemImage: "graduationcap")
            if let availability = junior.availability {
                DetailRow(title: "Disponibilidad", value: availability.title, systemImage: "clock")
            }
            GitHubLink(urlString: junior.githubURL)
            Text("Tecnologías")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TagCloud(tags: junior.technologies, tint: .brandGreen)
        }
    }

    // MARK: Muestra

    private var progressCard: some View {
        Card("Tu progreso", systemImage: "chart.line.uptrend.xyaxis", isSample: true) {
            AdaptiveStack(spacing: 16) {
                ProgressRing(progress: progress.progress, label: "Entregas aprobadas")
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(progress.approvedDeliveries) de \(progress.totalDeliveries) entregas aprobadas")
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Cada entrega aprobada por tu mentor libera el pago del hito.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var nextDeliveryCard: some View {
        Card("Próxima entrega", systemImage: "calendar", isSample: true) {
            VStack(alignment: .leading, spacing: 2) {
                Text(progress.nextDeliveryTitle)
                    .font(.headline)
                Text(progress.nextDeliveryProject)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)

            Label(daysText, systemImage: "hourglass")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.orange)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Label("Comentario de \(progress.mentorName)", systemImage: "text.bubble")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(UserRole.mentor.tint)
                Text("“\(progress.mentorComment)”")
                    .font(.subheadline)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var daysText: String {
        progress.daysUntilNextDelivery == 1
            ? "Vence mañana"
            : "Vence en \(progress.daysUntilNextDelivery) días"
    }
}

/// Proyecto recomendado: negocio, tecnologías, coincidencias con el perfil, presupuesto y duración.
private struct OpportunityCard: View {
    let opportunity: SampleOpportunity
    let profileTechnologies: [String]

    var body: some View {
        let shared = opportunity.sharedTechnologies(with: profileTechnologies)
        Card(opportunity.title, systemImage: "briefcase.fill", isSample: true) {
            Text(opportunity.business)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TagCloud(tags: opportunity.technologies, tint: .accent)

            if !shared.isEmpty {
                Label("Coincide con tu perfil: \(shared.joined(separator: ", "))", systemImage: "checkmark.circle.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.brandGreen)
                    .fixedSize(horizontal: false, vertical: true)
            }

            DetailRow(title: "Presupuesto", value: SampleData.soles(opportunity.budget), systemImage: "banknote")
            DetailRow(title: "Duración", value: "\(opportunity.weeks) semanas", systemImage: "calendar")
        }
    }
}

#if DEBUG
private extension JuniorDashboardView {
    @ViewBuilder
    static var preview: some View {
        let profile = UserProfile.previewJunior
        if case .junior(let junior) = profile.details {
            NavigationStack {
                JuniorDashboardView(name: profile.name, junior: junior)
                    .navigationTitle("Inicio")
                    .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            Text("El perfil de vista previa no es de junior.")
        }
    }
}

#Preview("Junior") {
    JuniorDashboardView.preview
}

#Preview("Junior · oscuro") {
    JuniorDashboardView.preview
        .preferredColorScheme(.dark)
}

#Preview("Junior · XXXL") {
    JuniorDashboardView.preview
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
