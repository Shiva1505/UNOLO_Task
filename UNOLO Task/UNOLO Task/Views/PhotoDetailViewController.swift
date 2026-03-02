//
//  PhotoDetailViewController.swift
//  UNOLO Task
//
//  Created by Shiva Kaushik on 28/02/26.
//

import UIKit

final class PhotoDetailViewController: UIViewController {

    var viewModel: PhotoDetailViewModel?
    var onDismiss: ((_ wasDeleted: Bool) -> Void)?

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Edit Photo"
        view.backgroundColor = .systemBackground
        scrollView.keyboardDismissMode = .interactive
        bindViewModel()
        configure()
    }

    private func configure() {
        guard let viewModel = viewModel else { return }

        titleTextField.text = viewModel.currentTitle

        // ✅ IMPORTANT: Load FULL image URL
        if let fullURL = viewModel.imageURL {
            Task { @MainActor in
                let image = await ImageLoader.shared.loadImage(from: fullURL)
                photoImageView.image = image
            }
        }
    }

    private func bindViewModel() {
        viewModel?.onError = { [weak self] message in
            self?.showAlert(title: "Error", message: message)
        }

        viewModel?.onSaveSuccess = { [weak self] in
            self?.onDismiss?(false)
            self?.navigationController?.popViewController(animated: true)
        }

        viewModel?.onDeleteSuccess = { [weak self] in
            self?.onDismiss?(true)
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func saveBtnPressed(_ sender: Any) {
        viewModel?.saveTitle(titleTextField.text ?? "")
    }
    
    @IBAction func deleteBtnPressed(_ sender: Any) {
        let alert = UIAlertController(
            title: "Delete Photo",
            message: "Are you sure you want to delete this photo?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.viewModel?.deletePhoto()
        })
        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
