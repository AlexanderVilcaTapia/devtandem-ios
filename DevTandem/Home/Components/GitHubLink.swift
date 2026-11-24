//
//  GitHubLink.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 24/11/26.
//

import SwiftUI

/// Enlace al perfil de GitHub que muestra solo el usuario. Si la dirección no es válida, muestra el texto sin enlace.
struct GitHubLink: View {
    let urlString: String

    private var username: String {
        urlString.hasPrefix(FieldValidators.gitHubProfilePrefix)
            ? String(urlString.dropFirst(FieldValidators.gitHubProfilePrefix.count))
            : urlString
    }

    var body: some View {
        if let url = URL(string: urlString), url.scheme == "https" {
            Link(destination: url) {
                HStack(spacing: 6) {
                    Label(username, systemImage: "link")
                    Image(systemName: "arrow.up.right.square")
                        .font(.footnote)
                        .accessibilityHidden(true)
                }
                .font(.subheadline.weight(.medium))
            }
            .accessibilityLabel("Perfil de GitHub: \(username)")
            .accessibilityHint("Se abre en el navegador")
        } else {
            Label(urlString, systemImage: "link")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        GitHubLink(urlString: "https://github.com/diego-ejemplo")
        GitHubLink(urlString: "no es una dirección")
    }
    .padding()
}
