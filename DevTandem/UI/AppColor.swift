//
//  AppColor.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 17/11/26.
//

import UIKit

/// Colores de marca definidos en Assets.xcassets (con variante clara y oscura).
enum AppColor {
    /// Azul principal (AccentColor): marino en modo claro, azul claro en modo oscuro.
    static let accent = UIColor(named: "AccentColor") ?? .systemBlue
    /// Verde de apoyo de la marca.
    static let green = UIColor(named: "BrandGreen") ?? .systemGreen
    /// Color del texto o ícono que va sobre un fondo `accent`.
    static let onAccent = UIColor(named: "OnAccent") ?? .white
}
