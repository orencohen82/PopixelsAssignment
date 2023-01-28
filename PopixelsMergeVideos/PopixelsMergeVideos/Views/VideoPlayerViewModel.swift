//
//  VideoPlayerViewModel.swift
//  PopixelsMergeVideos
//
//  Created by Oren Cohen on 27/01/2023.
//

import Foundation
import AVFoundation
import Combine

struct VideoPlayerViewModelConfiguration {
    let playCombinedMoviePublisher: PassthroughSubject<AVMutableComposition, Never>
}

class VideoPlayerViewModel {
    
    let configuration: VideoPlayerViewModelConfiguration
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    let playerLayerPublisher = PassthroughSubject<AVPlayerLayer, Never>()
    private var subscriptions = Set<AnyCancellable>()
    
    init(configuration: VideoPlayerViewModelConfiguration) {
        self.configuration = configuration
        setupObservations()
    }
    
    // MARK: - Private
    
    private func setupObservations() {
        configuration.playCombinedMoviePublisher.sink { [weak self] combinedMovie in
            self?.playVideo(combinedMovie: combinedMovie)
        }.store(in: &subscriptions)
    }
    
    private func playVideo(combinedMovie: AVMutableComposition) {
        self.player = AVPlayer(playerItem: AVPlayerItem(asset: combinedMovie))
        self.playerLayer = AVPlayerLayer(player: player)
        guard let playerLayer else { assertionFailure(); return }
        playerLayerPublisher.send(playerLayer)
    }
}
