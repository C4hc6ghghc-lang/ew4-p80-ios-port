import Foundation
import EW4NativeCore
#if canImport(AVFoundation)
import AVFoundation
#endif

public final class NativeAudioController: @unchecked Sendable {
    private let root: URL
    #if canImport(AVFoundation)
    private var bgm: AVAudioPlayer?
    private var effects: [AVAudioPlayer] = []
    #endif
    public init(resourceRoot: URL) { self.root = resourceRoot }

    public func playSFX(_ file: String, settings: NativeOptionsSettings) {
        guard settings.soundEffectVolume > 0 else { return }
        #if canImport(AVFoundation)
        guard let p=try? AVAudioPlayer(contentsOf:root.appendingPathComponent("Audio").appendingPathComponent(file)) else{return}
        p.volume=Float(settings.soundEffectVolume)/100; p.prepareToPlay(); p.play(); effects.append(p); effects.removeAll{!$0.isPlaying}
        #endif
    }
    public func playFormOpen(_ formID:String, settings:NativeOptionsSettings){if let f=NativeAudioPolicyCore.formOpenSFX[formID]{playSFX(f,settings:settings)}}
    public func startBattleMusic(index:Int=Int.random(in:0..<4), settings:NativeOptionsSettings){
        guard settings.backgroundVolume > 0 else { stopBattleMusic(); return }
        let file=NativeAudioPolicyCore.battleTrack(randomIndex:index)
        #if canImport(AVFoundation)
        guard let p=try? AVAudioPlayer(contentsOf:root.appendingPathComponent("Audio").appendingPathComponent(file)) else{return};bgm=p;p.numberOfLoops = -1;p.volume=Float(settings.backgroundVolume)/100;p.prepareToPlay();p.play()
        #endif
    }
    public func apply(_ settings:NativeOptionsSettings){
        #if canImport(AVFoundation)
        bgm?.volume=Float(settings.backgroundVolume)/100;if settings.backgroundVolume == 0 { bgm?.stop() }
        #endif
    }
    public func stopBattleMusic(){
        #if canImport(AVFoundation)
        bgm?.stop();bgm=nil
        #endif
    }
    public func playResult(_ kind:String,settings:NativeOptionsSettings){let cue=NativeAudioPolicyCore.resultCue(kind:kind);if cue.stopBattleMusic{stopBattleMusic()};if let b=cue.backgroundMusic {
        #if canImport(AVFoundation)
        if settings.backgroundVolume>0,let p=try? AVAudioPlayer(contentsOf:root.appendingPathComponent("Audio").appendingPathComponent(b)){bgm=p;p.numberOfLoops=0;p.volume=Float(settings.backgroundVolume)/100;p.play()}
        #endif
    };if let s=cue.soundEffect{playSFX(s,settings:settings)}}
}
