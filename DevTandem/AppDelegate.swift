//
//  AppDelegate.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 9/11/26.
//

import UIKit
import FirebaseCore
import os

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private let logger = Logger(subsystem: "com.devtandem.app", category: "AppDelegate")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureFirebase()
        return true
    }

    // MARK: - Firebase

    /// Inicializa Firebase validando antes que exista el archivo de configuración.
    /// Si falta, la app no se cae: registra el error y en desarrollo detiene la ejecución con un mensaje claro.
    private func configureFirebase() {
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            logger.error("Falta GoogleService-Info.plist en el bundle. Pídelo al equipo (Drive) y ponlo en la carpeta DevTandem.")
            assertionFailure("Falta GoogleService-Info.plist")
            return
        }

        FirebaseApp.configure()

        guard let options = FirebaseApp.app()?.options else {
            logger.error("FirebaseApp.configure() se ejecutó pero no se pudo leer la configuración.")
            return
        }

        logger.info("Firebase configurado. projectID: \(options.projectID ?? "desconocido", privacy: .public)")

        if options.databaseURL == nil {
            logger.error("El plist no trae DATABASE_URL: vuelve a descargar GoogleService-Info.plist después de crear la Realtime Database.")
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}
