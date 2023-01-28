//
//  MainScreen.swift
//  PopixelsMergeVideos
//
//  Created by Oren Cohen on 27/01/2023.
//

import UIKit
import AVFoundation
import PhotosUI
import Combine

class MainScreen: UIViewController, PHPickerViewControllerDelegate {
        
    @IBOutlet weak var videoPlayerView: VideoPlayerView!
    @IBOutlet weak var chooseVideosButton: UIButton!
    @IBOutlet weak var saveVideoButton: UIButton!
    
    let viewModel = MainScreenViewModel()
    
    private var subscriptions = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoPlayerView.viewModel = viewModel.videoPlayerViewModel
        setupObservations()
        setupUI()
    }

    @IBAction func chooseVideosTapped(_ sender: UIButton) {
        var config = PHPickerConfiguration()
        config.selectionLimit = 2
        config.filter = PHPickerFilter.videos
        
        let pickerViewController = PHPickerViewController(configuration: config)
        pickerViewController.delegate = self
        self.present(pickerViewController, animated: true, completion: nil)
    }
    
    @IBAction func saveVideoTapped(_ sender: UIButton) {
        viewModel.saveVideoTapped()
    }
    
    // MARK: PHPickerViewControllerDelegate
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        guard results.count > 0 else { return }
        viewModel.loadVideos(results)
    }
    
    // MARK: - Private
    
    private func setupObservations() {
        viewModel.showAlertPublisher.sink { [weak self] alertController in
            self?.present(alertController, animated: true)
        }.store(in: &subscriptions)
        
        viewModel.saveVideoAvailabilityPublisher.sink { [weak self] saveVideoStatus in
            switch saveVideoStatus {
            case .available:
                self?.saveVideoButton.setTitle("Save combined video", for: .normal)
                self?.saveVideoButton.isEnabled = true
            case .saving:
                self?.saveVideoButton.setTitle("Saving", for: .disabled)
                self?.saveVideoButton.isEnabled = false
            case .unavailable:
                self?.saveVideoButton.setTitle("Save combined video", for: .normal)
                self?.saveVideoButton.setTitle("Save combined video", for: .disabled)
                self?.saveVideoButton.isEnabled = false
            }
        }.store(in: &subscriptions)
    }
    
    private func setupUI() {
        saveVideoButton.isEnabled = false
        saveVideoButton.setTitle("Save combined video", for: .normal)
        saveVideoButton.setTitle("Save combined video", for: .disabled)
    }
}
