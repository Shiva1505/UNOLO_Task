//
//  PhotoListViewModel.swift
//  UNOLO Task
//
//  Created by Shiva Kaushik on 28/02/26.
//
import Foundation
import CoreData

@MainActor
final class PhotoListViewModel {

    private enum Constants {
        static let batchSize = 20
    }

    // MARK: - Dependencies

    private let coreDataManager: CoreDataManager
    private let apiService: PhotoAPIService

    // MARK: - State

    private(set) var items: [PhotoItem] = []
    private var entities: [PhotoEntity] = []
    private var loadedCount = 0
    private var totalCount = 0
    private var isLoadingMore = false
    private var isFetchingFromAPI = false

    // MARK: - Callbacks (View binding)

    var onPhotosAppended: (([Int]) -> Void)?
    var onPhotosReloaded: (() -> Void)?
    var onRowRemoved: ((Int) -> Void)?
    var onRowUpdated: ((Int) -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?
    var onEmptyStateChanged: ((Bool) -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Init

    init(coreDataManager: CoreDataManager, apiService: PhotoAPIService = PhotoAPIService(batchSize: Constants.batchSize)) {
        self.coreDataManager = coreDataManager
        self.apiService = apiService
    }

    // MARK: - Public API

    var numberOfItems: Int { items.count }
    var hasMore: Bool { loadedCount < totalCount }
    var isLoading: Bool { isFetchingFromAPI }

    func item(at index: Int) -> PhotoItem? {
        guard index >= 0, index < items.count else { return nil }
        return items[index]
    }

    func entity(at index: Int) -> PhotoEntity? {
        guard index >= 0, index < entities.count else { return nil }
        return entities[index]
    }

    func loadInitial() {
        do {
            totalCount = try coreDataManager.fetchPhotoCount()
            if totalCount > 0 {
                loadNextBatch()
            } else {
                fetchFromAPI()
            }
        } catch {
            onError?("Failed to load photos: \(error.localizedDescription)")
            onEmptyStateChanged?(true)
        }
    }

    func loadMore() {
        loadNextBatch()
    }

    func refresh() {
        guard !isFetchingFromAPI else { return }
        fetchFromAPI()
    }

    func deletePhoto(at index: Int, completion: @MainActor () -> Void) {
        guard index >= 0, index < entities.count else { return }
        let entity = entities[index]
        do {
            try coreDataManager.delete(entity)
            entities.remove(at: index)
            items.remove(at: index)
            loadedCount = items.count
            totalCount = max(0, totalCount - 1)
            onRowRemoved?(index)
            if items.isEmpty {
                onEmptyStateChanged?(true)
            }
            completion()
        } catch {
            onError?("Could not delete: \(error.localizedDescription)")
        }
    }
    func handleDetailUpdate(wasDeleted: Bool, at index: Int) {
        if wasDeleted, index >= 0, index < entities.count {
            entities.remove(at: index)
            items.remove(at: index)
            loadedCount = items.count
            totalCount = max(0, totalCount - 1)
            onRowRemoved?(index)
            if items.isEmpty { onEmptyStateChanged?(true) }
        } else if index >= 0, index < entities.count {
            items[index] = PhotoItem(entity: entities[index])
            onRowUpdated?(index)
        }
    }

    // MARK: - Private

    private func loadNextBatch() {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        do {
            let batch = try coreDataManager.fetchPhotos(limit: Constants.batchSize, offset: loadedCount)
            if batch.isEmpty {
                if items.isEmpty {
                    onEmptyStateChanged?(true)
                }
                isLoadingMore = false
                return
            }
            let newItems = batch.map { PhotoItem(entity: $0) }
            let startIndex = items.count
            items.append(contentsOf: newItems)
            entities.append(contentsOf: batch)
            loadedCount = items.count
            onPhotosAppended?((startIndex..<items.count).map { $0 })
            onEmptyStateChanged?(false)
        } catch {
            onError?("Failed to load more: \(error.localizedDescription)")
        }
        isLoadingMore = false
    }

    private func fetchFromAPI() {
        guard !isFetchingFromAPI else { return }
        isFetchingFromAPI = true
        onLoadingChanged?(true)

        Task {
            do {
                try await apiService.fetchAllPhotosInBatches { [weak self] batch in
                    await MainActor.run {
                        self?.coreDataManager.upsertPhotos(batch)
                    }
                }
                await MainActor.run {
                    self.reloadFromCoreData()
                }
            } catch {
                await MainActor.run {
                    self.onError?("Could not refresh: \(error.localizedDescription)")
                }
            }
            await MainActor.run {
                self.isFetchingFromAPI = false
                self.onLoadingChanged?(false)
            }
        }
    }

    private func reloadFromCoreData() {
        do {
            totalCount = try coreDataManager.fetchPhotoCount()
            loadedCount = 0
            items = []
            entities = []
            onPhotosReloaded?()
            if totalCount == 0 {
                onEmptyStateChanged?(true)
                return
            }
            loadNextBatch()
        } catch {
            onError?("Failed to load: \(error.localizedDescription)")
        }
    }
}
