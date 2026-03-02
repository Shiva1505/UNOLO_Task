//
//  CoreDataManager.swift
//  UNOLO Task
//
//  Created by Shiva Kaushik on 28/02/26.
//

import Foundation
import CoreData

enum CoreDataError: Error {
    case saveFailed(Error)
    case fetchFailed(Error)
}

final class CoreDataManager {

    private let persistentContainer: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }

    // MARK: - Fetch (with pagination)

    func fetchPhotoCount() throws -> Int {
        let request = PhotoEntity.fetchRequest()
        return try viewContext.count(for: request)
    }
    func fetchPhotos(limit: Int, offset: Int = 0) throws -> [PhotoEntity] {
        let request = PhotoEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PhotoEntity.id, ascending: true)]
        request.fetchLimit = limit
        request.fetchOffset = offset
        return try viewContext.fetch(request)
    }

    func fetchAllPhotos() throws -> [PhotoEntity] {
        let request = PhotoEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PhotoEntity.id, ascending: true)]
        return try viewContext.fetch(request)
    }

    // MARK: - Save / Upsert (no duplicates)
    func upsertPhotos(_ photos: [Photo]) {
        let context = viewContext
        for photo in photos {
            if let existing = try? fetchPhoto(by: Int64(photo.id)) {
                existing.albumId = Int64(photo.albumId)
                existing.title = photo.title
                existing.url = photo.url
                existing.thumbnailUrl = photo.thumbnailUrl
            } else {
                let entity = PhotoEntity(context: context)
                entity.id = Int64(photo.id)
                entity.albumId = Int64(photo.albumId)
                entity.title = photo.title
                entity.url = photo.url
                entity.thumbnailUrl = photo.thumbnailUrl
            }
        }
        saveContext(context)
    }

    private func fetchPhoto(by id: Int64) throws -> PhotoEntity? {
        let request = PhotoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %lld", id)
        request.fetchLimit = 1
        return try viewContext.fetch(request).first
    }

    // MARK: - Update title

    func updateTitle(for photoEntity: PhotoEntity, newTitle: String) throws {
        photoEntity.title = newTitle
        try saveContextAndThrow(viewContext)
    }

    // MARK: - Delete

    func delete(_ photoEntity: PhotoEntity) throws {
        viewContext.delete(photoEntity)
        try saveContextAndThrow(viewContext)
    }

    func deleteAllPhotos() throws {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "PhotoEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: viewContext)
        viewContext.reset()
    }

    // MARK: - Helpers

    private func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Core Data save error: \(error)")
            }
        }
    }

    private func saveContextAndThrow(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
}
