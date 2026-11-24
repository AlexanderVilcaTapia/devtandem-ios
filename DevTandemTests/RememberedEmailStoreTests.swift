//
//  RememberedEmailStoreTests.swift
//  DevTandemTests
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation
import Testing
@testable import DevTandem

/// Cada prueba usa su propia suite de UserDefaults y la borra al terminar.
@MainActor
final class RememberedEmailStoreTests {

    private let suiteName = "RememberedEmailStoreTests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let store: RememberedEmailStore

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
        store = RememberedEmailStore(defaults: defaults)
    }

    deinit {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    @Test("Sin nada guardado no hay correo recordado")
    func emptyByDefault() {
        #expect(store.rememberedEmail == nil)
    }

    @Test("Con el switch encendido se guarda el correo recortado")
    func remember() {
        store.update(email: " ana@empresa.com ", remember: true)
        #expect(store.rememberedEmail == "ana@empresa.com")
        #expect(defaults.string(forKey: RememberedEmailStore.key) == "ana@empresa.com")
    }

    @Test("Con el switch apagado se borra el correo guardado")
    func forget() {
        store.update(email: "ana@empresa.com", remember: true)
        store.update(email: "ana@empresa.com", remember: false)
        #expect(store.rememberedEmail == nil)
        #expect(defaults.object(forKey: RememberedEmailStore.key) == nil)
    }

    @Test("Un correo nuevo reemplaza al anterior")
    func replace() {
        store.update(email: "ana@empresa.com", remember: true)
        store.update(email: "luis@correo.com", remember: true)
        #expect(store.rememberedEmail == "luis@correo.com")
    }

    @Test("Un correo vacío no se guarda aunque el switch esté encendido")
    func emptyEmailIsNotSaved() {
        store.update(email: "ana@empresa.com", remember: true)
        store.update(email: "   ", remember: true)
        #expect(store.rememberedEmail == nil)
    }

    @Test("Un valor vacío guardado por otra vía se ignora")
    func storedBlankValue() {
        defaults.set("  ", forKey: RememberedEmailStore.key)
        #expect(store.rememberedEmail == nil)
    }
}
