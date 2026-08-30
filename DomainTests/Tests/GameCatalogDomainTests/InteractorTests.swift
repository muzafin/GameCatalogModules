import Combine
@testable import GameCatalogDomain
import XCTest

final class InteractorTests: XCTestCase {
    private var repository: MockGameRepository!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        repository = MockGameRepository()
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        repository = nil
        super.tearDown()
    }

    func testHomeInteractorRequestsFirstPageWithTwentyItems() {
        let sut = HomeInteractor(repository: repository)
        let expected = GamePage(games: [Game.fixture()], hasNextPage: true)
        repository.gamesResult = .success(expected)
        let expectation = expectation(description: "Games emitted")

        sut.games(page: 1)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { page in
                    XCTAssertEqual(page, expected)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(repository.requestedPage, 1)
        XCTAssertEqual(repository.requestedPageSize, 20)
    }

    func testHomeInteractorForwardsSearchKeyword() {
        let sut = HomeInteractor(repository: repository)
        repository.searchResult = .success([Game.fixture(name: "Zelda")])
        let expectation = expectation(description: "Search emitted")

        sut.search(query: "Zelda")
            .sink(receiveCompletion: { _ in }, receiveValue: { games in
                XCTAssertEqual(games.first?.name, "Zelda")
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(repository.requestedQuery, "Zelda")
    }

    func testDetailInteractorForwardsSelectedIdentifier() {
        let sut = DetailInteractor(repository: repository)
        repository.detailResult = .success(.fixture(id: 42))
        let expectation = expectation(description: "Detail emitted")

        sut.detail(id: 42)
            .sink(receiveCompletion: { _ in }, receiveValue: { detail in
                XCTAssertEqual(detail.id, 42)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(repository.requestedDetailId, 42)
    }

    func testFavoriteInteractorRemovesSelectedGame() {
        let sut = FavoriteInteractor(repository: repository)
        let expectation = expectation(description: "Remove completed")

        sut.remove(id: 7)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion { expectation.fulfill() }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(repository.removedId, 7)
    }

    func testGenericDetailUseCaseConformsAndReturnsDetail() {
        let sut = GetGameDetailUseCase(repository: repository)
        repository.detailResult = .success(.fixture(id: 99))
        let expectation = expectation(description: "Generic use case emitted")

        sut.execute(99)
            .sink(receiveCompletion: { _ in }, receiveValue: { detail in
                XCTAssertEqual(detail.id, 99)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }
}

private final class MockGameRepository: GameRepositoryProtocol {
    var gamesResult: Result<GamePage, Error> = .success(GamePage(games: [], hasNextPage: false))
    var searchResult: Result<[Game], Error> = .success([])
    var detailResult: Result<GameDetail, Error> = .success(.fixture())
    var requestedPage: Int?
    var requestedPageSize: Int?
    var requestedQuery: String?
    var requestedDetailId: Int?
    var removedId: Int?

    func games(page: Int, pageSize: Int) -> AnyPublisher<GamePage, Error> {
        requestedPage = page
        requestedPageSize = pageSize
        return gamesResult.publisher.eraseToAnyPublisher()
    }

    func search(query: String) -> AnyPublisher<[Game], Error> {
        requestedQuery = query
        return searchResult.publisher.eraseToAnyPublisher()
    }

    func detail(id: Int) -> AnyPublisher<GameDetail, Error> {
        requestedDetailId = id
        return detailResult.publisher.eraseToAnyPublisher()
    }

    func favorites() -> AnyPublisher<[Game], Error> {
        Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func isFavorite(id: Int) -> AnyPublisher<Bool, Error> {
        Just(false).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func addFavorite(_ game: Game) -> AnyPublisher<Void, Error> {
        Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func removeFavorite(id: Int) -> AnyPublisher<Void, Error> {
        removedId = id
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    var favoriteChanges: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }
}

private extension Game {
    static func fixture(id: Int = 1, name: String = "Game") -> Game {
        Game(
            id: id,
            name: name,
            released: "2026-01-01",
            backgroundImage: nil,
            rating: 4.5,
            ratingsCount: 100,
            playtime: 10,
            genres: ["Action"],
            platforms: ["iOS"]
        )
    }
}

private extension GameDetail {
    static func fixture(id: Int = 1) -> GameDetail {
        GameDetail(
            id: id,
            name: "Game",
            released: nil,
            backgroundImage: nil,
            rating: 4,
            ratingsCount: 1,
            playtime: 2,
            description: "Description",
            genres: [],
            platforms: [],
            developers: [],
            publishers: [],
            website: nil,
            esrbRating: nil
        )
    }
}

