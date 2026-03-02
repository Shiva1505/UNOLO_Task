//
//  PhotoItem.swift
//  UNOLO Task
//
//  Created by Shiva Kaushik on 28/02/26.
//

import Foundation
import CoreData

/// Display model for photo list/detail (MVVM View layer)
struct PhotoItem {
    let id: Int64
    let title: String?
    let thumbnailUrl: String?
    let url: String?
}

extension PhotoItem {
    init(entity: PhotoEntity) {
        self.id = entity.id
        self.title = entity.title
        self.thumbnailUrl = entity.thumbnailUrl
        self.url = entity.url
    }
}
