//
//  SampleDataTests.swift
//  DevTandemTests
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation
import Testing
@testable import DevTandem

struct SampleDataTests {

    private func project(_ statuses: [EscrowStatus]) -> SampleProject {
        SampleProject(
            id: "p",
            name: "Proyecto",
            juniorName: "Junior",
            mentorName: "Mentor",
            milestones: statuses.enumerated().map { index, status in
                SampleMilestone(id: "h\(index)", title: "Hito \(index)", amount: 100, status: status)
            }
        )
    }

    @Test("El avance de un proyecto es la fracción de hitos liberados")
    func projectProgress() {
        #expect(project([.released, .inReview, .funded, .funded]).progress == 0.25)
        #expect(project([.released, .released]).progress == 1)
        #expect(project([]).progress == 0)
    }

    @Test("El hito actual es el primero no liberado; nil si todo se liberó")
    func currentMilestone() {
        #expect(project([.released, .inReview, .funded]).currentMilestone?.id == "h1")
        #expect(project([.released, .released]).currentMilestone == nil)
    }

    @Test("El monto total suma todos los hitos")
    func totalAmount() {
        #expect(project([.released, .funded, .funded]).totalAmount == 300)
    }

    @Test("Las tecnologías compartidas no distinguen mayúsculas")
    func sharedTechnologies() {
        let opportunity = SampleOpportunity(
            id: "o", title: "T", business: "N",
            technologies: ["Swift", "SwiftUI", "Firebase"], budget: 1, weeks: 1
        )
        #expect(opportunity.sharedTechnologies(with: ["swift", "FIREBASE", "Kotlin"]) == ["Swift", "Firebase"])
        #expect(opportunity.sharedTechnologies(with: []).isEmpty)
    }

    @Test("Las recomendaciones ponen primero las que comparten más tecnologías")
    func recommendationsOrder() {
        let recommended = SampleData.recommendedOpportunities(for: ["kotlin", "Firebase"])
        #expect(recommended.first?.id == "oportunidad-citas")
        #expect(recommended.count == SampleData.juniorOpportunities.count)
    }

    @Test("Sin coincidencias, se conserva el orden original")
    func recommendationsWithoutMatches() {
        let recommended = SampleData.recommendedOpportunities(for: ["COBOL"])
        #expect(recommended.map(\.id) == SampleData.juniorOpportunities.map(\.id))
    }

    @Test("Las revisiones se ordenan de la más antigua a la más reciente")
    func reviewsOrder() {
        let hours = SampleData.reviewsByWaitingTime.map(\.waitingHours)
        #expect(hours == hours.sorted(by: >))
    }

    @Test("Los identificadores de muestra no se repiten")
    func uniqueIdentifiers() {
        let ids = SampleData.clientProjects.map(\.id)
            + SampleData.clientProjects.flatMap { $0.milestones.map(\.id) }
            + SampleData.juniorOpportunities.map(\.id)
            + SampleData.mentorReviews.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("Los valores de muestra están en rangos válidos")
    func validRanges() {
        for project in SampleData.clientProjects {
            #expect((0...1).contains(project.progress))
            #expect(!project.milestones.isEmpty)
        }
        let progress = SampleData.juniorProgress
        #expect(progress.approvedDeliveries <= progress.totalDeliveries)
        #expect((0...1).contains(SampleData.mentorStats.firstPassApprovalRate))
    }

    @Test("El avance del junior es la fracción de entregas aprobadas")
    func juniorProgress() {
        let progress = SampleJuniorProgress(
            approvedDeliveries: 3, totalDeliveries: 4,
            nextDeliveryTitle: "", nextDeliveryProject: "", daysUntilNextDelivery: 1,
            mentorName: "", mentorComment: ""
        )
        #expect(progress.progress == 0.75)
    }

    @Test("Los montos se muestran en soles")
    func solesFormat() {
        let text = SampleData.soles(1_800)
        #expect(text.contains("S/"))
        #expect(text.contains("1"))
        #expect(text.contains("800"))
    }
}
