import Combine
import CoreData
import Foundation
import GameCatalogDomain

public enum DatabaseError: LocalizedError {
    case persistentStore(Error)
    case fetch(Error)
    case save(Error)

    public var errorDescription: String? {
        switch self {
        case .persistentStore:
            return "Penyimpanan favorit tidak dapat dibuka."
        case .fetch:
            return "Daftar favorit tidak dapat dimuat."
        case .save:
            return "Perubahan favorit tidak dapat disimpan."
        }
    }
}

struct FavoriteGameEntity {
    let game: Game
    let addedAt: Date
}

protocol FavoriteLocalDataSourceProtocol {
    func favorites() -> AnyPublisher<[FavoriteGameEntity], Error>
    func isFavorite(id: Int) -> AnyPublisher<Bool, Error>
    func add(_ entity: FavoriteGameEntity) -> AnyPublisher<Void, Error>
    func remove(id: Int) -> AnyPublisher<Void, Error>
    var changes: AnyPublisher<Void, Never> { get }
}

public final class FavoriteLocalDataSource: FavoriteLocalDataSourceProtocol {
    private enum Field {
        static let entity = "FavoriteGameEntity"
        static let id = "id"
        static let name = "name"
        static let released = "released"
        static let backgroundImage = "backgroundImage"
        static let rating = "rating"
        static let addedAt = "addedAt"
    }

    private let container: NSPersistentContainer
    private let changesSubject = PassthroughSubject<Void, Never>()
    private var loadingError: DatabaseError?

    public init(inMemory: Bool = false) {
        container = NSPersistentContainer(
            name: "GameCatalog",
            managedObjectModel: Self.makeManagedObjectModel()
        )
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { [weak self] _, error in
            if let error { self?.loadingError = .persistentStore(error) }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var changes: AnyPublisher<Void, Never> {
        changesSubject.eraseToAnyPublisher()
    }

    func favorites() -> AnyPublisher<[FavoriteGameEntity], Error> {
        deferred { [weak self] in
            guard let self else { return [] }
            if let loadingError { throw loadingError }
            let request = NSFetchRequest<NSManagedObject>(entityName: Field.entity)
            request.sortDescriptors = [NSSortDescriptor(key: Field.addedAt, ascending: false)]
            do {
                return try container.viewContext.fetch(request).compactMap(Self.makeEntity(from:))
            } catch {
                throw DatabaseError.fetch(error)
            }
        }
    }

    func isFavorite(id: Int) -> AnyPublisher<Bool, Error> {
        deferred { [weak self] in
            guard let self else { return false }
            if let loadingError { throw loadingError }
            return try fetchObject(id: id) != nil
        }
    }

    func add(_ entity: FavoriteGameEntity) -> AnyPublisher<Void, Error> {
        deferred { [weak self] in
            guard let self else { return }
            if let loadingError { throw loadingError }
            if try fetchObject(id: entity.game.id) != nil { return }
            guard let description = NSEntityDescription.entity(
                forEntityName: Field.entity,
                in: container.viewContext
            ) else {
                throw DatabaseError.save(NSError(domain: "FavoriteLocalDataSource", code: 1))
            }
            let object = NSManagedObject(entity: description, insertInto: container.viewContext)
            object.setValue(Int64(entity.game.id), forKey: Field.id)
            object.setValue(entity.game.name, forKey: Field.name)
            object.setValue(entity.game.released, forKey: Field.released)
            object.setValue(entity.game.backgroundImage, forKey: Field.backgroundImage)
            object.setValue(entity.game.rating, forKey: Field.rating)
            object.setValue(entity.addedAt, forKey: Field.addedAt)
            try saveChanges()
        }
    }

    func remove(id: Int) -> AnyPublisher<Void, Error> {
        deferred { [weak self] in
            guard let self else { return }
            if let loadingError { throw loadingError }
            guard let object = try fetchObject(id: id) else { return }
            container.viewContext.delete(object)
            try saveChanges()
        }
    }

    private func deferred<T>(_ work: @escaping () throws -> T) -> AnyPublisher<T, Error> {
        Deferred { Future<T, Error> { promise in
            do { promise(.success(try work())) }
            catch { promise(.failure(error)) }
        } }
        .eraseToAnyPublisher()
    }

    private func fetchObject(id: Int) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: Field.entity)
        request.predicate = NSPredicate(format: "%K == %lld", Field.id, Int64(id))
        request.fetchLimit = 1
        do { return try container.viewContext.fetch(request).first }
        catch { throw DatabaseError.fetch(error) }
    }

    private func saveChanges() throws {
        do {
            try container.viewContext.save()
            changesSubject.send(())
        } catch {
            container.viewContext.rollback()
            throw DatabaseError.save(error)
        }
    }

    private static func makeEntity(from object: NSManagedObject) -> FavoriteGameEntity? {
        guard
            let id = object.value(forKey: Field.id) as? NSNumber,
            let name = object.value(forKey: Field.name) as? String
        else { return nil }
        return FavoriteGameEntity(
            game: Game(
                id: id.intValue,
                name: name,
                released: object.value(forKey: Field.released) as? String,
                backgroundImage: object.value(forKey: Field.backgroundImage) as? String,
                rating: (object.value(forKey: Field.rating) as? NSNumber)?.doubleValue ?? 0,
                ratingsCount: 0,
                playtime: 0,
                genres: [],
                platforms: []
            ),
            addedAt: object.value(forKey: Field.addedAt) as? Date ?? Date()
        )
    }

    private static func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = Field.entity
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        entity.properties = [
            attribute(Field.id, .integer64AttributeType, false),
            attribute(Field.name, .stringAttributeType, false),
            attribute(Field.released, .stringAttributeType, true),
            attribute(Field.backgroundImage, .stringAttributeType, true),
            attribute(Field.rating, .doubleAttributeType, true),
            attribute(Field.addedAt, .dateAttributeType, false)
        ]
        entity.uniquenessConstraints = [[Field.id]]
        model.entities = [entity]
        return model
    }

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        _ optional: Bool
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }
}

public final class ProfileStore: ProfileRepositoryProtocol {
    private enum Key {
        static let name = "profile.name"
        static let email = "profile.email"
        static let role = "profile.role"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> UserProfile {
        UserProfile(
            name: defaults.string(forKey: Key.name) ?? "Muhammad Zaenal Arifin",
            email: defaults.string(forKey: Key.email) ?? "arifinmuzafin4@gmail.com",
            role: defaults.string(forKey: Key.role) ?? "iOS Developer"
        )
    }

    public func save(_ profile: UserProfile) {
        defaults.set(profile.name, forKey: Key.name)
        defaults.set(profile.email, forKey: Key.email)
        defaults.set(profile.role, forKey: Key.role)
    }
}
