import Combine
import Foundation
import GameCatalogDomain

public final class GameRepository: GameRepositoryProtocol {
    private let remote: GameRemoteDataSourceProtocol
    private let local: FavoriteLocalDataSourceProtocol

    public init(remote: GameRemoteDataSource, local: FavoriteLocalDataSource) {
        self.remote = remote
        self.local = local
    }

    public func games(page: Int, pageSize: Int) -> AnyPublisher<GamePage, Error> {
        remote.games(page: page, pageSize: pageSize)
            .map { response in
                GamePage(
                    games: response.results?.compactMap { $0.toDomain() } ?? [],
                    hasNextPage: response.next != nil
                )
            }
            .eraseToAnyPublisher()
    }

    public func search(query: String) -> AnyPublisher<[Game], Error> {
        remote.search(query: query)
            .map { $0.results?.compactMap { $0.toDomain() } ?? [] }
            .eraseToAnyPublisher()
    }

    public func detail(id: Int) -> AnyPublisher<GameDetail, Error> {
        remote.detail(id: id)
            .tryMap { try $0.toDomain() }
            .eraseToAnyPublisher()
    }

    public func favorites() -> AnyPublisher<[Game], Error> {
        local.favorites()
            .map { $0.map(\.game) }
            .eraseToAnyPublisher()
    }

    public func isFavorite(id: Int) -> AnyPublisher<Bool, Error> {
        local.isFavorite(id: id)
    }

    public func addFavorite(_ game: Game) -> AnyPublisher<Void, Error> {
        local.add(FavoriteGameEntity(game: game, addedAt: Date()))
    }

    public func removeFavorite(id: Int) -> AnyPublisher<Void, Error> {
        local.remove(id: id)
    }

    public var favoriteChanges: AnyPublisher<Void, Never> {
        local.changes
    }
}
