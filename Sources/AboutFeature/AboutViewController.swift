//
//  AboutViewController.swift
//  GameCatalog
//

import Common
import GameCatalogDomain
import UIKit

final class AboutViewController: UIViewController {

    private let profileUseCase: ProfileUseCaseProtocol

    init(profileUseCase: ProfileUseCaseProtocol) {
        self.profileUseCase = profileUseCase
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 60
        iv.backgroundColor = .systemGray5
        iv.layer.borderWidth = 3
        iv.layer.borderColor = UIColor.systemBlue.cgColor
        iv.image = UIImage(named: "profile")
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Muhammad Zaenal Arifin"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "iOS Developer"
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()

    private let divider: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .separator
        return v
    }()

    private let infoStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 0
        return sv
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureProfile()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = L10n.text("about.title")
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Edit",
            style: .plain,
            target: self,
            action: #selector(editProfileTapped)
        )

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubviews(profileImageView, nameLabel, subtitleLabel, divider, infoStackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),

            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            divider.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            divider.heightAnchor.constraint(equalToConstant: 1),

            infoStackView.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 8),
            infoStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            infoStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            infoStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    private func configureProfile() {
        let profile = profileUseCase.load()
        nameLabel.text = profile.name
        subtitleLabel.text = profile.role
        infoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let rows: [(String, String, String)] = [
            ("person.fill", "Nama", profile.name),
            ("envelope.fill", "Email", profile.email),
            ("graduationcap.fill", "Institusi", "Dicoding Indonesia"),
            (
                "info.circle.fill",
                "Tentang Aplikasi",
                "Game Catalog menampilkan daftar game terpopuler menggunakan data dari RAWG.io API."
            )
        ]

        rows.forEach { icon, title, value in
            let row = InfoRowView(icon: icon, title: title, value: value)
            infoStackView.addArrangedSubview(row)
            let separator = UIView()
            separator.backgroundColor = .separator
            separator.translatesAutoresizingMaskIntoConstraints = false
            separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            infoStackView.addArrangedSubview(separator)
        }
    }

    @objc private func editProfileTapped() {
        let editViewController = EditProfileViewController(
            profile: profileUseCase.load(),
            profileUseCase: profileUseCase
        )
        editViewController.onSave = { [weak self] in
            self?.configureProfile()
        }
        let navigationController = UINavigationController(rootViewController: editViewController)
        present(navigationController, animated: true)
    }
}

public enum AboutFeatureFactory {
    public static func make(useCase: ProfileUseCaseProtocol) -> UIViewController {
        AboutViewController(profileUseCase: useCase)
    }
}
