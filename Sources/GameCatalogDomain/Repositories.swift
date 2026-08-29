import Combine
import Foundation

public protocol GameRepositoryProtocol {
    func games(page: Int, pageSize: Int) -> AnyPublisher<GamePage, Error>
    func search(query: String) -> AnyPublisher<[Game], Error>
    func detail(id: Int) -> AnyPublisher<GameDetail, Error>
    func favorites() -> AnyPublisher<[Game], Error>
    func isFavorite(id: Int) -> AnyPublisher<Bool, Error>
    func addFavorite(_ game: Game) -> AnyPublisher<Void, Error>
    func removeFavorite(id: Int) -> AnyPublisher<Void, Error>
    var favoriteChanges: AnyPublisher<Void, Never> { get }
}

public protocol ProfileRepositoryProtocol {
    func load() -> UserProfile
    func save(_ profile: UserProfile)
}

public protocol UseCase {
    associatedtype Request
    associatedtype Response

    func execute(_ request: Request) -> AnyPublisher<Response, Error>
}
