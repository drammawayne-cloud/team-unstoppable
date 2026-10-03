import Foundation
import Combine
import AVFoundation
import MediaPlayer
import UIKit

@MainActor
final class RadioPlayer: ObservableObject {
    enum State: String {
        case ready = "Ready to listen", connecting = "Connecting", playing = "Playing", paused = "Paused", buffering = "Buffering", unavailable = "Connection unavailable"
    }
    @Published private(set) var state: State = .ready
    @Published private(set) var title = "High Life Radio"
    @Published private(set) var subtitle = "Caribbean energy. Global frequency."
    @Published private(set) var stationMessage = "Tap play to connect"
    @Published private(set) var isLiveStream = true
    @Published private(set) var currentMixID: String?
    @Published private(set) var elapsed: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var sleepUntil: Date?
    @Published private(set) var failureMessage: String?
    var isPlaying: Bool { state == .playing }
    var isActive: Bool { wantsPlayback }
    var busy: Bool { state == .connecting || state == .buffering }
    private(set) var config = StationConfig.fallback
    private let player = AVPlayer()
    private var wantsPlayback = false
    private var generation = UUID()
    private var interruptedPlayback = false
    private var retries = 0
    private var statusObservation: NSKeyValueObservation?
    private var itemObservation: NSKeyValueObservation?
    private var observers = Set<AnyCancellable>()
    private var endObserver: AnyCancellable?
    private var failureObserver: AnyCancellable?
    private var retryTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?
    private var metadataTask: Task<Void, Never>?
    private var sleepTask: Task<Void, Never>?
    private var timeObserver: Any?
    private var foreground = true
    private let metadataSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 8
        configuration.timeoutIntervalForResource = 10
        return URLSession(configuration: configuration)
    }()
    init() {
        player.automaticallyWaitsToMinimizeStalling = true
        statusObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            let status = player.timeControlStatus
            Task { @MainActor [weak self] in self?.handle(status) }
        }
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.elapsed = time.seconds.isFinite ? max(0, time.seconds) : 0
                let total = self.player.currentItem?.duration.seconds ?? 0
                self.duration = total.isFinite ? max(0, total) : 0
                if !self.isLiveStream && self.isPlaying { self.updateNowPlaying() }
            }
        }
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: DispatchQueue.main).sink { [weak self] note in self?.interruption(note) }.store(in: &observers)
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .receive(on: DispatchQueue.main).sink { [weak self] note in
                guard let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                      AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable else { return }
                self?.pause()
            }.store(in: &observers)
        configureRemoteCommands()
    }
    func configure(_ value: StationConfig) {
        guard (try? value.validated()) != nil else { return }
        let changed = value != config
        config = value
        if changed { metadataTask?.cancel(); metadataTask = nil }
        startMetadataUpdates()
    }
    func setForeground(_ value: Bool) {
        foreground = value
        if foreground || wantsPlayback { startMetadataUpdates() }
        else { metadataTask?.cancel(); metadataTask = nil }
    }
    func playRadio() {
        guard let url = SafeLink.https(config.streamUrl) else { return }
        isLiveStream = true
        currentMixID = nil
        title = config.stationName
        subtitle = "Caribbean energy. Global frequency."
        begin(url: url)
    }
    func play(_ mix: Mix) {
        guard let url = SafeLink.https(mix.audioURL) else { return }
        isLiveStream = false
        currentMixID = mix.id
        title = mix.title
        subtitle = mix.artist
        begin(url: url)
    }
    func toggle() {
        if wantsPlayback { pause() }
        else if isLiveStream || player.currentItem == nil { playRadio() }
        else { resume() }
    }
    private func activateAudio() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, policy: .longFormAudio)
        try session.setActive(true)
    }
    private func begin(url: URL) {
        generation = UUID()
        retryTask?.cancel(); timeoutTask?.cancel()
        retries = 0; elapsed = 0; duration = 0
        failureMessage = nil
        wantsPlayback = true
        state = .connecting
        do {
            try activateAudio()
            replaceItem(url)
            player.play()
            armTimeout()
            startMetadataUpdates()
            updateNowPlaying()
        } catch { fail("Audio output could not start. Try again.") }
    }
    private func replaceItem(_ url: URL) {
        let item = AVPlayerItem(url: url)
        let token = generation
        itemObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .failed else { return }
            Task { @MainActor [weak self] in
                guard let self, self.generation == token else { return }
                self.retryOrFail()
            }
        }
        endObserver = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main).sink { [weak self] _ in
                guard let self, self.generation == token else { return }
                if self.isLiveStream { self.retryOrFail() } else { self.pause(); self.seek(to: 0) }
            }
        failureObserver = NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main).sink { [weak self] _ in
                guard let self, self.generation == token else { return }; self.retryOrFail()
            }
        player.replaceCurrentItem(with: item)
    }
    private func resume() {
        guard player.currentItem?.status != .failed else {
            fail("This mix could not load. Open the mix and try it again."); return
        }
        failureMessage = nil
        do { try activateAudio(); wantsPlayback = true; state = .connecting; player.play(); armTimeout(); startMetadataUpdates() }
        catch { fail("Audio output could not start. Try again.") }
    }
    func pause() {
        wantsPlayback = false
        retryTask?.cancel(); retryTask = nil
        timeoutTask?.cancel(); timeoutTask = nil
        player.pause()
        state = .paused
        failureMessage = nil
        updateNowPlaying()
        if !foreground { metadataTask?.cancel(); metadataTask = nil }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    private func handle(_ status: AVPlayer.TimeControlStatus) {
        guard wantsPlayback else { return }
        switch status {
        case .playing:
            state = .playing
            failureMessage = nil
            timeoutTask?.cancel(); timeoutTask = nil
            retryTask?.cancel(); retryTask = nil
        case .waitingToPlayAtSpecifiedRate:
            state = state == .connecting ? .connecting : .buffering
            armTimeout()
        case .paused: break
        @unknown default: break
        }
        updateNowPlaying()
    }
    private func armTimeout() {
        guard timeoutTask == nil else { return }
        let token = generation
        timeoutTask = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: 18_000_000_000) } catch { return }
            guard let self, self.generation == token, self.wantsPlayback, self.state != .playing else { return }
            self.timeoutTask = nil
            self.retryOrFail()
        }
    }
    private func retryOrFail() {
        guard wantsPlayback, retryTask == nil else { return }
        timeoutTask?.cancel(); timeoutTask = nil
        guard isLiveStream, retries < 3, let url = SafeLink.https(config.streamUrl) else {
            fail("The stream is unavailable or your connection was interrupted. Press play to try again."); return
        }
        let delay = [2, 5, 10][retries]
        retries += 1
        state = .buffering
        failureMessage = "Reconnecting · attempt \(retries) of 3"
        let token = generation
        retryTask = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: UInt64(delay) * 1_000_000_000) } catch { return }
            guard let self, self.generation == token, self.wantsPlayback else { return }
            self.retryTask = nil
            self.replaceItem(url)
            self.player.play()
            self.armTimeout()
        }
    }
    private func fail(_ message: String) {
        pause()
        failureMessage = message
        state = .unavailable
        updateNowPlaying()
    }
    func seek(to seconds: Double) {
        guard !isLiveStream, duration > 0, seconds.isFinite else { return }
        player.seek(to: CMTime(seconds: min(max(0, seconds), duration), preferredTimescale: 600))
        elapsed = min(max(0, seconds), duration)
        updateNowPlaying()
    }
    func setSleep(minutes: Int?) {
        sleepTask?.cancel(); sleepTask = nil
        guard let minutes, minutes > 0 else { sleepUntil = nil; return }
        sleepUntil = Date().addingTimeInterval(Double(minutes * 60))
        sleepTask = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: UInt64(minutes * 60) * 1_000_000_000) } catch { return }
            self?.pause(); self?.sleepUntil = nil
        }
    }
    private func interruption(_ note: Notification) {
        guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        if type == .began { interruptedPlayback = wantsPlayback; pause() }
        else {
            let rawOptions = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            if interruptedPlayback && AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume) {
                if isLiveStream { playRadio() } else { resume() }
            }
            interruptedPlayback = false
        }
    }
    private func startMetadataUpdates() {
        guard metadataTask == nil, foreground || wantsPlayback else { return }
        metadataTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.refreshMetadata()
                do { try await Task.sleep(nanoseconds: 30_000_000_000) } catch { return }
            }
        }
    }
    private func refreshMetadata() async {
        guard let url = SafeLink.https(config.nowPlayingUrl) else { return }
        do {
            let (data, response) = try await metadataSession.data(from: url)
            guard !Task.isCancelled, let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode), data.count < 1_000_000,
                  SafeLink.https(response.url?.absoluteString) != nil else { return }
            let info = try RadioMetadata.decode(data)
            stationMessage = info.is_online == true ? "Station reports online" : (info.is_online == false ? "Station reports offline" : "Station status unknown")
            guard isLiveStream else { return }
            if let track = info.now_playing, track.isFresh(), let song = track.song {
                title = song.title?.isEmpty == false ? song.title! : (song.text ?? config.stationName)
                subtitle = song.artist?.isEmpty == false ? song.artist! : config.stationName
            } else {
                title = config.stationName
                subtitle = "Track information is delayed"
            }
            updateNowPlaying()
        } catch {
            guard !Task.isCancelled else { return }
            stationMessage = "Station metadata unavailable"
            if isLiveStream { title = config.stationName; subtitle = "Live radio · track information unavailable"; updateNowPlaying() }
        }
    }
    private func configureRemoteCommands() {
        let commands = MPRemoteCommandCenter.shared()
        commands.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in guard let self, !self.wantsPlayback else { return }; self.toggle() }; return .success
        }
        commands.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }; return .success
        }
        commands.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.toggle() }; return .success
        }
        commands.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let position = event.positionTime
            Task { @MainActor in self?.seek(to: position) }; return .success
        }
        commands.nextTrackCommand.isEnabled = false
        commands.previousTrackCommand.isEnabled = false
        commands.changePlaybackPositionCommand.isEnabled = false
    }
    private func updateNowPlaying() {
        var info: [String: Any] = [MPMediaItemPropertyTitle: title,
                                  MPMediaItemPropertyArtist: subtitle,
                                  MPMediaItemPropertyAlbumTitle: "Team Unstoppable",
                                  MPNowPlayingInfoPropertyIsLiveStream: isLiveStream,
                                  MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0]
        if !isLiveStream { info[MPMediaItemPropertyPlaybackDuration] = duration; info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed }
        if let image = UIImage(named: "RadioArtwork") {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled = !isLiveStream && duration > 0
    }
}
