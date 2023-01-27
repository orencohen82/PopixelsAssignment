//
//  MainScreen.swift
//  PopixelsMergeVideos
//
//  Created by Oren Cohen on 27/01/2023.
//

import UIKit
import AVFoundation
import PhotosUI

class MainScreen: UIViewController, PHPickerViewControllerDelegate {
        
    @IBOutlet weak var chooseVideosButton: UIButton!
    @IBOutlet weak var saveVideoButton: UIButton!
    
    let viewModel = MainScreenViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        saveVideoButton.isEnabled = false
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
        
        self.saveVideoButton.isEnabled = true
        viewModel.loadVideos(results)
    }
}
