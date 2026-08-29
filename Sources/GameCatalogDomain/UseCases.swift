import Combine
import Foundation

public protocol HomeUseCaseProtocol {
    func games(page: Int) -> AnyPublisher<GamePage, Error>
    func search(query: String) -> AnyPublisher<[Game], Error>
}

public final class HomeInteractor: HomeUseCaseProtocol {
    private let repository: GameRepositoryProtocol

    public init(repository: GameRepositoryProtocol) {
        self.repository = repository
    }

    public func games(page: Int) -> AnyPublisher<GamePage, Error> {
        repository.games(page: page, pageSize: 20)
    }

    public func search(query: String) -> AnyPublisher<[Game], Error> {
        repository.search(query: query)
    }
}

public protocol DetailUseCaseProtocol {
    func detail(id: Int) -> AnyPublisher<GameDetail, Error>
    func isFavorite(id: Int) -> AnyPublisher<Bool, Error>
    func addFavorite(_ game: Game) -> AnyPublisher<Void, Error>
    func removeFavorite(id: Int) -> AnyPublisher<Void, Error>
}

public final class DetailInteractor: DetailUseCaseProtocol {
    private let repository: GameRepositoryProtocol
    private let getDetail: GetGameDetailUseCase

    public init(repository: GameRepositoryProtocol) {
        self.repository = repository
        getDetail = GetGameDetailUseCase(repository: repository)
    }

    public func detail(id: Int) -> AnyPublisher<GameDetail, Error> {
        getDetail.execute(id)
    }

    public func isFavorite(id: Int) -> AnyPublisher<Bool, Error> {
        repository.isFavorite(id: id)
    }

    public func addFavorite(_ game: Game) -> AnyPublisher<Void, Error> {
        repository.addFavorite(game)
    }

    public func removeFavorite(id: Int) -> AnyPublisher<Void, Error> {
        repository.removeFavorite(id: id)
    }
}

public protocol FavoriteUseCaseProtocol {
    func favorites() -> AnyPublisher<[Game], Error>
    func remove(id: Int) -> AnyPublisher<Void, Error>
    var changes: AnyPublisher<Void, Never> { get }
}

public final class FavoriteInteractor: FavoriteUseCaseProtocol {
    private let repository: GameRepositoryProtocol

    public init(repository: GameRepositoryProtocol) {
        self.repository = repository
    }

    public func favorites() -> AnyPublisher<[Game], Error> {
        repository.favorites()
    }

    public func remove(id: Int) -> AnyPublisher<Void, Error> {
        repository.removeFavorite(id: id)
    }

    public var changes: AnyPublisher<Void, Never> {
        repository.favoriteChanges
    }
}

public protocol ProfileUseCaseProtocol {
    func load() -> UserProfile
    func save(_ profile: UserProfile)
}

public final class ProfileInteractor: ProfileUseCaseProtocol {
    private let repository: ProfileRepositoryProtocol

    public init(repository: ProfileRepositoryProtocol) {
        self.repository = repository
    }

    public func load() -> UserProfile {
        repository.load()
    }

    public func save(_ profile: UserProfile) {
        repository.save(profile)
    }
}

public struct GetGameDetailUseCase: UseCase {
    public typealias Request = Int
    public typealias Response = GameDetail

    private let repository: GameRepositoryProtocol

    public init(repository: GameRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ request: Int) -> AnyPublisher<GameDetail, Error> {
        repository.detail(id: request)
    }
}
