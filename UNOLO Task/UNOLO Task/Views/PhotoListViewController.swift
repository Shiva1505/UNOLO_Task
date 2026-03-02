//
//  PhotoListViewController.swift
//  UNOLO Task
//
//  Created by Shiva Kaushik on 28/02/26.
//

import UIKit
import CoreData

final class PhotoListViewController: UIViewController {

    // MARK: - ViewModel & Dependencies

    private var viewModel: PhotoListViewModel!
    private var coreDataManager: CoreDataManager!
    private var lastSelectedIndex: Int?

    // MARK: - UI

    @IBOutlet private weak var tableView: UITableView!
    private var refreshControl = UIRefreshControl()
    private let loadingOverlay: UIView = {
        let loadView = UIView()
        loadView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        loadView.translatesAutoresizingMaskIntoConstraints = false
        loadView.isHidden = true
        return loadView
    }()
    private let activityIndicator: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .large)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.color = .white
        return indicatorView
    }()
    private let emptyStateView: UIView = {
        let emptyView = UIView()
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.isHidden = true
        return emptyView
    }()
    private let emptyStateLabel: UILabel = {
        let emptyLbl = UILabel()
        emptyLbl.translatesAutoresizingMaskIntoConstraints = false
        emptyLbl.text = "No photos yet.\nPull down to fetch from the server."
        emptyLbl.numberOfLines = 0
        emptyLbl.textAlignment = .center
        emptyLbl.font = .preferredFont(forTextStyle: .body)
        emptyLbl.textColor = .secondaryLabel
        return emptyLbl
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Photos"
        setupViewModel()
        setupTableView()
        setupLoadingIndicator()
        setupEmptyState()
        bindViewModel()
        viewModel.loadInitial()
    }

    private func setupViewModel() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("AppDelegate unavailable")
        }
        coreDataManager = CoreDataManager(persistentContainer: appDelegate.persistentContainer)
        viewModel = PhotoListViewModel(coreDataManager: coreDataManager)
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.register(PhotoTableViewCell.self, forCellReuseIdentifier: PhotoTableViewCell.reuseIdentifier)
        refreshControl.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    private func setupLoadingIndicator() {
        view.addSubview(loadingOverlay)
        loadingOverlay.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor)
        ])
    }

    private func setupEmptyState() {
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyStateLabel)
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor)
        ])
    }

    private func bindViewModel() {
        viewModel.onPhotosAppended = { [weak self] indices in
            guard let self = self else { return }
            self.appendRowsSafely(indices: indices)
        }
        viewModel.onPhotosReloaded = { [weak self] in
            self?.tableView.reloadData()
        }
        viewModel.onRowRemoved = { [weak self] index in
            self?.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }
        viewModel.onRowUpdated = { [weak self] index in
            self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
        viewModel.onLoadingChanged = { [weak self] visible in
            self?.loadingOverlay.isHidden = !visible
            if visible {
                self?.activityIndicator.startAnimating()
            } else {
                self?.activityIndicator.stopAnimating()
                self?.refreshControl.endRefreshing()
            }
        }
        viewModel.onEmptyStateChanged = { [weak self] show in
            self?.emptyStateView.isHidden = !show
        }
        viewModel.onError = { [weak self] message in
            self?.showAlert(title: "Error", message: message)
        }
    }

    private func appendRowsSafely(indices: [Int]) {
        guard !indices.isEmpty else { return }

        let section = 0
        let currentRows = tableView.numberOfRows(inSection: section)
        let expectedStart = indices.first ?? 0

        // Keep table/list state in sync even if callbacks arrive while UI is mid-update.
        guard currentRows == expectedStart else {
            tableView.reloadData()
            return
        }

        let indexPaths = indices.map { IndexPath(row: $0, section: section) }
        tableView.performBatchUpdates({
            tableView.insertRows(at: indexPaths, with: .automatic)
        })
    }

    @objc private func refreshPulled() {
        viewModel.refresh()
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let index = (sender as? IndexPath)?.row
        if let detail = segue.destination as? PhotoDetailViewController,
           let index = index,
           let entity = viewModel.entity(at: index) {
            lastSelectedIndex = index
            detail.viewModel = PhotoDetailViewModel(coreDataManager: coreDataManager, photoEntity: entity)
            detail.onDismiss = { [weak self] wasDeleted in
                guard let self = self, let idx = self.lastSelectedIndex else { return }
                self.viewModel.handleDetailUpdate(wasDeleted: wasDeleted, at: idx)
                self.lastSelectedIndex = nil
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension PhotoListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfItems
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PhotoTableViewCell.reuseIdentifier, for: indexPath) as! PhotoTableViewCell
        if let item = viewModel.item(at: indexPath.row) {
            cell.configure(title: item.title, thumbnailURL: item.thumbnailUrl)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension PhotoListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "ShowPhotoDetail", sender: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row >= viewModel.numberOfItems - 1, viewModel.hasMore {
            viewModel.loadMore()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.frame.height

        // Trigger a little before the bottom so loading is seamless.
        let threshold: CGFloat = 120
        if offsetY > contentHeight - visibleHeight - threshold, viewModel.hasMore {
            viewModel.loadMore()
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let alert = UIAlertController(
            title: "Delete Photo",
            message: "Are you sure you want to delete this photo?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.viewModel.deletePhoto(at: indexPath.row) {
                self?.tableView.reloadData()
            }
        })
        present(alert, animated: true)
    }
}
