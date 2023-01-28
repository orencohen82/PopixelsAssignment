//
//  VideoPlayerView.swift
//  PopixelsMergeVideos
//
//  Created by Oren Cohen on 27/01/2023.
//

import UIKit
import AVFoundation
import Combine

class VideoPlayerView: UIView {
    
    var viewModel: VideoPlayerViewModel? {
        didSet {
            setupObservations()
        }
    }
    weak var playerLayer: AVPlayerLayer?
    var tapGesture: UITapGestureRecognizer?
    private var subscriptions = Set<AnyCancellable>()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapView(_:)))
        self.addGestureRecognizer(tapGesture!)
        self.backgroundColor = .gray
        self.isUserInteractionEnabled = true
    }
    
    // MARK: - Private
    
    private func setupObservations() {
        viewModel?.playerLayerPublisher.sink(receiveValue: { [weak self] playerLayer in
            self?.embedAndPlayVideo(playerLayer: playerLayer)
        }).store(in: &subscriptions)
    }
    
    private func embedAndPlayVideo(playerLayer: AVPlayerLayer) {
        self.playerLayer = playerLayer
        playerLayer.frame = self.layer.bounds
        playerLayer.videoGravity = .resizeAspect

        self.layer.sublayers?.removeAll()
        self.layer.addSublayer(playerLayer)

        playerLayer.player?.play()
    }
    
    // MARK: - Actions
    
    @objc func didTapView(_ sender: UITapGestureRecognizer) {
        guard let player = playerLayer?.player else { return }
        
        if player.rate > 0.0 {
            player.pause()
        } else {
            if player.currentTime() == player.currentItem?.duration {
                player.seek(to: CMTime.zero) { _ in
                    player.play()
                }
            } else {
                player.play()
            }            
        }
    }
}
