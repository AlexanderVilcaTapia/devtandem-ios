//
//  PaddedTextField.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 17/11/26.
//

import UIKit

/// Campo de texto con el estilo de DevTándem: bordes redondeados, padding interno,
/// estado de error (borde rojo) y botón opcional para mostrar u ocultar la contraseña.
final class PaddedTextField: UITextField {

    private let horizontalPadding: CGFloat = 14

    /// Marca el campo como inválido (borde rojo).
    var isInvalid = false {
        didSet { updateBorder() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        borderStyle = .none
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        layer.masksToBounds = true
        adjustsFontForContentSizeCategory = true
        font = UIFont.preferredFont(forTextStyle: .body)
        heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
        // Los CGColor no se adaptan solos al modo oscuro: se recalculan al cambiar el estilo.
        registerForTraitChanges([UITraitUserInterfaceStyle.self], action: #selector(updateBorder))
        updateBorder()
    }

    @objc private func updateBorder() {
        let color: UIColor = isInvalid ? .systemRed : .separator
        layer.borderColor = color.resolvedColor(with: traitCollection).cgColor
        layer.borderWidth = isInvalid ? 1.5 : 1
    }

    // MARK: - Padding

    override func textRect(forBounds bounds: CGRect) -> CGRect { contentRect(in: bounds) }
    override func editingRect(forBounds bounds: CGRect) -> CGRect { contentRect(in: bounds) }
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect { contentRect(in: bounds) }

    private func contentRect(in bounds: CGRect) -> CGRect {
        var insets = UIEdgeInsets(top: 0, left: horizontalPadding, bottom: 0, right: horizontalPadding)
        if let rightView, rightViewMode != .never {
            insets.right += rightView.bounds.width
        }
        return bounds.inset(by: insets)
    }

    // MARK: - Configuración por código

    /// Configura placeholder y rasgos del teclado desde código, para no depender de los
    /// atributos puestos a mano en el Storyboard.
    func configure(
        placeholder: String,
        keyboard: UIKeyboardType = .default,
        capitalization: UITextAutocapitalizationType = .none,
        contentType: UITextContentType? = nil,
        isSecure: Bool = false
    ) {
        self.placeholder = placeholder
        keyboardType = keyboard
        autocapitalizationType = capitalization
        autocorrectionType = .no
        spellCheckingType = .no
        textContentType = contentType
        isSecureTextEntry = isSecure
    }

    // MARK: - Mostrar / ocultar contraseña

    /// Agrega un botón de ojo a la derecha para alternar la visibilidad de la contraseña.
    func enablePasswordToggle() {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "eye.slash")
        configuration.baseForegroundColor = .secondaryLabel

        let button = UIButton(configuration: configuration)
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.accessibilityLabel = "Mostrar contraseña"
        button.addTarget(self, action: #selector(togglePasswordVisibility(_:)), for: .touchUpInside)

        rightView = button
        rightViewMode = .always
    }

    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        // Reasignar el texto evita que iOS lo borre al cambiar isSecureTextEntry.
        let existingText = text
        isSecureTextEntry.toggle()
        text = nil
        text = existingText

        sender.configuration?.image = UIImage(systemName: isSecureTextEntry ? "eye.slash" : "eye")
        sender.accessibilityLabel = isSecureTextEntry ? "Mostrar contraseña" : "Ocultar contraseña"
    }
}
