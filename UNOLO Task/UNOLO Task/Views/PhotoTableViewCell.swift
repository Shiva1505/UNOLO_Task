//
//  PhotoTableViewCell.swift
//  UNOLO Task
//
//  Created by Shiva Kaushik on 28/02/26.
//

import UIKit

final class PhotoTableViewCell: UITableViewCell {

    static let reuseIdentifier = "PhotoCell"

    // MARK: - UI

    private let photoImageView: UIImageView = {
        let photoView = UIImageView()
        photoView.translatesAutoresizingMaskIntoConstraints = false
        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        photoView.backgroundColor = .systemGray5
        photoView.layer.cornerRadius = 4
        return photoView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 2
        label.font = .preferredFont(forTextStyle: .body)
        return label
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        contentView.addSubview(photoImageView)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            photoImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            photoImageView.widthAnchor.constraint(equalToConstant: 60),
            photoImageView.heightAnchor.constraint(equalToConstant: 60),
            photoImageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8),
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: photoImageView.bottomAnchor, constant: 8),

            titleLabel.leadingAnchor.constraint(equalTo: photoImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8),
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor, constant: 8)
        ])
    }

    // MARK: - Configure

    private var currentThumbnailURL: String?

    func configure(title: String?, thumbnailURL: String?) {
        titleLabel.text = title ?? "—"
        photoImageView.image = nil
        currentThumbnailURL = thumbnailURL

        guard let url = thumbnailURL else { return }

        Task { @MainActor in
            let image = await ImageLoader.shared.loadImage(from: url)
            // Only set image if this cell wasn't reused for another URL
            if self.currentThumbnailURL == url {
                self.photoImageView.image = image
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentThumbnailURL = nil
        photoImageView.image = nil
        titleLabel.text = nil
    }
}
