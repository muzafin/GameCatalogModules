//
//  EditProfileViewController.swift
//  GameCatalog
//

import GameCatalogDomain
import UIKit

final class EditProfileViewController: UIViewController {

    var onSave: (() -> Void)?

    private let profile: UserProfile
    private let profileUseCase: ProfileUseCaseProtocol

    private lazy var nameField = makeTextField(
        placeholder: "Nama lengkap",
        text: profile.name
    )

    private lazy var emailField: UITextField = {
        let field = makeTextField(placeholder: "Email", text: profile.email)
        field.keyboardType = .emailAddress
        field.textContentType = .emailAddress
        field.autocapitalizationType = .none
        return field
    }()

    private lazy var roleField = makeTextField(
        placeholder: "Peran",
        text: profile.role
    )

    init(profile: UserProfile, profileUseCase: ProfileUseCaseProtocol) {
        self.profile = profile
        self.profileUseCase = profileUseCase
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = "Edit Profile"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )

        let formStack = UIStackView(arrangedSubviews: [
            makeFieldGroup(title: "Nama", field: nameField),
            makeFieldGroup(title: "Email", field: emailField),
            makeFieldGroup(title: "Peran", field: roleField)
        ])
        formStack.translatesAutoresizingMaskIntoConstraints = false
        formStack.axis = .vertical
        formStack.spacing = 20

        view.addSubview(formStack)
        NSLayoutConstraint.activate([
            formStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            formStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            formStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func makeTextField(placeholder: String, text: String) -> UITextField {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = placeholder
        field.text = text
        field.borderStyle = .roundedRect
        field.backgroundColor = .secondarySystemGroupedBackground
        field.clearButtonMode = .whileEditing
        field.heightAnchor.constraint(equalToConstant: 46).isActive = true
        return field
    }

    private func makeFieldGroup(title: String, field: UITextField) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [label, field])
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }

    private func trimmedText(from field: UITextField) -> String {
        return field.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func showValidationError() {
        let alert = UIAlertController(
            title: "Data Belum Lengkap",
            message: "Nama, email, dan peran tidak boleh kosong.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        let name = trimmedText(from: nameField)
        let email = trimmedText(from: emailField)
        let role = trimmedText(from: roleField)

        guard !name.isEmpty, !email.isEmpty, !role.isEmpty else {
            showValidationError()
            return
        }

        profileUseCase.save(UserProfile(name: name, email: email, role: role))
        onSave?()
        dismiss(animated: true)
    }
}
