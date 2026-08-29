import Combine
import Foundation
import GameCatalogDomain

public enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case transport(Error)
    case decoding(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL tidak valid."
        case .invalidResponse:
            return "Respons server tidak lengkap."
        case .serverError(let code):
            return "Server mengembalikan kode \(code)."
        case .transport(let error), .decoding(let error):
            return error.localizedDescription
        }
    }
}

struct GamesResponse: Decodable {
    let next: String?
    let results: [GameResponse]?
}

struct GameResponse: Decodable {
    let id: Int?
    let name: String?
    let released: String?
    let backgroundImage: String?
    let rating: Double?
    let ratingsCount: Int?
    let playtime: Int?
    let genres: [NamedResponse]?
    let platforms: [PlatformResponse]?

    enum CodingKeys: String, CodingKey {
        case id, name, released, rating, genres, platforms, playtime
        case backgroundImage = "background_image"
        case ratingsCount = "ratings_count"
    }

    func toDomain() -> Game? {
        guard let id else { return nil }
        return Game(
            id: id,
            name: name ?? "Tidak diketahui",
            released: released,
            backgroundImage: backgroundImage,
            rating: rating ?? 0,
            ratingsCount: ratingsCount ?? 0,
            playtime: playtime ?? 0,
            genres: genres?.compactMap(\.name) ?? [],
            platforms: platforms?.compactMap { $0.platform?.name } ?? []
        )
    }
}

struct GameDetailResponse: Decodable {
    let id: Int?
    let name: String?
    let released: String?
    let backgroundImage: String?
    let rating: Double?
    let ratingsCount: Int?
    let playtime: Int?
    let descriptionRaw: String?
    let genres: [NamedResponse]?
    let platforms: [PlatformResponse]?
    let developers: [NamedResponse]?
    let publishers: [NamedResponse]?
    let website: String?
    let esrbRating: NamedResponse?

    enum CodingKeys: String, CodingKey {
        case id, name, released, rating, genres, platforms, developers, publishers, website, playtime
        case backgroundImage = "background_image"
        case ratingsCount = "ratings_count"
        case descriptionRaw = "description_raw"
        case esrbRating = "esrb_rating"
    }

    func toDomain() throws -> GameDetail {
        guard let id else { throw NetworkError.invalidResponse }
        return GameDetail(
            id: id,
            name: name ?? "Tidak diketahui",
            released: released,
            backgroundImage: backgroundImage,
            rating: rating ?? 0,
            ratingsCount: ratingsCount ?? 0,
            playtime: playtime ?? 0,
            description: descriptionRaw ?? "Tidak ada deskripsi.",
            genres: genres?.compactMap(\.name) ?? [],
            platforms: platforms?.compactMap { $0.platform?.name } ?? [],
            developers: developers?.compactMap(\.name) ?? [],
            publishers: publishers?.compactMap(\.name) ?? [],
            website: website,
            esrbRating: esrbRating?.name
        )
    }
}

struct NamedResponse: Decodable {
    let name: String?
}

struct PlatformResponse: Decodable {
    let platform: NamedResponse?
}

protocol GameRemoteDataSourceProtocol {
    func games(page: Int, pageSize: Int) -> AnyPublisher<GamesResponse, Error>
    func search(query: String) -> AnyPublisher<GamesResponse, Error>
    func detail(id: Int) -> AnyPublisher<GameDetailResponse, Error>
}

public final class GameRemoteDataSource: GameRemoteDataSourceProtocol {
    private let session: URLSession
    private let baseURL: URL
    private let apiKey: String

    public init(
        session: URLSession = .shared,
        baseURL: URL = URL(string: "https://api.rawg.io/api")!,
        apiKey: String
    ) {
        self.session = session
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    func games(page: Int, pageSize: Int) -> AnyPublisher<GamesResponse, Error> {
        request(
            path: "games",
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "page_size", value: String(pageSize))
            ]
        )
    }

    func search(query: String) -> AnyPublisher<GamesResponse, Error> {
        request(
            path: "games",
            queryItems: [
                URLQueryItem(name: "search", value: query),
                URLQueryItem(name: "page_size", value: "20")
            ]
        )
    }

    func detail(id: Int) -> AnyPublisher<GameDetailResponse, Error> {
        request(path: "games/\(id)", queryItems: [])
    }

    private func request<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem]
    ) -> AnyPublisher<T, Error> {
        let endpoint = baseURL.appendingPathComponent(path)
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            return Fail(error: NetworkError.invalidURL as Error).eraseToAnyPublisher()
        }
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)] + queryItems
        guard let url = components.url else {
            return Fail(error: NetworkError.invalidURL as Error).eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: url)
            .mapError { NetworkError.transport($0) as Error }
            .tryMap { output in
                guard let response = output.response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                guard (200...299).contains(response.statusCode) else {
                    throw NetworkError.serverError(response.statusCode)
                }
                return output.data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error -> Error in
                if let networkError = error as? NetworkError { return networkError }
                return NetworkError.decoding(error)
            }
            .eraseToAnyPublisher()
    }
}
