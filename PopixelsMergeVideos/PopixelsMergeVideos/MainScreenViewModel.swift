//
//  MainScreenViewModel.swift
//  PopixelsMergeVideos
//
//  Created by Oren Cohen on 27/01/2023.
//

import Foundation
import AVFoundation
import PhotosUI

class MainScreenViewModel {
    
    let videoPlayerViewModel = VideoPlayerViewModel()
    var selectedVideos: [AVURLAsset] = [AVURLAsset]()
    var combinedMovie: AVMutableComposition?
    
    // MARK - Public interface
    
    func saveVideoTapped() {
        
    }
    
    func loadVideos(_ results: [PHPickerResult]) {
        for result in results {
            let provider = result.itemProvider
            guard provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else { assertionFailure("Not a video!"); return }
            let movie = UTType.movie.identifier
            provider.loadFileRepresentation(forTypeIdentifier: movie) { [weak self] url, err in
                if let url = url {
                    DispatchQueue.main.sync {
                        let asset = AVURLAsset(url: url)
                        self?.selectedVideos.append(asset)
                    }
                }
            }
        }
        guard selectedVideos.count > 0 else { assertionFailure("Error - selectedVideos is empty"); return }
        mergeVideos(selectedVideos: selectedVideos)
    }
    
    // MARK - Private
    
    private func mergeVideos(selectedVideos: [AVURLAsset]) {
        let movie = AVMutableComposition()
        let videoTrack = movie.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = movie.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        do {
            var currentDuration = movie.duration
            
            for asset in selectedVideos {
                let assetRange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)
                let assetAudioTrack = asset.tracks(withMediaType: .audio).first!
                let assetVideoTrack = asset.tracks(withMediaType: .video).first!

                try videoTrack?.insertTimeRange(assetRange, of: assetVideoTrack, at: currentDuration)
                try audioTrack?.insertTimeRange(assetRange, of: assetAudioTrack, at: currentDuration)
                videoTrack?.preferredTransform = assetVideoTrack.preferredTransform
                currentDuration = movie.duration
            }
            
        } catch (let error) {
            print("Could not create movie \(error.localizedDescription)")
        }
        combinedMovie = movie
        
    }
    
    private func playCombinedMovie() {
        guard let combinedMovie else { assertionFailure("Error - no combined movie"); return }
        videoPlayerViewModel.playVideo(combinedMovie: combinedMovie)
    }
}
