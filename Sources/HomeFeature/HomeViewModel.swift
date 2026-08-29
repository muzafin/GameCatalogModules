import Combine
import Foundation
import GameCatalogDomain

final class HomeViewModel {
    @Published private(set) var games: [Game] = []
    @Published private(set) var searchResults: [Game] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var query = ""

    private let useCase: HomeUseCaseProtocol
    private let searchSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var requestCancellable: AnyCancellable?
    private var currentPage = 1
    private var hasNextPage = true

    init(useCase: HomeUseCaseProtocol) {
        self.useCase = useCase
        searchSubject
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] in self?.performSearch(query: $0) }
            .store(in: &cancellables)
    }

    var displayedGames: [Game] {
        query.isEmpty ? games : searchResults
    }

    var canLoadNextPage: Bool {
        query.isEmpty && hasNextPage && !isLoading
    }

    func loadGames(reset: Bool = false) {
        guard !isLoading && (hasNextPage || reset) else { return }
        if reset {
            currentPage = 1
            hasNextPage = true
            games = []
        }
        isLoading = true
        errorMessage = nil
        requestCancellable = useCase.games(page: currentPage)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] page in
                    guard let self else { return }
                    games.append(contentsOf: page.games)
                    hasNextPage = page.hasNextPage
                    currentPage += 1
                }
            )
    }

    func updateSearch(query: String) {
        self.query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = nil
        if self.query.isEmpty {
            requestCancellable?.cancel()
            searchResults = []
            isLoading = false
            if games.isEmpty { loadGames(reset: true) }
        } else {
            searchSubject.send(self.query)
        }
    }

    func retry() {
        if query.isEmpty {
            loadGames(reset: true)
        } else {
            performSearch(query: query)
        }
    }

    private func performSearch(query: String) {
        guard query == self.query else { return }
        isLoading = true
        errorMessage = nil
        requestCancellable?.cancel()
        requestCancellable = useCase.search(query: query)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] in self?.searchResults = $0 }
            )
    }
}
