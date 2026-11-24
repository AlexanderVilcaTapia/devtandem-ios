# DevTándem iOS

App iOS nativa de **DevTándem**, plataforma "Talento junior, respaldo senior". Conecta a clientes
(Mypes y startups) con programadores junior. Un mentor senior valida el código antes de cada entrega,
y el pago de cada hito queda en custodia (escrow) hasta su aprobación.

Los pagos son **simulados**: solo son estados en la base de datos y no se mueve dinero real.

Trabajo final del curso **Programación en Móviles Avanzado** (Tecsup, 2026-02).

## Estado (v0.1.0, Sección 2)

Funciona:
- Registro con tres roles: **cliente**, **junior** y **mentor**. Cada rol tiene sus propios campos, y el
  mentor necesita un código de invitación.
- Validaciones con mensajes en español, y errores de Firebase traducidos al español.
- Inicio de sesión, opción "Recordar mi correo" y recuperación de contraseña por correo.
- **Sesión persistente**: si ya iniciaste sesión, la app abre directo en tu pantalla de inicio.
- Pantalla de inicio distinta para cada rol, en SwiftUI, con modo oscuro, tipografía dinámica y
  VoiceOver. Los proyectos, pagos y revisiones que aparecen ahí son **datos de muestra** y lo indican
  con la etiqueta "Muestra".
- Cierre de sesión con confirmación.

Pendiente:
- Publicar las reglas de seguridad de Realtime Database. Hoy la base está en modo de prueba
  (ver [Limitaciones conocidas](#limitaciones-conocidas)).
- Proyectos e hitos reales (Sección 3).
- Google Sign-In (opcional).

## Stack

- Swift 6.4 en **modo de lenguaje Swift 5**, con aislamiento por defecto en `MainActor`.
- Una app UIKit que muestra las pantallas SwiftUI dentro de `UIHostingController`.
  - El Login y el Registro usan Storyboard.
  - Todo lo nuevo se hace en SwiftUI con MVVM (`@Observable`).
- iOS **17.6** como versión mínima.
- Firebase iOS SDK **13.2.0** por Swift Package Manager: Authentication y Realtime Database.
  Storage está enlazado, pero todavía no se usa.
- Pruebas con Swift Testing.
- Planificado para las próximas secciones: CoreData, SwiftData, consumo de una API REST y micrófono.

## Requisitos

- **Xcode 27.2**.
- Simulador con **iOS 17.6 o superior**. Un runtime de iOS 17.0 no sirve, porque el mínimo es 17.6.
- **Python 3**, solo si vas a regenerar las reglas de la base de datos.

## Configurar Firebase

El archivo `GoogleService-Info.plist` **no está en el repositorio** (está en `.gitignore`), porque
contiene la configuración del proyecto de Firebase. Para correr la app necesitas un proyecto de
Firebase propio:

1. Crea un proyecto en la [consola de Firebase](https://console.firebase.google.com/).
2. Agrega una app **iOS** con el bundle id `com.devtandem.DevTandem`. Es el del target `DevTandem`;
   si lo cambias en Xcode, usa el nuevo.
3. Descarga `GoogleService-Info.plist` y arrástralo en Xcode a la carpeta `DevTandem`, donde está
   `AppDelegate.swift`. Marca "Copy items if needed" y el target `DevTandem`.
   **No lo agregues a git.**
4. En **Authentication**, ve a Sign-in method y activa **Correo electrónico/contraseña**.
5. Crea una **Realtime Database**.
   - Si la creas después de descargar el plist, vuelve a descargarlo: tiene que incluir `DATABASE_URL`.
   - Si falta, la app lo avisa en la consola de Xcode.
6. Crea los códigos de invitación para mentores en la base de datos. Cada código es un hijo de
   `/inviteCodes` cuyo valor es el booleano `true`:

   ```
   inviteCodes
     <TU_CODIGO>: true
   ```

   Reemplaza `<TU_CODIGO>` por un código que inventes:
   - solo mayúsculas, números, `_` o `-`;
   - hasta 40 caracteres.

   La app convierte a mayúsculas lo que escribe el usuario. No publiques tus códigos.
7. Elige las reglas de seguridad:
   - **Para desarrollo**, puedes dejar la base en modo de prueba.
   - **Para usar la app de verdad**, publica `firebase/database.rules.json` en la consola, en
     Realtime Database → Reglas. Antes, pruébalas en el Rules Playground.

Al compilar y ejecutar, la consola de Xcode debe mostrar `Firebase configurado`. Si falta el plist,
la app se detiene en Debug con el mensaje "Falta GoogleService-Info.plist".

## Ejecutar y probar

- **Ejecutar:** abre `DevTandem.xcodeproj`, elige el esquema `DevTandem` y un simulador con iOS 17.6 o
  superior, y pulsa ⌘R.
- **Pruebas unitarias en Xcode:** pulsa ⌘U.
- **Pruebas unitarias en la terminal:** usa el nombre de un simulador que tengas instalado. Para
  verlos, corre `xcrun simctl list devices available`.

  ```
  xcodebuild -project DevTandem.xcodeproj -scheme DevTandem \
    -destination 'platform=iOS Simulator,name=iPhone 11,OS=27.2' \
    -only-testing:DevTandemTests test
  ```

  Si el nombre del simulador contiene " - ", `name=` no lo encuentra. En ese caso usa
  `-destination 'platform=iOS Simulator,id=<ID>'`.

Las pruebas no usan red ni Firebase: los servicios se reemplazan por dobles falsos. Cubren:

| Suite | Qué prueba |
|---|---|
| `FieldValidatorsTests`, `FormValidatorTests` | Validaciones del registro y el login, y sus mensajes |
| `UserProfileCodingTests` | El formato del perfil en la base de datos (contrato de datos) |
| `AccountErrorMappingTests` | Traducción de los errores de Firebase al español |
| `AccountServiceTests` | Registro con rollback, login, sesión guardada y cierre de sesión |
| `LaunchViewModelTests` | Arranque: sin sesión, con perfil, sin perfil y sin conexión |
| `HomeViewModelTests`, `ProfileHeaderInitialsTests` | Cierre de sesión con confirmación y errores, e iniciales del perfil |
| `SampleDataTests` | Datos de muestra de las pantallas de inicio |
| `RememberedEmailStoreTests` | "Recordar mi correo" |
| `DatabaseRulesTests` | Que las reglas sigan alineadas con los enums y límites de la app |

### Reglas de Realtime Database

`firebase/database.rules.json` **no se edita a mano**. Lo genera un script que lee los valores
permitidos directamente de los enums de Swift (`DevTandem/Models/`):

```
python3 firebase/generate_database_rules.py
```

Si agregas o cambias una opción de un enum:
1. Regenera las reglas con el script.
2. Corre las pruebas. `DatabaseRulesTests` falla si las reglas quedaron desalineadas.
3. Vuelve a publicarlas.

## Estructura

```
DevTandem/
  App/         AppRouter: decide la pantalla raíz (arranque, login o inicio)
  Launch/      Pantalla de arranque que restaura la sesión (SwiftUI)
  Auth/        Login y Registro (UIKit), AuthService, AccountService, ProfileRepository y errores
  Home/        Inicio por rol, perfil y componentes visuales (SwiftUI)
  Models/      Perfil, roles y opciones (Codable, según el contrato de datos)
  Validation/  Validadores y errores de formulario
  Storage/     Datos guardados en el dispositivo (UserDefaults)
  UI/          Base de formularios UIKit y colores de la marca
DevTandemTests/  Pruebas unitarias (Swift Testing)
firebase/        Reglas de seguridad y su generador
```

## Limitaciones conocidas

- **Código de invitación del mentor:** lo valida la regla de seguridad al guardar el perfil.
  - Mientras las reglas no se publiquen, se acepta **cualquier** código.
  - Una validación completa necesitaría un servidor propio o Cloud Functions.
  - Un código inválido crea y luego borra un usuario en Authentication (rollback).
- **Pagos simulados:** la custodia por hito es solo un estado en la base de datos.
- **Cambios de sesión con la app abierta:** si la sesión deja de ser válida en ese momento (por
  ejemplo, si se deshabilita la cuenta en la consola), la app no reacciona hasta el próximo arranque.

## Control de versiones

- Commits con Conventional Commits en español (`feat`, `fix`, `docs`, `build`, `test`, `refactor`,
  `chore`): un cambio lógico por commit, y cada commit compila.
- Los Pull Requests se fusionan **conservando los commits**, con "Create a merge commit" y sin squash.
- Nunca se suben secretos (`GoogleService-Info.plist`, `Secrets.plist`).
