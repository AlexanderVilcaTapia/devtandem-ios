//
//  ProfileRepository.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import Foundation
import FirebaseDatabase
import FirebaseSharedSwift
import os

/// Falla al leer o escribir en Realtime Database, ya clasificada.
nonisolated enum RemoteDataError: Error, Equatable {
    /// El nodo no existe.
    case notFound
    /// El nodo existe pero no se pudo decodificar (faltan claves o hay valores desconocidos).
    case incomplete
    case network
    case timeout
    case permissionDenied
    case unexpected(code: Int)

    /// Dominios y códigos verificados en el código fuente de FirebaseDatabase 13.2.0:
    /// - Escrituras rechazadas: dominio "com.firebase"; 1 = permission_denied, 2 = unavailable.
    /// - `getData` fallido: dominio "com.firebase.core", código 1. El motivo va en
    ///   `NSLocalizedFailureReasonErrorKey`: "Client is offline." o el que mande el servidor.
    static func fromDatabaseError(_ error: Error) -> RemoteDataError {
        let nsError = error as NSError
        switch nsError.domain {
        case "com.firebase":
            switch nsError.code {
            case 1: return .permissionDenied
            case 2: return .network
            default: return .unexpected(code: nsError.code)
            }
        case "com.firebase.core":
            let reason = nsError.userInfo[NSLocalizedFailureReasonErrorKey] as? String
            switch reason {
            case "Client is offline.": return .network
            case "permission_denied": return .permissionDenied
            default: return .unexpected(code: nsError.code)
            }
        case NSURLErrorDomain:
            return .network
        default:
            return .unexpected(code: nsError.code)
        }
    }
}

/// Lectura y escritura de perfiles en `/users/{uid}`.
protocol ProfileRepository: AnyObject {
    /// Guarda el perfil. `createdAt` lo pone el servidor.
    func save(_ profile: UserProfile, uid: String) async throws(RemoteDataError)
    func fetchProfile(uid: String) async throws(RemoteDataError) -> UserProfile
    /// Descarta las escrituras que aún no confirmó el servidor (antes del rollback).
    func discardPendingWrites()
}

/// Implementación con Firebase Realtime Database.
final class RealtimeProfileRepository: ProfileRepository {

    /// Sin conexión, `setValue` no llama a su completion hasta que el servidor confirma,
    /// así que el guardado necesita un tiempo máximo propio. La lectura usa el mismo,
    /// para que el arranque de la app nunca se quede esperando.
    private let saveTimeout: TimeInterval
    private let logger = Logger(subsystem: "com.devtandem.app", category: "ProfileRepository")

    /// Se obtiene en cada uso para no tocar Firebase antes de `FirebaseApp.configure()`.
    private var database: Database { Database.database() }

    init(saveTimeout: TimeInterval = 15) {
        self.saveTimeout = saveTimeout
    }

    private func profileReference(uid: String) -> DatabaseReference {
        database.reference(withPath: "users").child(uid)
    }

    // MARK: - Guardar

    func save(_ profile: UserProfile, uid: String) async throws(RemoteDataError) {
        let value: [String: Any]
        do {
            guard let encoded = try Database.Encoder().encode(profile) as? [String: Any] else {
                logger.error("El perfil no se codificó como diccionario")
                throw RemoteDataError.unexpected(code: -1)
            }
            value = encoded
        } catch let error as RemoteDataError {
            throw error
        } catch {
            logger.error("No se pudo codificar el perfil: \(String(describing: type(of: error)), privacy: .public)")
            throw .unexpected(code: -1)
        }

        // La fecha de creación la pone el servidor (milisegundos, el mismo formato de UserProfile).
        var payload = value
        payload[UserProfile.CodingKeys.createdAt.rawValue] = ServerValue.timestamp()

        let outcome = await write(payload, to: profileReference(uid: uid))
        switch outcome {
        case .saved:
            return
        case .failed(let error):
            let classified = RemoteDataError.fromDatabaseError(error)
            let nsError = error as NSError
            logger.error("save falló: \(nsError.domain, privacy: .public) \(nsError.code, privacy: .public)")
            throw classified
        case .timedOut:
            logger.error("save superó el tiempo máximo de \(self.saveTimeout, privacy: .public) s")
            throw .timeout
        }
    }

    private enum WriteOutcome: Sendable {
        case saved
        case failed(Error)
        case timedOut
    }

    /// Escribe y espera lo que llegue primero: la respuesta del servidor o el timeout.
    private func write(_ payload: [String: Any], to reference: DatabaseReference) async -> WriteOutcome {
        let timeout = saveTimeout
        return await withCheckedContinuation { (continuation: CheckedContinuation<WriteOutcome, Never>) in
            let gate = ResumeOnceGate(continuation)
            reference.setValue(payload) { error, _ in
                gate.resume(with: error.map { .failed($0) } ?? .saved)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                gate.resume(with: .timedOut)
            }
        }
    }

    // MARK: - Leer

    func fetchProfile(uid: String) async throws(RemoteDataError) -> UserProfile {
        let result = await read(profileReference(uid: uid))
        switch result {
        case .success(let profile):
            return profile
        case .failure(let error):
            throw error
        }
    }

    /// Lee y decodifica el perfil, y espera lo que llegue primero: la respuesta o el timeout.
    /// La decodificación se hace dentro del callback porque `DataSnapshot` no es `Sendable`.
    private func read(_ reference: DatabaseReference) async -> Result<UserProfile, RemoteDataError> {
        let timeout = saveTimeout
        let logger = logger
        return await withCheckedContinuation { (continuation: CheckedContinuation<Result<UserProfile, RemoteDataError>, Never>) in
            let gate = ResumeOnceGate(continuation)
            reference.getData { error, snapshot in
                if let error {
                    let nsError = error as NSError
                    logger.error("fetchProfile falló: \(nsError.domain, privacy: .public) \(nsError.code, privacy: .public)")
                    gate.resume(with: .failure(RemoteDataError.fromDatabaseError(error)))
                    return
                }
                guard let snapshot, snapshot.exists() else {
                    gate.resume(with: .failure(.notFound))
                    return
                }
                do {
                    gate.resume(with: .success(try snapshot.data(as: UserProfile.self)))
                } catch {
                    // No se registra el contenido del perfil: tiene datos personales.
                    logger.error("El perfil existe pero no se pudo decodificar: \(String(describing: type(of: error)), privacy: .public)")
                    gate.resume(with: .failure(.incomplete))
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                gate.resume(with: .failure(.timeout))
            }
        }
    }

    func discardPendingWrites() {
        database.purgeOutstandingWrites()
    }
}

/// Reanuda una continuación una sola vez, aunque la llamen dos fuentes (respuesta y timeout).
/// Reanudar dos veces una `CheckedContinuation` es un error en tiempo de ejecución.
nonisolated final class ResumeOnceGate<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Value, Never>?

    init(_ continuation: CheckedContinuation<Value, Never>) {
        self.continuation = continuation
    }

    func resume(with value: Value) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(returning: value)
    }
}
