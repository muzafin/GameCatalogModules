import Combine
import Foundation
import GameCatalogDomain

final class FavoriteViewModel {
    @Published private(set) var favorites: [Game] = []
    @Published private(set) var errorMessage: String?

    private let useCase: FavoriteUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    init(useCase: FavoriteUseCaseProtocol) {
        self.useCase = useCase
        useCase.changes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.load() }
            .store(in: &cancellables)
    }

    func load() {
        errorMessage = nil
        useCase.favorites()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] in self?.favorites = $0 }
            )
            .store(in: &cancellables)
    }

    func remove(id: Int) {
        useCase.remove(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
}
