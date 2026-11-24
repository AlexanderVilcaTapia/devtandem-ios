//
//  RememberedEmailStore.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation

/// "Recordar mi correo" del login, guardado en la memoria del dispositivo (UserDefaults).
/// Solo se guarda el correo, nunca la contraseña.
struct RememberedEmailStore {

    static let key = "rememberedEmail"

    private let defaults: UserDefaults

    /// En los tests se pasa un `UserDefaults(suiteName:)` propio para no tocar el de la app.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Correo guardado, o nil si no hay ninguno (o si quedó vacío).
    var rememberedEmail: String? {
        guard let email = defaults.string(forKey: Self.key)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty
        else { return nil }
        return email
    }

    /// Se llama después de un login exitoso: si `remember` es true guarda el correo; si no, lo borra.
    func update(email: String, remember: Bool) {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if remember, !trimmed.isEmpty {
            defaults.set(trimmed, forKey: Self.key)
        } else {
            defaults.removeObject(forKey: Self.key)
        }
    }
}
