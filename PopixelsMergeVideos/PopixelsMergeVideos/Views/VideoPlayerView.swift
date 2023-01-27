//
//  VideoPlayerView.swift
//  PopixelsMergeVideos
//
//  Created by Oren Cohen on 27/01/2023.
//

import UIKit
import AVFoundation

class VideoPlayerView: UIView {
    
    var viewModel: VideoPlayerViewModel?
    var playerLayer: AVPlayerLayer?
    var tapGesture: UITapGestureRecognizer?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapView(_:)))
    }
    
    init(viewModel: VideoPlayerViewModel) {
        super.init(frame: CGRect.zero)
        self.viewModel = viewModel
    }
    
    // MARK: - Actions
    
    @IBAction func didTapView(_ sender: UITapGestureRecognizer) {
        print("did tap view", sender)
        guard let player = playerLayer?.player else { return }
        
        if player.rate > 0.0 {
            player.pause()
        } else {
            player.play()
        }
    }
}
