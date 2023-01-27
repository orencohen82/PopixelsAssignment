//
//  VideoPlayerViewModel.swift
//  PopixelsMergeVideos
//
//  Created by Oren Cohen on 27/01/2023.
//

import Foundation
import AVFoundation

class VideoPlayerViewModel {
    
    var player: AVPlayer?
    
    func playVideo(combinedMovie: AVMutableComposition) {
        self.player = AVPlayer(playerItem: AVPlayerItem(asset: combinedMovie))
        let playerLayer = AVPlayerLayer(player: player)
        
    }
}
