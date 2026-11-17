# DevTándem iOS

App iOS nativa de **DevTándem**: plataforma "Talento junior, respaldo senior" que conecta
clientes (Mypes y startups) con programadores junior, con validación de código por un mentor senior
antes de la entrega y pagos en custodia (escrow) por hito.

Trabajo final del curso **Programación en Móviles Avanzado** (Tecsup, 2026-02).

## Stack
- Swift (modo de lenguaje Swift 5), UIKit como app base y SwiftUI incrustado con UIHostingController
- iOS 17.6 como versión mínima
- Firebase iOS SDK por Swift Package Manager: Authentication, Realtime Database y Storage
- CoreData (UIKit) y SwiftData (SwiftUI)

## Requisitos
- Xcode 27.2 (el SDK de Firebase usado exige Xcode 26.2 o superior)
- Simulador con iOS 17 o superior

## Configuración de Firebase (obligatoria)
El archivo `GoogleService-Info.plist` **no se versiona** porque contiene la configuración del proyecto Firebase.

1. Pídelo al equipo (Drive).
2. Arrástralo en Xcode a la carpeta `DevTandem` (la que contiene `AppDelegate.swift`) marcando "Copy items if needed" y el target `DevTandem`.
3. Compila y ejecuta. En la consola debe aparecer `Firebase configurado`.

Sin este archivo la app se detiene en modo Debug con el mensaje "Falta GoogleService-Info.plist".

## Control de versiones
Commits con la convención Conventional Commits, en español (`feat`, `fix`, `docs`, `build`, `test`, `chore`).
Nunca se suben secretos (`GoogleService-Info.plist`, `Secrets.plist`).

## Estado
En desarrollo.
