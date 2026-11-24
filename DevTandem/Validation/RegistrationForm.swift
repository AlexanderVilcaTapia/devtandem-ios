//
//  RegistrationForm.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation

/// Datos crudos del formulario de registro, tal como los tiene `RegisterViewController`:
/// textos sin procesar y selecciones de menú opcionales (nil = el usuario no eligió).
/// Solo se validan los campos de la sección del rol elegido.
nonisolated struct RegistrationForm: Equatable {
    // Comunes
    var name = ""
    var email = ""
    var password = ""
    var confirmPassword = ""
    var role: UserRole = .client

    // Cliente
    var company = ""
    var industry: ClientIndustry?
    var projectType: ProjectType?
    var companySize: CompanySize?

    // Junior
    var juniorExperience: JuniorExperience?
    var juniorTechnologies = ""
    var juniorGitHub = ""
    var juniorAvailability: WeeklyAvailability?

    // Mentor
    var mentorExperience: MentorExperience?
    var mentorTechnologies = ""
    var mentorGitHub = ""
    var inviteCode = ""
    var mentorAvailability: ReviewAvailability?
}
