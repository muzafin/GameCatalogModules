import Foundation

public struct Game: Identifiable, Equatable {
    public let id: Int
    public let name: String
    public let released: String?
    public let backgroundImage: String?
    public let rating: Double
    public let ratingsCount: Int
    public let playtime: Int
    public let genres: [String]
    public let platforms: [String]

    public init(
        id: Int,
        name: String,
        released: String?,
        backgroundImage: String?,
        rating: Double,
        ratingsCount: Int,
        playtime: Int,
        genres: [String],
        platforms: [String]
    ) {
        self.id = id
        self.name = name
        self.released = released
        self.backgroundImage = backgroundImage
        self.rating = rating
        self.ratingsCount = ratingsCount
        self.playtime = playtime
        self.genres = genres
        self.platforms = platforms
    }
}

public struct GamePage: Equatable {
    public let games: [Game]
    public let hasNextPage: Bool

    public init(games: [Game], hasNextPage: Bool) {
        self.games = games
        self.hasNextPage = hasNextPage
    }
}

public struct GameDetail: Equatable {
    public let id: Int
    public let name: String
    public let released: String?
    public let backgroundImage: String?
    public let rating: Double
    public let ratingsCount: Int
    public let playtime: Int
    public let description: String
    public let genres: [String]
    public let platforms: [String]
    public let developers: [String]
    public let publishers: [String]
    public let website: String?
    public let esrbRating: String?

    public init(
        id: Int,
        name: String,
        released: String?,
        backgroundImage: String?,
        rating: Double,
        ratingsCount: Int,
        playtime: Int,
        description: String,
        genres: [String],
        platforms: [String],
        developers: [String],
        publishers: [String],
        website: String?,
        esrbRating: String?
    ) {
        self.id = id
        self.name = name
        self.released = released
        self.backgroundImage = backgroundImage
        self.rating = rating
        self.ratingsCount = ratingsCount
        self.playtime = playtime
        self.description = description
        self.genres = genres
        self.platforms = platforms
        self.developers = developers
        self.publishers = publishers
        self.website = website
        self.esrbRating = esrbRating
    }

    public var game: Game {
        Game(
            id: id,
            name: name,
            released: released,
            backgroundImage: backgroundImage,
            rating: rating,
            ratingsCount: ratingsCount,
            playtime: playtime,
            genres: genres,
            platforms: platforms
        )
    }
}

public struct UserProfile: Equatable {
    public let name: String
    public let email: String
    public let role: String

    public init(name: String, email: String, role: String) {
        self.name = name
        self.email = email
        self.role = role
    }
}
