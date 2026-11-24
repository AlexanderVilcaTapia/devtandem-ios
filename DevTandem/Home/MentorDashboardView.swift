//
//  MentorDashboardView.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import SwiftUI

/// Panel de inicio del mentor: su perfil real y, de muestra, estadísticas de la semana
/// y revisiones de código pendientes (la más antigua primero).
struct MentorDashboardView: View {
    let name: String
    let mentor: MentorProfile
    var stats: SampleMentorStats = SampleData.mentorStats
    var reviews: [SampleReview] = SampleData.reviewsByWaitingTime

    /// A partir de este tiempo de espera, la revisión se marca como urgente.
    private static let urgentAfterHours = 24

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ProfileHeader(name: name, role: .mentor, greeting: "Hola,")
                profileCard
                SampleNotice()
                statsCard

                SectionHeader(title: "Revisiones pendientes", subtitle: "La más antigua primero")
                ForEach(reviews) { review in
                    ReviewCard(review: review, isUrgent: review.waitingHours >= Self.urgentAfterHours)
                }
            }
            .padding()
        }
        .background(Color.screenBackground)
    }

    // MARK: Datos reales

    private var profileCard: some View {
        Card("Tu perfil de mentor", systemImage: "checkmark.seal") {
            DetailRow(title: "Experiencia", value: mentor.experience.title, systemImage: "briefcase")
            if let availability = mentor.availability {
                DetailRow(title: "Revisión semanal", value: availability.title, systemImage: "clock")
            }
            GitHubLink(urlString: mentor.githubURL)
            Text("Tecnologías que revisas")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TagCloud(tags: mentor.technologies, tint: UserRole.mentor.tint)
        }
    }

    // MARK: Muestra

    private var statsCard: some View {
        let hours = stats.averageReviewHours.formatted(
            .number.precision(.fractionLength(0...1)).locale(Locale(identifier: "es_PE"))
        )
        let approval = stats.firstPassApprovalRate.formatted(.percent.precision(.fractionLength(0)))

        return Card("Esta semana", systemImage: "chart.bar", isSample: true) {
            AdaptiveStack {
                StatTile(value: "\(stats.reviewsThisWeek)", label: "Revisiones hechas",
                         systemImage: "checklist", tint: UserRole.mentor.tint)
                StatTile(value: "\(hours) h", label: "Tiempo medio de revisión",
                         systemImage: "clock", tint: .accent)
                StatTile(value: approval, label: "Aprobadas a la primera",
                         systemImage: "hand.thumbsup.fill", tint: .brandGreen)
            }
        }
    }
}

/// Revisión pendiente: hito, junior, proyecto, tecnologías y tiempo de espera.
private struct ReviewCard: View {
    let review: SampleReview
    let isUrgent: Bool

    var body: some View {
        Card(review.milestoneTitle, systemImage: "doc.text.magnifyingglass", isSample: true) {
            VStack(alignment: .leading, spacing: 2) {
                Text(review.juniorName)
                    .font(.subheadline.weight(.medium))
                Text(review.projectName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)

            TagCloud(tags: review.technologies, tint: UserRole.mentor.tint)

            Label(
                isUrgent ? "Esperando hace \(review.waitingHours) h · urgente" : "Esperando hace \(review.waitingHours) h",
                systemImage: isUrgent ? "exclamationmark.triangle.fill" : "hourglass"
            )
            .font(.footnote.weight(.medium))
            .foregroundStyle(isUrgent ? Color.orange : Color.secondary)
        }
    }
}

#if DEBUG
private extension MentorDashboardView {
    @ViewBuilder
    static var preview: some View {
        let profile = UserProfile.previewMentor
        if case .mentor(let mentor) = profile.details {
            NavigationStack {
                MentorDashboardView(name: profile.name, mentor: mentor)
                    .navigationTitle("Inicio")
                    .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            Text("El perfil de vista previa no es de mentor.")
        }
    }
}

#Preview("Mentor") {
    MentorDashboardView.preview
}

#Preview("Mentor · oscuro") {
    MentorDashboardView.preview
        .preferredColorScheme(.dark)
}

#Preview("Mentor · XXXL") {
    MentorDashboardView.preview
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
