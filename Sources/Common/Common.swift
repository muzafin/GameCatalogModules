import Combine
import Foundation
import GameCatalogDomain
import UIKit

public enum L10n {
    public static func text(_ key: String) -> String {
        NSLocalizedString(key, bundle: .module, comment: "")
    }
}

public extension UIView {
    func addSubviews(_ views: UIView...) {
        views.forEach(addSubview)
    }

    func startShimmering() {
        stopShimmering()
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.systemGray4.cgColor, UIColor.systemGray5.cgColor, UIColor.systemGray4.cgColor]
        gradient.frame = CGRect(
            x: -bounds.width,
            y: 0,
            width: 3 * bounds.width,
            height: bounds.height
        )
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.locations = [0, 0.5, 1]
        gradient.name = "shimmerLayer"
        layer.addSublayer(gradient)

        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = -bounds.width
        animation.toValue = bounds.width
        animation.duration = 1.2
        animation.repeatCount = .infinity
        gradient.add(animation, forKey: "shimmer")
    }

    func stopShimmering() {
        layer.sublayers?
            .filter { $0.name == "shimmerLayer" }
            .forEach { $0.removeFromSuperlayer() }
    }
}

public extension String {
    func formattedDate() -> String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        input.locale = Locale(identifier: "en_US_POSIX")
        guard let date = input.date(from: self) else { return self }
        let output = DateFormatter()
        output.dateFormat = "d MMM yyyy"
        output.locale = Locale.current
        return output.string(from: date)
    }
}

public extension Double {
    var ratingString: String { String(format: "%.1f", self) }
}

public final class ImageLoader {
    public static let shared = ImageLoader()

    private let cache = NSCache<NSString, UIImage>()
    private let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
    }

    public func image(from urlString: String?) -> AnyPublisher<UIImage?, Never> {
        guard
            let urlString,
            !urlString.isEmpty,
            let url = URL(string: urlString)
        else {
            return Just(nil).eraseToAnyPublisher()
        }
        if let cached = cache.object(forKey: urlString as NSString) {
            return Just(cached).eraseToAnyPublisher()
        }
        return session.dataTaskPublisher(for: url)
            .map { [weak self] output -> UIImage? in
                guard let image = UIImage(data: output.data) else { return nil }
                self?.cache.setObject(image, forKey: urlString as NSString)
                return image
            }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

public final class ErrorView: UIView {
    public var retryAction: (() -> Void)?

    private let messageLabel = UILabel()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground

        let icon = UIImageView(image: UIImage(systemName: "wifi.slash"))
        icon.tintColor = .systemGray3
        icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 60).isActive = true

        let title = UILabel()
        title.text = L10n.text("error.title")
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        title.textAlignment = .center

        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        let button = UIButton(type: .system)
        button.setTitle(L10n.text("action.retry"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [icon, title, messageLabel, button])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32)
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(message: String) {
        messageLabel.text = message
    }

    @objc private func retryTapped() {
        retryAction?()
    }
}

public final class RatingView: UIView {
    private let ratingLabel = UILabel()
    private let countLabel = UILabel()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        let star = UIImageView(image: UIImage(systemName: "star.fill"))
        star.tintColor = .systemYellow
        star.widthAnchor.constraint(equalToConstant: 18).isActive = true
        star.heightAnchor.constraint(equalToConstant: 18).isActive = true
        ratingLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        countLabel.font = .systemFont(ofSize: 13)
        countLabel.textColor = .secondaryLabel
        let stack = UIStackView(arrangedSubviews: [star, ratingLabel, countLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = 4
        stack.alignment = .center
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(rating: Double, count: Int) {
        ratingLabel.text = rating.ratingString
        countLabel.text = "(\(count) \(L10n.text("rating.reviews")))"
    }
}

public final class InfoRowView: UIView {
    public init(icon: String, title: String, value: String) {
        super.init(frame: .zero)
        let image = UIImageView(image: UIImage(systemName: icon))
        image.tintColor = .systemBlue
        image.widthAnchor.constraint(equalToConstant: 20).isActive = true
        image.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = .secondaryLabel
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.numberOfLines = 0

        let labels = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        labels.axis = .vertical
        labels.spacing = 2
        let row = UIStackView(arrangedSubviews: [image, labels])
        row.translatesAutoresizingMaskIntoConstraints = false
        row.spacing = 12
        row.alignment = .top
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class GenreChipCell: UICollectionViewCell {
    public static let identifier = "GenreChipCell"
    private let label = UILabel()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        contentView.layer.cornerRadius = 12
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemBlue
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(with genre: String) {
        label.text = genre
    }
}
