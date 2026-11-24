//
//  PreviewProfiles.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

#if DEBUG
import Foundation

/// Perfiles ficticios para los #Preview de Xcode. Solo existen en compilaciones de depuración.
extension UserProfile {
    static let previewClient = UserProfile(
        name: "Rosa Quispe Huamán",
        email: "rosa@ejemplo.com",
        createdAt: Date(timeIntervalSince1970: 1_790_000_000),
        details: .client(ClientProfile(
            company: "Panadería Santa Rosita",
            industry: .food,
            projectType: .ecommerce,
            companySize: .micro
        ))
    )

    static let previewJunior = UserProfile(
        name: "Diego Mamani",
        email: "diego@ejemplo.com",
        createdAt: Date(timeIntervalSince1970: 1_790_000_000),
        details: .junior(JuniorProfile(
            experience: .lessThanOneYear,
            technologies: ["Swift", "SwiftUI", "Firebase", "Git"],
            githubURL: "https://github.com/diego-ejemplo",
            availability: .tenToTwentyHours
        ))
    )

    static let previewMentor = UserProfile(
        name: "Lucía Paredes",
        email: "lucia@ejemplo.com",
        createdAt: Date(timeIntervalSince1970: 1_790_000_000),
        details: .mentor(MentorProfile(
            experience: .moreThanEightYears,
            technologies: ["Swift", "Kotlin", "Node.js", "PostgreSQL"],
            githubURL: "https://github.com/lucia-ejemplo",
            inviteCode: "EJEMPLO",
            availability: .fiveToTenHours
        ))
    )
}
#endif
