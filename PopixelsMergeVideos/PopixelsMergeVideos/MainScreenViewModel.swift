//
//  MainScreenViewModel.swift
//  PopixelsMergeVideos
//
//  Created by Oren Cohen on 27/01/2023.
//

import Foundation
import AVFoundation
import PhotosUI
import Combine

enum SaveVideoStatus {
    case unavailable
    case saving
    case available
}

class MainScreenViewModel {
    
    let videoPlayerViewModel: VideoPlayerViewModel
    var selectedVideos: [AVURLAsset] = [AVURLAsset]()
    var combinedMovie: AVMutableComposition?
    
    let playCombinedMoviePublisher = PassthroughSubject<AVMutableComposition, Never>()
    let showAlertPublisher = PassthroughSubject<UIAlertController, Never>()
    let saveVideoAvailabilityPublisher = PassthroughSubject<SaveVideoStatus, Never>()
    
    private var subscriptions = Set<AnyCancellable>()
    
    static var assetKeysRequiredToPlay = [
            "playable",
            "tracks",
            "duration"
    ]
    
    // MARK: - Public interface
    
    init() {
        self.videoPlayerViewModel = VideoPlayerViewModel(
            configuration: VideoPlayerViewModelConfiguration(
                playCombinedMoviePublisher: playCombinedMoviePublisher))
    }
    
    func saveVideoTapped() {
        guard let assetToExport = self.videoPlayerViewModel.player?.currentItem?.asset else { return }
        guard let outputMovieURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("exported.mov") else { return }
        saveVideoAvailabilityPublisher.send(.saving)
        export(assetToExport, to: outputMovieURL)
    }
    
    func loadVideos(_ results: [PHPickerResult]) {
        guard results.count > 0 else { return }
        let dispatchGroup = DispatchGroup()
        
        for result in results {
            dispatchGroup.enter()
            
            //print("handling result \(i)")
            
            loadVideo(result: result) { [weak self] asset in
                self?.selectedVideos.append(asset)
                //print("finished handling result \(i)")
                dispatchGroup.leave()
            }
            
            dispatchGroup.notify(queue: .main) { [weak self] in
                guard let selectedVideos = self?.selectedVideos, selectedVideos.count > 0 else { assertionFailure("Error - selectedVideos is empty"); return }
                self?.mergeVideos(selectedVideos: selectedVideos)
                //print("finished handling results")
            }
        }
    }
}

// MARK: - Private

private extension MainScreenViewModel {
    private func loadVideo(result: PHPickerResult, completion: @escaping (AVURLAsset) -> Void) {
        let provider = result.itemProvider
        guard provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else { assertionFailure("Not a video!"); return }
        let movie = UTType.movie.identifier
        provider.loadFileRepresentation(forTypeIdentifier: movie) { url, err in
            if let url = url {
                let asset = AVURLAsset(url: url)
                let tracksKey = #keyPath(AVAsset.tracks)
                asset.loadValuesAsynchronously(forKeys: [tracksKey]) {
                    DispatchQueue.main.sync {
                        completion(asset)
                    }
                }
            }
        }
    }
    
    private func mergeVideos(selectedVideos: [AVURLAsset]) {
        let movie = AVMutableComposition()
        let videoTrack = movie.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = movie.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        var currentDuration = movie.duration
        
        for asset in selectedVideos {
            do {
                let assetRange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)
                guard let assetAudioTrack = asset.tracks(withMediaType: .audio).first else { assertionFailure("Error - asset.tracks is empty"); return }
                guard let assetVideoTrack = asset.tracks(withMediaType: .video).first else { assertionFailure("Error - asset.tracks is empty"); return }
                
                try videoTrack?.insertTimeRange(assetRange, of: assetVideoTrack, at: currentDuration)
                try audioTrack?.insertTimeRange(assetRange, of: assetAudioTrack, at: currentDuration)
                videoTrack?.preferredTransform = assetVideoTrack.preferredTransform
                currentDuration = movie.duration
                
                
            } catch (let error) {
                print("Could not create movie \(error.localizedDescription)")
                return
            }
        }
        combinedMovie = movie
        playCombinedMovie()
    }
    
    private func playCombinedMovie() {
        guard let combinedMovie else { assertionFailure("Error - no combined movie"); return }
        playCombinedMoviePublisher.send(combinedMovie)
        self.saveVideoAvailabilityPublisher.send(.available)
    }
    
    private func export(_ asset: AVAsset, to outputMovieURL: URL) {

      //delete any old file
      do {
        try FileManager.default.removeItem(at: outputMovieURL)
      } catch {
        print("Could not remove file (or file doesn't exist) \(error.localizedDescription)")
      }

      //create exporter
      let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)

      //configure exporter
      exporter?.outputURL = outputMovieURL
      exporter?.outputFileType = .mov

      //export!
      exporter?.exportAsynchronously(completionHandler: { [weak exporter] in
        DispatchQueue.main.async {
          if let error = exporter?.error {
            print("failed \(error.localizedDescription)")
          } else {
            self.saveVideoToCameraRoll(outputMovieURL: outputMovieURL)
          }
        }

      })
    }
    
    private func saveVideoToCameraRoll(outputMovieURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputMovieURL)
        }) { [weak self] saved, error in
            if saved {
                DispatchQueue.main.sync {
                    let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    self?.showAlertPublisher.send(alertController)
                    self?.saveVideoAvailabilityPublisher.send(.available)
                }
            }
        }
    }
}
