import Combine
import GameCatalogDomain
import UIKit

/// Shared list cell used by both Home and Favorite features.
/// Keeping it in Common prevents one feature module from depending on another.
public final class GameTableViewCell: UITableViewCell {
    public static let identifier = "GameTableViewCell"

    private var imageCancellable: AnyCancellable?
    private var representedImageURL: String?

    private let gameImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray5
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.numberOfLines = 2
        label.textColor = .label
        return label
    }()

    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let releaseDateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        accessoryType = .disclosureIndicator
        selectionStyle = .default

        let starImageView = UIImageView(image: UIImage(systemName: "star.fill"))
        starImageView.tintColor = .systemYellow
        starImageView.contentMode = .scaleAspectFit
        starImageView.widthAnchor.constraint(equalToConstant: 14).isActive = true
        starImageView.heightAnchor.constraint(equalToConstant: 14).isActive = true

        let ratingStackView = UIStackView(arrangedSubviews: [starImageView, ratingLabel])
        ratingStackView.axis = .horizontal
        ratingStackView.spacing = 4
        ratingStackView.alignment = .center

        let calendarImageView = UIImageView(image: UIImage(systemName: "calendar"))
        calendarImageView.tintColor = .systemBlue
        calendarImageView.contentMode = .scaleAspectFit
        calendarImageView.widthAnchor.constraint(equalToConstant: 14).isActive = true
        calendarImageView.heightAnchor.constraint(equalToConstant: 14).isActive = true

        let releaseDateStackView = UIStackView(arrangedSubviews: [calendarImageView, releaseDateLabel])
        releaseDateStackView.axis = .horizontal
        releaseDateStackView.spacing = 4
        releaseDateStackView.alignment = .center

        let infoStackView = UIStackView(arrangedSubviews: [titleLabel, ratingStackView, releaseDateStackView])
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.axis = .vertical
        infoStackView.spacing = 6
        infoStackView.alignment = .leading

        contentView.addSubviews(gameImageView, infoStackView)
        NSLayoutConstraint.activate([
            gameImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            gameImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            gameImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            gameImageView.widthAnchor.constraint(equalToConstant: 100),
            gameImageView.heightAnchor.constraint(equalToConstant: 75),
            infoStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            infoStackView.leadingAnchor.constraint(equalTo: gameImageView.trailingAnchor, constant: 12),
            infoStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            infoStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    public func configure(with game: Game) {
        titleLabel.text = game.name
        ratingLabel.text = game.rating.ratingString
        releaseDateLabel.text = game.released?.formattedDate() ?? "-"

        gameImageView.image = nil
        gameImageView.backgroundColor = .systemGray5
        gameImageView.startShimmering()
        imageCancellable?.cancel()
        representedImageURL = game.backgroundImage
        imageCancellable = ImageLoader.shared.image(from: game.backgroundImage).sink { [weak self] image in
            guard self?.representedImageURL == game.backgroundImage else { return }
            self?.gameImageView.stopShimmering()
            if let image {
                self?.gameImageView.image = image
                self?.gameImageView.backgroundColor = .clear
            } else {
                self?.gameImageView.image = UIImage(systemName: "photo")
                self?.gameImageView.tintColor = .systemGray3
            }
        }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        imageCancellable?.cancel()
        representedImageURL = nil
        gameImageView.image = nil
        gameImageView.stopShimmering()
        titleLabel.text = nil
        ratingLabel.text = nil
        releaseDateLabel.text = nil
    }
}
