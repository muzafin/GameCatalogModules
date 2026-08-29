//
//  DetailViewController.swift
//  GameCatalog
//

import Combine
import Common
import GameCatalogDomain
import UIKit

final class DetailViewController: UIViewController {

    // MARK: - Properties
    private let viewModel: DetailViewModel
    private var cancellables = Set<AnyCancellable>()

    private lazy var favoriteButton = UIBarButtonItem(
        image: UIImage(systemName: "heart"),
        style: .plain,
        target: self,
        action: #selector(favoriteTapped)
    )

    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = true
        return sv
    }()

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let heroImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray5
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()

    private let ratingView: RatingView = {
        let rv = RatingView()
        rv.translatesAutoresizingMaskIntoConstraints = false
        return rv
    }()

    private let releaseDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()

    private let genresCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 8
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .clear
        cv.register(GenreChipCell.self, forCellWithReuseIdentifier: GenreChipCell.identifier)
        return cv
    }()

    private let descriptionHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = L10n.text("detail.description")
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let infoStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 8
        return sv
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let errorView: ErrorView = {
        let view = ErrorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    // MARK: - Init
    init(viewModel: DetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.load()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = favoriteButton
        refreshFavoriteButton(isFavorite: false)

        genresCollectionView.dataSource = self

        view.addSubviews(scrollView, loadingIndicator, errorView)
        scrollView.addSubview(contentView)
        contentView.addSubviews(
            heroImageView, titleLabel, ratingView,
            releaseDateLabel, genresCollectionView,
            descriptionHeaderLabel, descriptionLabel, infoStackView
        )

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

            heroImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            heroImageView.heightAnchor.constraint(equalToConstant: 220),

            titleLabel.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            ratingView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            ratingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            releaseDateLabel.topAnchor.constraint(equalTo: ratingView.bottomAnchor, constant: 4),
            releaseDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            genresCollectionView.topAnchor.constraint(equalTo: releaseDateLabel.bottomAnchor, constant: 12),
            genresCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            genresCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            genresCollectionView.heightAnchor.constraint(equalToConstant: 32),

            descriptionHeaderLabel.topAnchor.constraint(equalTo: genresCollectionView.bottomAnchor, constant: 16),
            descriptionHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionHeaderLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            descriptionLabel.topAnchor.constraint(equalTo: descriptionHeaderLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            infoStackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            infoStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            infoStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        errorView.retryAction = { [weak viewModel = viewModel] in viewModel?.load() }
    }

    private func bindViewModel() {
        viewModel.$detail
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] detail in
                self?.configure(with: detail)
                self?.scrollView.isHidden = false
            }
            .store(in: &cancellables)

        viewModel.$isFavorite
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.refreshFavoriteButton(isFavorite: $0) }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading {
                    self?.loadingIndicator.startAnimating()
                    self?.scrollView.isHidden = true
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.errorView.isHidden = message == nil
                if let message { self?.errorView.configure(message: message) }
            }
            .store(in: &cancellables)
    }

    private func configure(with detail: GameDetail) {
        title = detail.name
        titleLabel.text = detail.name
        ratingView.configure(rating: detail.rating, count: detail.ratingsCount)

        if let released = detail.released {
            releaseDateLabel.text = "📅 " + released.formattedDate()
        }

        descriptionLabel.text = detail.description

        ImageLoader.shared.image(from: detail.backgroundImage)
            .sink { [weak self] image in self?.heroImageView.image = image }
            .store(in: &cancellables)

        genresCollectionView.reloadData()

        // Info rows
        infoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if !detail.developers.isEmpty {
            addInfoRow(icon: "person.2.fill", title: "Developer", value: detail.developers.joined(separator: ", "))
        }

        if !detail.publishers.isEmpty {
            addInfoRow(icon: "building.2.fill", title: "Publisher", value: detail.publishers.joined(separator: ", "))
        }

        if detail.playtime > 0 {
            addInfoRow(icon: "clock.fill", title: "Rata-rata Waktu Main", value: "\(detail.playtime) jam")
        }

        if let esrb = detail.esrbRating {
            addInfoRow(icon: "shield.fill", title: "Rating ESRB", value: esrb)
        }

        if let website = detail.website, !website.isEmpty {
            addInfoRow(icon: "globe", title: "Website", value: website)
        }
    }

    private func addInfoRow(icon: String, title: String, value: String) {
        let row = InfoRowView(icon: icon, title: title, value: value)
        infoStackView.addArrangedSubview(row)
    }

    private func refreshFavoriteButton(isFavorite: Bool) {
        favoriteButton.image = UIImage(systemName: isFavorite ? "heart.fill" : "heart")
        favoriteButton.tintColor = isFavorite ? .systemRed : .systemBlue
        favoriteButton.isEnabled = isFavorite || viewModel.detail != nil
        favoriteButton.accessibilityLabel = isFavorite ? "Hapus dari favorit" : "Tambah ke favorit"
    }

    @objc private func favoriteTapped() {
        viewModel.toggleFavorite()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

public enum DetailFeatureFactory {
    public static func make(gameId: Int, useCase: DetailUseCaseProtocol) -> UIViewController {
        DetailViewController(viewModel: DetailViewModel(gameId: gameId, useCase: useCase))
    }
}

// MARK: - UICollectionViewDataSource
extension DetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.detail?.genres.count ?? 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: GenreChipCell.identifier, for: indexPath
        ) as? GenreChipCell else {
            return UICollectionViewCell()
        }
        let genre = viewModel.detail?.genres[indexPath.item] ?? ""
        cell.configure(with: genre)
        return cell
    }
}
