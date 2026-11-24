//
//  SampleData.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation

// Datos de MUESTRA para las pantallas de inicio. Todo es ficticio: las personas, los negocios
// y los montos son inventados y no corresponden a marcas ni a personas reales.
// En la UI, cada tarjeta que usa estos datos lleva la etiqueta "Muestra".

// MARK: - Cliente

/// Estado del pago en custodia (escrow) de un hito. Los pagos de DevTándem son simulados.
nonisolated enum EscrowStatus: CaseIterable, Equatable {
    /// El cliente depositó el monto; queda retenido hasta aprobar el hito.
    case funded
    /// El junior entregó y el mentor está revisando el código.
    case inReview
    /// El hito se aprobó y el pago se liberó al junior.
    case released

    var title: String {
        switch self {
        case .funded: return "En custodia"
        case .inReview: return "En revisión del mentor"
        case .released: return "Liberado"
        }
    }

    var symbolName: String {
        switch self {
        case .funded: return "lock.fill"
        case .inReview: return "magnifyingglass"
        case .released: return "checkmark.circle.fill"
        }
    }
}

nonisolated struct SampleMilestone: Identifiable, Equatable {
    let id: String
    let title: String
    let amount: Decimal
    let status: EscrowStatus
}

nonisolated struct SampleProject: Identifiable, Equatable {
    let id: String
    let name: String
    let juniorName: String
    let mentorName: String
    let milestones: [SampleMilestone]

    /// Fracción de hitos con el pago liberado (0 si no hay hitos).
    var progress: Double {
        guard !milestones.isEmpty else { return 0 }
        let released = milestones.filter { $0.status == .released }.count
        return Double(released) / Double(milestones.count)
    }

    var totalAmount: Decimal {
        milestones.reduce(Decimal(0)) { $0 + $1.amount }
    }

    /// Primer hito que aún no se libera; nil si el proyecto terminó.
    var currentMilestone: SampleMilestone? {
        milestones.first { $0.status != .released }
    }
}

// MARK: - Junior

nonisolated struct SampleOpportunity: Identifiable, Equatable {
    let id: String
    let title: String
    let business: String
    let technologies: [String]
    let budget: Decimal
    let weeks: Int

    /// Tecnologías del proyecto que también están en el perfil, sin distinguir mayúsculas.
    func sharedTechnologies(with profileTechnologies: [String]) -> [String] {
        let known = Set(profileTechnologies.map { $0.lowercased() })
        return technologies.filter { known.contains($0.lowercased()) }
    }
}

nonisolated struct SampleJuniorProgress: Equatable {
    let approvedDeliveries: Int
    let totalDeliveries: Int
    let nextDeliveryTitle: String
    let nextDeliveryProject: String
    let daysUntilNextDelivery: Int
    let mentorName: String
    let mentorComment: String

    /// Fracción de entregas aprobadas (0 si no hay entregas).
    var progress: Double {
        guard totalDeliveries > 0 else { return 0 }
        return Double(approvedDeliveries) / Double(totalDeliveries)
    }
}

// MARK: - Mentor

nonisolated struct SampleReview: Identifiable, Equatable {
    let id: String
    let juniorName: String
    let projectName: String
    let milestoneTitle: String
    let waitingHours: Int
    let technologies: [String]
}

nonisolated struct SampleMentorStats: Equatable {
    let reviewsThisWeek: Int
    let averageReviewHours: Double
    /// Fracción de entregas aprobadas en la primera revisión.
    let firstPassApprovalRate: Double
}

// MARK: - Datos

nonisolated enum SampleData {

    static let clientProjects: [SampleProject] = [
        SampleProject(
            id: "proyecto-tienda",
            name: "Tienda en línea de panes y postres",
            juniorName: "Diego Mamani",
            mentorName: "Lucía Paredes",
            milestones: [
                SampleMilestone(id: "tienda-1", title: "Catálogo de productos", amount: 600, status: .released),
                SampleMilestone(id: "tienda-2", title: "Carrito y pedidos", amount: 900, status: .inReview),
                SampleMilestone(id: "tienda-3", title: "Panel de administración", amount: 700, status: .funded)
            ]
        ),
        SampleProject(
            id: "proyecto-landing",
            name: "Página de reservas del taller",
            juniorName: "Valeria Condori",
            mentorName: "Martín Salazar",
            milestones: [
                SampleMilestone(id: "landing-1", title: "Diseño y maqueta", amount: 350, status: .released),
                SampleMilestone(id: "landing-2", title: "Formulario de reservas", amount: 450, status: .released),
                SampleMilestone(id: "landing-3", title: "Publicación y ajustes", amount: 200, status: .funded)
            ]
        )
    ]

    static let juniorOpportunities: [SampleOpportunity] = [
        SampleOpportunity(
            id: "oportunidad-inventario",
            title: "App de inventario para una ferretería",
            business: "Ferretería El Clavo Dorado",
            technologies: ["Swift", "SwiftUI", "Firebase"],
            budget: 1_800,
            weeks: 6
        ),
        SampleOpportunity(
            id: "oportunidad-menu",
            title: "Menú digital con código QR",
            business: "Cevichería La Ola Brava",
            technologies: ["React", "JavaScript", "CSS"],
            budget: 900,
            weeks: 3
        ),
        SampleOpportunity(
            id: "oportunidad-citas",
            title: "Agenda de citas para un consultorio",
            business: "Consultorio Dental Sonrisa Andina",
            technologies: ["Kotlin", "Firebase"],
            budget: 1_500,
            weeks: 5
        ),
        SampleOpportunity(
            id: "oportunidad-reportes",
            title: "Reportes de ventas desde Excel",
            business: "Distribuidora Valle Verde",
            technologies: ["Python", "SQL"],
            budget: 1_200,
            weeks: 4
        )
    ]

    static let juniorProgress = SampleJuniorProgress(
        approvedDeliveries: 4,
        totalDeliveries: 6,
        nextDeliveryTitle: "Carrito y pedidos",
        nextDeliveryProject: "Tienda en línea de panes y postres",
        daysUntilNextDelivery: 3,
        mentorName: "Lucía Paredes",
        mentorComment: "Buen avance. Separa la lógica del carrito en su propio ViewModel y agrega pruebas para el cálculo del total."
    )

    static let mentorReviews: [SampleReview] = [
        SampleReview(
            id: "revision-carrito",
            juniorName: "Diego Mamani",
            projectName: "Tienda en línea de panes y postres",
            milestoneTitle: "Carrito y pedidos",
            waitingHours: 5,
            technologies: ["Swift", "SwiftUI"]
        ),
        SampleReview(
            id: "revision-api",
            juniorName: "Camila Rojas",
            projectName: "Control de asistencia de un gimnasio",
            milestoneTitle: "API de registro de ingresos",
            waitingHours: 20,
            technologies: ["Node.js", "PostgreSQL"]
        ),
        SampleReview(
            id: "revision-formulario",
            juniorName: "Valeria Condori",
            projectName: "Página de reservas del taller",
            milestoneTitle: "Formulario de reservas",
            waitingHours: 30,
            technologies: ["React", "CSS"]
        )
    ]

    static let mentorStats = SampleMentorStats(
        reviewsThisWeek: 9,
        averageReviewHours: 6.5,
        firstPassApprovalRate: 0.72
    )

    /// Oportunidades ordenadas por cuántas tecnologías comparten con el perfil (más primero).
    /// Con el mismo número, se respeta el orden original. Si ninguna coincide, se muestran todas igual.
    static func recommendedOpportunities(for technologies: [String]) -> [SampleOpportunity] {
        juniorOpportunities
            .enumerated()
            .sorted { lhs, rhs in
                let left = lhs.element.sharedTechnologies(with: technologies).count
                let right = rhs.element.sharedTechnologies(with: technologies).count
                return left != right ? left > right : lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    /// Revisiones ordenadas por tiempo de espera, la más antigua primero.
    static var reviewsByWaitingTime: [SampleReview] {
        mentorReviews.sorted { $0.waitingHours > $1.waitingHours }
    }

    /// Monto en soles con formato peruano (por ejemplo, "S/ 1,800.00").
    static func soles(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: "PEN").locale(Locale(identifier: "es_PE")))
    }
}
