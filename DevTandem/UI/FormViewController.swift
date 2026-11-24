//
//  FormViewController.swift
//  DevTandem
//
//  Created by Alexander Manuel Vilca Tapia on 17/11/26.
//

import UIKit

/// Clase base de las pantallas con formulario (login y registro).
/// Centraliza: ajuste del scroll con el teclado, tecla Siguiente/Listo entre campos visibles,
/// cierre del teclado y mensajes de error accesibles.
class FormViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {

    /// Scroll view que contiene el formulario. La subclase lo asigna en viewDidLoad.
    var keyboardScrollView: UIScrollView?

    private var formFields: [UITextField] = []
    private weak var activeField: UITextField?

    // MARK: - Ciclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(
            self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(
            self, name: UIResponder.keyboardWillHideNotification, object: nil)
        view.endEditing(true)
    }

    // MARK: - Configuración de campos

    /// Registra los campos en orden visual para la navegación con Siguiente/Listo.
    func configureFields(_ fields: [UITextField]) {
        formFields = fields
        for field in fields {
            field.delegate = self
            field.addTarget(self, action: #selector(fieldEditingChanged(_:)), for: .editingChanged)
        }
    }

    /// Se llama cuando el usuario pulsa "Listo" en el último campo visible. Las subclases lo sobrescriben.
    func formDidRequestSubmit() {}

    @objc private func fieldEditingChanged(_ sender: UITextField) {
        (sender as? PaddedTextField)?.isInvalid = false
    }

    // MARK: - Errores

    /// Muestra un mensaje de error, marca los campos inválidos y lo anuncia a VoiceOver.
    func showError(_ message: String, in label: UILabel, invalidFields: [PaddedTextField] = []) {
        invalidFields.forEach { $0.isInvalid = true }
        label.text = message
        setErrorLabel(label, visible: true)
        UIAccessibility.post(notification: .announcement, argument: message)
        _ = invalidFields.first?.becomeFirstResponder()
    }

    /// Oculta el mensaje de error y quita las marcas rojas de todos los campos.
    func clearErrors(in label: UILabel) {
        formFields.forEach { ($0 as? PaddedTextField)?.isInvalid = false }
        label.text = nil
        setErrorLabel(label, visible: false)
    }

    private func setErrorLabel(_ label: UILabel, visible: Bool) {
        let shouldHide = !visible
        UIView.animate(withDuration: 0.25) {
            // Solo se asigna si cambia: reasignar el mismo valor de isHidden a un arranged subview
            // deja al UIStackView inconsistente (pasa al mostrar dos errores seguidos).
            if label.isHidden != shouldHide {
                label.isHidden = shouldHide
            }
            label.alpha = visible ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Estado de carga

    /// true mientras hay una petición en curso. Las subclases lo revisan para ignorar toques dobles.
    private(set) var isLoading = false

    /// Controles que se deshabilitan durante la carga, además de los campos de texto:
    /// botones secundarios, switches, menús y el selector de rol. La subclase lo asigna.
    var controlsDisabledWhileLoading: [UIControl] = []

    private var idleTitle: String?

    /// Activa o quita el estado de carga. `button` muestra un indicador y `loadingTitle`; al terminar
    /// recupera su título. Mientras carga: no se puede editar ni volver atrás, y se ignoran los toques dobles.
    func setLoading(_ loading: Bool, on button: UIButton, loadingTitle: String) {
        guard loading != isLoading else { return }
        isLoading = loading

        if loading {
            view.endEditing(true)
            idleTitle = button.configuration?.title
        }

        formFields.forEach { $0.isEnabled = !loading }
        controlsDisabledWhileLoading
            .filter { $0 !== button }
            .forEach { $0.isEnabled = !loading }

        // El botón activo no se deshabilita (se vería gris con el indicador): solo deja de recibir toques.
        button.isUserInteractionEnabled = !loading
        if var configuration = button.configuration {
            configuration.showsActivityIndicator = loading
            configuration.title = loading ? loadingTitle : idleTitle
            button.configuration = configuration
        }

        navigationItem.hidesBackButton = loading
        navigationController?.interactivePopGestureRecognizer?.isEnabled = !loading

        if loading {
            UIAccessibility.post(notification: .announcement, argument: loadingTitle)
        } else {
            idleTitle = nil
        }
    }

    // MARK: - Teclado

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let scrollView = keyboardScrollView,
              let endFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else { return }
        let keyboardTop = view.convert(endFrame, from: nil).minY
        let scrollBottom = view.convert(scrollView.bounds, from: scrollView).maxY
        updateBottomInset(max(0, scrollBottom - keyboardTop), userInfo: notification.userInfo)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        updateBottomInset(0, userInfo: notification.userInfo)
    }

    private func updateBottomInset(_ inset: CGFloat, userInfo: [AnyHashable: Any]?) {
        guard let scrollView = keyboardScrollView else { return }
        let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        UIView.animate(withDuration: duration) {
            scrollView.contentInset.bottom = inset
            scrollView.verticalScrollIndicatorInsets.bottom = inset
        }
        scrollToActiveField()
    }

    private func scrollToActiveField() {
        guard let scrollView = keyboardScrollView, let field = activeField else { return }
        let rect = scrollView.convert(field.bounds, from: field).insetBy(dx: 0, dy: -24)
        scrollView.scrollRectToVisible(rect, animated: true)
    }

    // MARK: - UITextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
        textField.returnKeyType = nextVisibleField(after: textField) == nil ? .done : .next
        textField.reloadInputViews()
        DispatchQueue.main.async { [weak self] in
            self?.scrollToActiveField()
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if activeField === textField { activeField = nil }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let next = nextVisibleField(after: textField) {
            next.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            formDidRequestSubmit()
        }
        return true
    }

    private func nextVisibleField(after field: UITextField) -> UITextField? {
        guard let index = formFields.firstIndex(of: field) else { return nil }
        return formFields[(index + 1)...].first { isEffectivelyVisible($0) }
    }

    /// Un campo dentro de un stack oculto (por el rol elegido) no cuenta como visible.
    private func isEffectivelyVisible(_ candidate: UIView) -> Bool {
        var current: UIView? = candidate
        while let item = current {
            if item.isHidden || item.alpha == 0 { return false }
            current = item.superview
        }
        return true
    }

    // MARK: - UIGestureRecognizerDelegate

    /// El toque para cerrar el teclado se ignora sobre controles (campos, botones, segmentos).
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var current = touch.view
        while let item = current {
            if item is UIControl { return false }
            current = item.superview
        }
        return true
    }
}
