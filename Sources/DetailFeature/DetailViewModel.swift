import Combine
import Foundation
import GameCatalogDomain

final class DetailViewModel {
    @Published private(set) var detail: GameDetail?
    @Published private(set) var isFavorite = false
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    let gameId: Int
    private let useCase: DetailUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    init(gameId: Int, useCase: DetailUseCaseProtocol) {
        self.gameId = gameId
        self.useCase = useCase
    }

    func load() {
        isLoading = true
        errorMessage = nil
        Publishers.Zip(useCase.detail(id: gameId), useCase.isFavorite(id: gameId))
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] detail, favorite in
                    self?.detail = detail
                    self?.isFavorite = favorite
                }
            )
            .store(in: &cancellables)
    }

    func toggleFavorite() {
        guard let detail else { return }
        let operation = isFavorite
            ? useCase.removeFavorite(id: gameId)
            : useCase.addFavorite(detail.game)

        operation
            .flatMap { [useCase, gameId] in useCase.isFavorite(id: gameId) }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] in self?.isFavorite = $0 }
            )
            .store(in: &cancellables)
    }
}
