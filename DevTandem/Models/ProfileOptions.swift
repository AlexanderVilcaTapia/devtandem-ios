//
//  ProfileOptions.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 17/11/26.
//

import Foundation

/// Opción de un campo de selección del formulario de perfil.
/// `rawValue` es la clave estable que se guarda en Firebase; `title` es el texto en español para la UI.
/// El protocolo y los enums son `nonisolated`: son datos puros y no deben quedar atados a MainActor,
/// que es la aislación por defecto del target.
nonisolated protocol FormOption: CaseIterable, RawRepresentable, Codable where RawValue == String {
    var title: String { get }
}

// MARK: - Cliente

nonisolated enum ClientIndustry: String, FormOption {
    case retail, education, health, finance, logistics, food, technology, tourism, manufacturing, other

    var title: String {
        switch self {
        case .retail: return "Comercio y retail"
        case .education: return "Educación"
        case .health: return "Salud"
        case .finance: return "Finanzas"
        case .logistics: return "Logística y transporte"
        case .food: return "Gastronomía"
        case .technology: return "Tecnología"
        case .tourism: return "Turismo"
        case .manufacturing: return "Manufactura"
        case .other: return "Otro"
        }
    }
}

nonisolated enum ProjectType: String, FormOption {
    case landingPage, webSystem, customSoftware, mobileApp, ecommerce, integrations, other

    var title: String {
        switch self {
        case .landingPage: return "Landing page"
        case .webSystem: return "Sistema web"
        case .customSoftware: return "Software a medida"
        case .mobileApp: return "App móvil"
        case .ecommerce: return "E-commerce"
        case .integrations: return "APIs e integraciones"
        case .other: return "Otro"
        }
    }
}

nonisolated enum CompanySize: String, FormOption {
    case micro, small, medium, large

    var title: String {
        switch self {
        case .micro: return "1 a 10 personas"
        case .small: return "11 a 50 personas"
        case .medium: return "51 a 200 personas"
        case .large: return "Más de 200 personas"
        }
    }
}

// MARK: - Junior

nonisolated enum JuniorExperience: String, FormOption {
    case noExperience, lessThanOneYear, oneToTwoYears, twoToThreeYears

    var title: String {
        switch self {
        case .noExperience: return "Sin experiencia laboral"
        case .lessThanOneYear: return "Menos de 1 año"
        case .oneToTwoYears: return "1 a 2 años"
        case .twoToThreeYears: return "2 a 3 años"
        }
    }
}

nonisolated enum WeeklyAvailability: String, FormOption {
    case lessThanTenHours, tenToTwentyHours, twentyToThirtyHours, moreThanThirtyHours

    var title: String {
        switch self {
        case .lessThanTenHours: return "Menos de 10 h por semana"
        case .tenToTwentyHours: return "10 a 20 h por semana"
        case .twentyToThirtyHours: return "20 a 30 h por semana"
        case .moreThanThirtyHours: return "Más de 30 h por semana"
        }
    }
}

// MARK: - Mentor

nonisolated enum MentorExperience: String, FormOption {
    case threeToFiveYears, fiveToEightYears, moreThanEightYears

    var title: String {
        switch self {
        case .threeToFiveYears: return "3 a 5 años"
        case .fiveToEightYears: return "5 a 8 años"
        case .moreThanEightYears: return "Más de 8 años"
        }
    }
}

nonisolated enum ReviewAvailability: String, FormOption {
    case lessThanFiveHours, fiveToTenHours, moreThanTenHours

    var title: String {
        switch self {
        case .lessThanFiveHours: return "Menos de 5 h por semana"
        case .fiveToTenHours: return "5 a 10 h por semana"
        case .moreThanTenHours: return "Más de 10 h por semana"
        }
    }
}
