//
//  PhotoDetailViewModel.swift
//  UNOLO Task
//
//  Created by Shiva Kaushik on 28/02/26.
//

import Foundation
import CoreData

final class PhotoDetailViewModel {

    // MARK: - Dependencies

    private let coreDataManager: CoreDataManager
    private let photoEntity: PhotoEntity

    // MARK: - Callbacks

    var onSaveSuccess: (() -> Void)?
    var onDeleteSuccess: (() -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Display state

    var currentTitle: String? { photoEntity.title }
    var imageURL: String? { photoEntity.url }

    // MARK: - Init

    init(coreDataManager: CoreDataManager, photoEntity: PhotoEntity) {
        self.coreDataManager = coreDataManager
        self.photoEntity = photoEntity
    }

    // MARK: - Actions

    func saveTitle(_ newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onError?("Please enter a title.")
            return
        }
        do {
            try coreDataManager.updateTitle(for: photoEntity, newTitle: trimmed)
            onSaveSuccess?()
        } catch {
            onError?("Could not save: \(error.localizedDescription)")
        }
    }

    func deletePhoto() {
        do {
            try coreDataManager.delete(photoEntity)
            onDeleteSuccess?()
        } catch {
            onError?("Could not delete: \(error.localizedDescription)")
        }
    }
}
