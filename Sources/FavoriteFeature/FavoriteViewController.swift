import Combine
import Common
import GameCatalogDomain
import UIKit

final class FavoriteViewController: UIViewController {
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(GameTableViewCell.self, forCellReuseIdentifier: GameTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        return tableView
    }()

    private let emptyStackView: UIStackView = {
        let imageView = UIImageView(image: UIImage(systemName: "heart.slash"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .tertiaryLabel
        imageView.heightAnchor.constraint(equalToConstant: 64).isActive = true
        let title = UILabel()
        title.text = L10n.text("favorite.empty.title")
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        title.textAlignment = .center
        let message = UILabel()
        message.text = L10n.text("favorite.empty.message")
        message.textColor = .secondaryLabel
        message.textAlignment = .center
        message.numberOfLines = 0
        let stack = UIStackView(arrangedSubviews: [imageView, title, message])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    private let errorView: ErrorView = {
        let view = ErrorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let viewModel: FavoriteViewModel
    private let detailFactory: (Int) -> UIViewController
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: FavoriteViewModel, detailFactory: @escaping (Int) -> UIViewController) {
        self.viewModel = viewModel
        self.detailFactory = detailFactory
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.load()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = L10n.text("favorite.title")
        navigationController?.navigationBar.prefersLargeTitles = true
        view.addSubviews(tableView, emptyStackView, errorView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            errorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        errorView.retryAction = { [weak viewModel = viewModel] in viewModel?.load() }
    }

    private func bindViewModel() {
        viewModel.$favorites
            .receive(on: DispatchQueue.main)
            .sink { [weak self] favorites in
                self?.tableView.reloadData()
                self?.tableView.isHidden = favorites.isEmpty
                self?.emptyStackView.isHidden = !favorites.isEmpty
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
}

public enum FavoriteFeatureFactory {
    public static func make(
        useCase: FavoriteUseCaseProtocol,
        detailFactory: @escaping (Int) -> UIViewController
    ) -> UIViewController {
        FavoriteViewController(
            viewModel: FavoriteViewModel(useCase: useCase),
            detailFactory: detailFactory
        )
    }
}

extension FavoriteViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.favorites.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: GameTableViewCell.identifier,
            for: indexPath
        ) as? GameTableViewCell else { return UITableViewCell() }
        cell.configure(with: viewModel.favorites[indexPath.row])
        return cell
    }
}

extension FavoriteViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(
            detailFactory(viewModel.favorites[indexPath.row].id),
            animated: true
        )
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let game = viewModel.favorites[indexPath.row]
        let action = UIContextualAction(style: .destructive, title: "Hapus") { [weak viewModel = viewModel] _, _, done in
            viewModel?.remove(id: game.id)
            done(true)
        }
        action.image = UIImage(systemName: "heart.slash.fill")
        return UISwipeActionsConfiguration(actions: [action])
    }
}
