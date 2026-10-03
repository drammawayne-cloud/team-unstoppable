import SwiftUI
import UIKit
import AVKit

private enum TU {
    static let background = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.07, green: 0.075, blue: 0.07, alpha: 1) : UIColor(red: 0.965, green: 0.951, blue: 0.914, alpha: 1) })
    static let card = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.12, alpha: 1) : UIColor(red: 0.995, green: 0.987, blue: 0.962, alpha: 1) })
    static let gold = Color(red: 0.88, green: 0.72, blue: 0.36)
    static let ink = Color(red: 0.075, green: 0.08, blue: 0.07)
}

struct AppShell: View {
    @State private var tab = 0
    @State private var showPlayer = false
    var body: some View {
        TabView(selection: $tab) {
            page(HomeScreen(tab: $tab)).tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            page(RadioScreen()).tabItem { Label("Radio", systemImage: "antenna.radiowaves.left.and.right") }.tag(1)
            page(TeamScreen()).tabItem { Label("The Team", systemImage: "person.2.fill") }.tag(2)
            page(EventsScreen()).tabItem { Label("Events", systemImage: "calendar") }.tag(3)
            page(MoreScreen()).tabItem { Label("More", systemImage: "square.grid.2x2.fill") }.tag(4)
        }
        .tint(Color.primary)
        .sheet(isPresented: $showPlayer) { NavigationStack { RadioScreen(nowPlaying: true) }.presentationDragIndicator(.visible) }
        .onOpenURL { url in
            guard url.scheme == "teamunstoppable" else { return }
            switch url.host { case "radio": tab = 1; case "team": tab = 2; case "events": tab = 3; case "more": tab = 4; default: tab = 0 }
        }
    }
    private func page<Content: View>(_ content: Content) -> some View {
        NavigationStack {
            content.safeAreaInset(edge: .bottom, spacing: 0) { MiniPlayer { showPlayer = true } }
        }
    }
}

private struct Canvas<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) { content }
                .frame(maxWidth: 740, alignment: .leading).padding(22).frame(maxWidth: .infinity)
        }.background(TU.background)
    }
}
private struct Eyebrow: View {
    let text: String
    var body: some View { Text(text.uppercased()).font(.system(size: 11, weight: .heavy, design: .monospaced)).tracking(2).foregroundStyle(.secondary) }
}
private struct SectionHeading: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.title2.bold())
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
        }
    }
}
private struct SolidButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).padding(.horizontal, 20).padding(.vertical, 16)
            .frame(maxWidth: .infinity).foregroundStyle(TU.ink)
            .background(TU.gold.opacity(configuration.isPressed ? 0.65 : 1), in: RoundedRectangle(cornerRadius: 16))
    }
}
private struct BlankState: View {
    let symbol: String
    let title: String
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: symbol).font(.system(size: 30)).foregroundStyle(.secondary).accessibilityHidden(true)
            Text(title).font(.headline)
            Text(text).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(24).background(TU.card, in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct HomeScreen: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var radio: RadioPlayer
    @Binding var tab: Int
    var body: some View {
        Canvas {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("TEAM").font(.system(size: 14, weight: .black, design: .rounded)).tracking(6)
                    Text("UNSTOPPABLE").font(.system(size: 24, weight: .black, design: .rounded)).tracking(-0.7)
                }
                Spacer()
                NavigationLink { SavedScreen() } label: { Image(systemName: "bookmark").font(.title3).frame(width: 44, height: 44) }.accessibilityLabel("Saved items")
            }
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 8) {
                    Image(systemName: "globe.americas.fill")
                    Text("CARIBBEAN ROOTS. WORLDWIDE SOUND.").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1)
                }.foregroundStyle(TU.gold)
                Text("ONE TEAM.\nNO LIMITS.").font(.system(size: 52, weight: .black, design: .rounded)).tracking(-2).minimumScaleFactor(0.65).foregroundStyle(.white)
                Text("The DJs. The music. The movement.\nTake Team Unstoppable everywhere.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.72)).lineSpacing(4)
                Button { radio.playRadio(); tab = 1 } label: { Label("Listen to High Life Radio", systemImage: "play.fill") }.buttonStyle(SolidButton())
                HStack {
                    Text("01 / THE COLLECTIVE").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1)
                    Spacer()
                    Image(systemName: "waveform").font(.title2)
                }.foregroundStyle(.white.opacity(0.45))
            }.padding(26).frame(maxWidth: .infinity, alignment: .leading).background(TU.ink, in: RoundedRectangle(cornerRadius: 28))
            HStack(spacing: 12) {
                shortcut("The team", symbol: "person.2.fill") { tab = 2 }
                NavigationLink { MixesScreen() } label: { shortcutLabel("Mixes", symbol: "opticaldisc.fill") }.buttonStyle(.plain)
                shortcut("Events", symbol: "calendar") { tab = 3 }
            }
            HStack(alignment: .bottom) {
                SectionHeading(title: "Behind the sound.", subtitle: "Meet the people in the movement.")
                Spacer()
                Button("View all") { tab = 2 }.font(.subheadline.bold())
            }
            ForEach(store.content.members.prefix(2)) { member in
                NavigationLink { MemberDetail(member: member) } label: { MemberRow(member: member) }.buttonStyle(.plain)
            }
            if store.content.members.isEmpty { BlankState(symbol: "person.2", title: "The team is coming together", text: "Published member profiles will appear here.") }
            NavigationLink { BookingScreen() } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(text: "Bring the energy")
                        Text("Your event. Our sound.").font(.title3.bold())
                        Text("Prepare a booking request").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.title2)
                }.padding(24).background(TU.card, in: RoundedRectangle(cornerRadius: 22))
            }.buttonStyle(.plain)
            Text(store.contentStatus).font(.caption).foregroundStyle(.secondary)
        }.toolbar(.hidden, for: .navigationBar).refreshable { await store.refresh() }
    }
    private func shortcut(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { shortcutLabel(title, symbol: symbol) }.buttonStyle(.plain)
    }
    private func shortcutLabel(_ title: String, symbol: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.title3)
            Text(title).font(.system(size: 12, weight: .semibold))
        }.frame(maxWidth: .infinity).padding(.vertical, 21).background(TU.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct RecordArtwork: View {
    var body: some View {
        ZStack {
            Circle().fill(TU.ink)
            ForEach(0..<12) { index in
                Circle().stroke(.white.opacity(index % 3 == 0 ? 0.13 : 0.04), lineWidth: 1).padding(CGFloat(index) * 7 + 10)
            }
            Circle().fill(TU.gold).padding(76)
            VStack(spacing: 6) {
                Text("HIGH LIFE").font(.system(size: 15, weight: .black, design: .rounded))
                Text("RADIO").font(.system(size: 10, weight: .heavy, design: .monospaced)).tracking(4)
                Circle().fill(TU.ink).frame(width: 9, height: 9).padding(.top, 7)
            }.foregroundStyle(TU.ink)
        }.aspectRatio(1, contentMode: .fit).accessibilityLabel("High Life Radio record artwork")
    }
}
private struct MiniPlayer: View {
    @EnvironmentObject private var radio: RadioPlayer
    var open: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Button(action: open) {
                HStack(spacing: 12) {
                    Image(systemName: radio.isLiveStream ? "antenna.radiowaves.left.and.right" : "waveform")
                        .font(.title3).foregroundStyle(TU.ink).frame(width: 43, height: 43).background(TU.gold, in: RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(radio.title).font(.subheadline.bold()).lineLimit(1)
                        Text(radio.state.rawValue).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }.contentShape(Rectangle())
            }.buttonStyle(.plain).accessibilityLabel("Open player. \(radio.title). \(radio.state.rawValue)")
            Button { radio.toggle() } label: {
                Image(systemName: radio.isActive ? "pause.fill" : "play.fill").font(.title3).frame(width: 48, height: 48)
            }.buttonStyle(.plain).accessibilityLabel(radio.isActive ? "Pause audio" : "Play audio")
        }.padding(.horizontal, 18).padding(.vertical, 10).background(.regularMaterial)
            .overlay(alignment: .top) { Divider() }
    }
}
private struct RoutePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.tintColor = .label
        view.activeTintColor = .systemOrange
        view.prioritizesVideoDevices = false
        return view
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
private struct RadioScreen: View {
    @EnvironmentObject private var radio: RadioPlayer
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    var nowPlaying = false
    private var isCurrent: Bool { nowPlaying || radio.isLiveStream }
    var body: some View {
        Canvas {
            Eyebrow(text: nowPlaying && !radio.isLiveStream ? "The mix archive" : "High Life Radio · worldwide")
            VStack(spacing: 26) {
                RecordArtwork().frame(maxWidth: 310).padding(.vertical, 12)
                VStack(spacing: 10) {
                    Text(isCurrent ? radio.title : "High Life Radio").font(.title.bold()).multilineTextAlignment(.center)
                    Text(isCurrent ? radio.subtitle : "Caribbean energy. Global frequency.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Label(isCurrent ? radio.state.rawValue : "Switch to live radio", systemImage: isCurrent && radio.isPlaying ? "waveform" : "antenna.radiowaves.left.and.right")
                        .font(.caption.bold()).padding(.horizontal, 14).padding(.vertical, 8).background(TU.card, in: Capsule())
                }
                if isCurrent && !radio.isLiveStream && radio.duration > 0 {
                    VStack {
                        Slider(value: Binding(get: { radio.elapsed }, set: { radio.seek(to: $0) }), in: 0...max(1, radio.duration))
                            .accessibilityLabel("Playback position")
                        HStack {
                            Text(clock(radio.elapsed)); Spacer(); Text(clock(radio.duration))
                        }.font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 32) {
                    RoutePicker().frame(width: 52, height: 52).accessibilityLabel("Choose AirPlay or audio output")
                    Button {
                        if isCurrent { radio.toggle() } else { radio.playRadio() }
                    } label: {
                        Image(systemName: isCurrent && radio.isActive ? "pause.fill" : "play.fill")
                            .font(.system(size: 32, weight: .bold)).foregroundStyle(TU.ink)
                            .frame(width: 88, height: 88).background(TU.gold, in: Circle())
                    }.accessibilityLabel(isCurrent && radio.isActive ? "Pause playback" : "Start playback")
                    Menu {
                        ForEach([15, 30, 60], id: \.self) { minutes in Button("\(minutes) minutes") { radio.setSleep(minutes: minutes) } }
                        Button("Turn off sleep timer") { radio.setSleep(minutes: nil) }
                    } label: {
                        Image(systemName: radio.sleepUntil == nil ? "moon.zzz" : "moon.zzz.fill").font(.title2).frame(width: 52, height: 52)
                    }.accessibilityLabel("Sleep timer")
                }
                if let until = radio.sleepUntil { Text("Audio stops at \(until.formatted(date: .omitted, time: .shortened))").font(.caption).foregroundStyle(.secondary) }
                if isCurrent, let failure = radio.failureMessage {
                    Text(failure).font(.subheadline).multilineTextAlignment(.center).foregroundStyle(.secondary).accessibilityAddTraits(.updatesFrequently)
                }
            }.frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "The frequency")
                Text("One connection. Everywhere.").font(.title3.bold())
                Text("Listen while you explore the app. Use your lock screen, headphones or AirPlay to control the sound.").font(.subheadline).foregroundStyle(.secondary)
                Divider()
                Text(radio.stationMessage).font(.caption)
                Text(store.stationStatus).font(.caption).foregroundStyle(.secondary)
                if !radio.isLiveStream {
                    Button("Switch to High Life Radio") { radio.playRadio() }.font(.subheadline.bold())
                }
            }.padding(22).background(TU.card, in: RoundedRectangle(cornerRadius: 22))
        }.navigationTitle(nowPlaying ? "Now playing" : "Radio").navigationBarTitleDisplayMode(.inline)
            .toolbar { if nowPlaying { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } } }
    }
    private func clock(_ seconds: Double) -> String { let value = max(0, Int(seconds)); return String(format: "%d:%02d", value / 60, value % 60) }
}

private struct MemberPortrait: View {
    let member: Member
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(TU.ink)
            if let url = SafeLink.https(member.imageURL) {
                AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { initials }
            } else { initials }
        }.clipped().clipShape(RoundedRectangle(cornerRadius: 20))
    }
    private var initials: some View { Text(member.initials).font(.system(size: 29, weight: .black, design: .rounded)).foregroundStyle(TU.gold) }
}
private struct MemberRow: View {
    let member: Member
    var body: some View {
        HStack(spacing: 16) {
            MemberPortrait(member: member).frame(width: 72, height: 82)
            VStack(alignment: .leading, spacing: 8) {
                Text(member.name).font(.headline)
                Text(member.role).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "arrow.up.right").foregroundStyle(.secondary)
        }.padding(14).background(TU.card, in: RoundedRectangle(cornerRadius: 24))
    }
}
private struct TeamScreen: View {
    @EnvironmentObject private var store: AppStore
    @State private var search = ""
    var filtered: [Member] {
        store.content.members.filter { search.isEmpty || "\($0.name) \($0.role) \($0.genres.joined(separator: " "))".localizedCaseInsensitiveContains(search) }
    }
    var body: some View {
        Canvas {
            SectionHeading(title: "Different sounds.\nOne unstoppable team.", subtitle: "DJs, artists and the people behind the energy.")
            ForEach(filtered) { member in NavigationLink { MemberDetail(member: member) } label: { MemberRow(member: member) }.buttonStyle(.plain) }
            if filtered.isEmpty { BlankState(symbol: "person.2", title: search.isEmpty ? "Profiles coming soon" : "No matching profiles", text: search.isEmpty ? "Approved members will appear here." : "Try another name, role or genre.") }
        }.navigationTitle("The Team").searchable(text: $search, prompt: "Name, role or genre").refreshable { await store.refresh() }
    }
}
private struct SaveButton: View {
    @EnvironmentObject private var store: AppStore
    let kind: String
    let id: String
    var body: some View {
        Button { store.toggleSave(kind, id) } label: { Image(systemName: store.isSaved(kind, id) ? "bookmark.fill" : "bookmark").frame(width: 44, height: 44) }
            .accessibilityLabel(store.isSaved(kind, id) ? "Remove from saved" : "Save for later")
    }
}
private struct MemberDetail: View {
    let member: Member
    var body: some View {
        Canvas {
            MemberPortrait(member: member).frame(height: 230)
            Eyebrow(text: member.role)
            Text(member.name).font(.largeTitle.bold())
            Text(member.bio).font(.body).lineSpacing(5)
            Text(member.genres.joined(separator: "  /  ")).font(.caption.bold()).foregroundStyle(.secondary)
            if let website = SafeLink.https(member.websiteURL) { Link("Official website", destination: website) }
            NavigationLink { BookingScreen(memberName: member.name) } label: { Label("Request a booking", systemImage: "envelope") }.buttonStyle(SolidButton())
        }.navigationTitle(member.name).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .primaryAction) { SaveButton(kind: "member", id: member.id) } }
    }
}

private struct EventsScreen: View {
    @EnvironmentObject private var store: AppStore
    @State private var savedOnly = false
    private var events: [TeamEvent] {
        store.content.events.filter { $0.isUpcoming() && (!savedOnly || store.isSaved("event", $0.id)) }.sorted { ($0.start ?? .distantFuture) < ($1.start ?? .distantFuture) }
    }
    var body: some View {
        Canvas {
            SectionHeading(title: "Be where the energy is.", subtitle: "The next link-up starts here.")
            Picker("Events", selection: $savedOnly) { Text("Upcoming").tag(false); Text("Saved").tag(true) }.pickerStyle(.segmented)
            ForEach(events) { event in NavigationLink { EventDetail(event: event) } label: { EventRow(event: event) }.buttonStyle(.plain) }
            if events.isEmpty {
                BlankState(symbol: "calendar", title: savedOnly ? "No upcoming saved events" : "The next link-up is on the way", text: savedOnly ? "Save an event to keep it here." : "Confirmed events, venues and ticket links will appear here. There are no announced dates in this build.")
            }
            NavigationLink { BookingScreen() } label: { Label("Bring Team Unstoppable to your event", systemImage: "arrow.up.right") }.font(.subheadline.bold())
        }.navigationTitle("Events").refreshable { await store.refresh() }
    }
}
private struct EventRow: View {
    let event: TeamEvent
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let date = event.start { Eyebrow(text: date.formatted(date: .abbreviated, time: .shortened)) }
            Text(event.title).font(.title3.bold())
            Label(event.venue, systemImage: "mappin.and.ellipse").font(.subheadline).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(22).background(TU.card, in: RoundedRectangle(cornerRadius: 22))
    }
}
private struct EventDetail: View {
    @EnvironmentObject private var store: AppStore
    let event: TeamEvent
    @State private var notice = ""
    @State private var showNotice = false
    @State private var requesting = false
    private var maps: URL? {
        var parts = URLComponents(string: "https://maps.apple.com/")
        parts?.queryItems = [URLQueryItem(name: "q", value: "\(event.venue) \(event.address)")]
        return parts?.url
    }
    var body: some View {
        Canvas {
            EventRow(event: event)
            Text(event.description).lineSpacing(5)
            if let date = event.start { Text("Times are shown in your device’s time zone. \(date.formatted(date: .complete, time: .shortened))").font(.caption).foregroundStyle(.secondary) }
            if let maps { Link(destination: maps) { Label(event.address.isEmpty ? "Open venue in Maps" : event.address, systemImage: "map") } }
            if let tickets = SafeLink.https(event.ticketURL) { Link("View tickets", destination: tickets).buttonStyle(SolidButton()) }
            Button {
                requesting = true
                Task {
                    defer { requesting = false }
                    do { notice = try await store.remind(event) } catch { notice = "The reminder could not be scheduled. Please try again." }
                    showNotice = true
                }
            } label: { Label("Remind me one hour before", systemImage: "bell") }.disabled(requesting || !event.isUpcoming())
            ShareLink(item: "\(event.title)\n\(event.venue)\n\(event.startsAt)\n\(event.ticketURL ?? AppStore.website.absoluteString)") { Label("Share event", systemImage: "square.and.arrow.up") }
        }.navigationTitle(event.title).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .primaryAction) { SaveButton(kind: "event", id: event.id) } }
            .alert("Event reminder", isPresented: $showNotice) { Button("OK", role: .cancel) {} } message: { Text(notice) }
    }
}

private struct MixesScreen: View {
    @EnvironmentObject private var store: AppStore
    @State private var search = ""
    private var mixes: [Mix] { store.content.mixes.filter { search.isEmpty || "\($0.title) \($0.artist) \($0.genre)".localizedCaseInsensitiveContains(search) } }
    var body: some View {
        Canvas {
            SectionHeading(title: "Stay in the mix.", subtitle: "DJ sets and selections from the team.")
            ForEach(mixes) { mix in MixRow(mix: mix) }
            if mixes.isEmpty { BlankState(symbol: "opticaldisc", title: search.isEmpty ? "The archive is coming next" : "No matching mixes", text: search.isEmpty ? "Approved mixes will appear here. In the meantime, listen to High Life Radio." : "Try another title, DJ or genre.") }
        }.navigationTitle("Mixes").searchable(text: $search, prompt: "Title, DJ or genre")
    }
}
private struct MixRow: View {
    @EnvironmentObject private var radio: RadioPlayer
    let mix: Mix
    var body: some View {
        HStack(spacing: 14) {
            Button { if radio.currentMixID == mix.id { radio.toggle() } else { radio.play(mix) } } label: {
                Image(systemName: radio.currentMixID == mix.id && radio.isActive ? "pause.fill" : "play.fill").frame(width: 48, height: 48).background(TU.gold, in: Circle()).foregroundStyle(TU.ink)
            }.accessibilityLabel("\(radio.currentMixID == mix.id && radio.isActive ? "Pause" : "Play") \(mix.title)")
            VStack(alignment: .leading, spacing: 5) { Text(mix.title).font(.headline); Text("\(mix.artist) · \(mix.genre)").font(.caption).foregroundStyle(.secondary) }
            Spacer()
            SaveButton(kind: "mix", id: mix.id)
        }.padding(16).background(TU.card, in: RoundedRectangle(cornerRadius: 22))
    }
}
private struct SavedScreen: View {
    @EnvironmentObject private var store: AppStore
    private var members: [Member] { store.content.members.filter { store.isSaved("member", $0.id) } }
    private var mixes: [Mix] { store.content.mixes.filter { store.isSaved("mix", $0.id) } }
    private var events: [TeamEvent] { store.content.events.filter { store.isSaved("event", $0.id) } }
    var body: some View {
        Canvas {
            Text("Your corner of the movement.").font(.title2.bold())
            if members.isEmpty && mixes.isEmpty && events.isEmpty { BlankState(symbol: "bookmark", title: "Make it yours", text: "Save team profiles, mixes and events. Your saved items stay on this device; audio is streamed, not downloaded.") }
            ForEach(members) { member in NavigationLink { MemberDetail(member: member) } label: { MemberRow(member: member) }.buttonStyle(.plain) }
            ForEach(mixes) { mix in MixRow(mix: mix) }
            ForEach(events) { event in NavigationLink { EventDetail(event: event) } label: { EventRow(event: event) }.buttonStyle(.plain) }
        }.navigationTitle("Saved")
    }
}
private struct VideosScreen: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        Canvas {
            SectionHeading(title: "See the movement.", subtitle: "Performances, moments and behind the scenes.")
            ForEach(store.content.videos) { video in
                if let url = SafeLink.https(video.url) { Link(destination: url) { Label(video.title, systemImage: "play.rectangle").font(.headline).frame(maxWidth: .infinity, alignment: .leading).padding(22).background(TU.card, in: RoundedRectangle(cornerRadius: 20)) } }
            }
            if store.content.videos.isEmpty { BlankState(symbol: "play.rectangle", title: "Videos coming soon", text: "Official video links will appear here once published. Videos open with their original provider.") }
        }.navigationTitle("Videos")
    }
}
private struct MoreScreen: View {
    @EnvironmentObject private var store: AppStore
    @AppStorage("appearance") private var appearance = "light"
    @State private var clear = false
    var body: some View {
        List {
            Section {
                NavigationLink { MixesScreen() } label: { Label("Mixes", systemImage: "opticaldisc") }
                NavigationLink { VideosScreen() } label: { Label("Videos", systemImage: "play.rectangle") }
                NavigationLink { SavedScreen() } label: { Label("Saved items", systemImage: "bookmark") }
                NavigationLink { BookingScreen() } label: { Label("Booking request", systemImage: "envelope") }
            } header: { Text("The movement") }
            Section {
                Link(destination: AppStore.website) { Label("1teamunstoppable.com", systemImage: "safari") }
                ShareLink(item: AppStore.website) { Label("Share Team Unstoppable", systemImage: "square.and.arrow.up") }
            } header: { Text("Connect") }
            Section {
                Picker("Appearance", selection: $appearance) { Text("Cream").tag("light"); Text("Dark").tag("dark"); Text("System").tag("system") }
                Button { Task { await store.refresh() } } label: { Label(store.refreshing ? "Refreshing…" : "Refresh content", systemImage: "arrow.clockwise") }.disabled(store.refreshing)
                Text(store.contentStatus).font(.caption).foregroundStyle(.secondary)
                NavigationLink { PrivacyScreen() } label: { Label("Privacy & app information", systemImage: "hand.raised") }
                Button("Clear saved items, drafts and reminders", role: .destructive) { clear = true }
            } header: { Text("Your app") }
            Section {
                Text("TEAM UNSTOPPABLE").font(.headline)
                Text("One team. No limits.\nVersion 0.1.0 · iPhone & iPad").font(.caption).foregroundStyle(.secondary)
            }
        }.scrollContentBackground(.hidden).background(TU.background).navigationTitle("More")
            .confirmationDialog("Clear saved items, booking drafts and event reminders on this device?", isPresented: $clear, titleVisibility: .visible) {
                Button("Clear local items", role: .destructive) { store.clearSaved() }
            }
    }
}
private struct BookingScreen: View {
    var memberName = "Team Unstoppable"
    @AppStorage("booking-draft") private var savedDraft = ""
    @State private var name = ""
    @State private var contact = ""
    @State private var location = ""
    @State private var date = Date().addingTimeInterval(86400)
    @State private var note = ""
    @State private var prepared = false
    private var valid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !contact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var draft: String {
        "TEAM UNSTOPPABLE — BOOKING REQUEST\nRequested: \(memberName)\nName: \(name)\nContact: \(contact)\nEvent date: \(date.formatted(date: .complete, time: .shortened))\nVenue / location: \(location)\nDetails: \(note)\n\nThis is an enquiry, not a confirmed booking."
    }
    var body: some View {
        Form {
            Section {
                Text("Request \(memberName)").font(.headline)
                Text("Prepare a request, then share it using Mail or Messages with your chosen recipient. This app does not automatically send enquiries or confirm availability.").font(.subheadline).foregroundStyle(.secondary)
            }
            Section("Your enquiry") {
                TextField("Your name", text: $name).textContentType(.name)
                TextField("Email or phone", text: $contact).textContentType(.emailAddress).textInputAutocapitalization(.never)
                DatePicker("Event date", selection: $date, in: Date()...)
                TextField("Venue / city", text: $location)
                TextField("Event details, set length and other notes", text: $note, axis: .vertical).lineLimit(4...8)
            }
            Section {
                Button("Prepare & save request") { savedDraft = draft; prepared = true }.disabled(!valid)
                if prepared { Text("Draft saved on this device. Not sent.").font(.caption).foregroundStyle(.secondary) }
            }
            if !savedDraft.isEmpty {
                Section("Saved request — not sent") {
                    Text(savedDraft).font(.subheadline).textSelection(.enabled)
                    ShareLink(item: savedDraft) { Label("Choose where to send", systemImage: "square.and.arrow.up") }
                }
            }
        }.scrollContentBackground(.hidden).background(TU.background).navigationTitle("Booking request").navigationBarTitleDisplayMode(.inline)
    }
}
private struct PrivacyScreen: View {
    var body: some View {
        Canvas {
            SectionHeading(title: "Your privacy matters.", subtitle: "This build does not require an account.")
            paragraph("On your device", "Saved profiles, saved events, saved mixes, display preferences and booking drafts are stored locally. Content is cached for browsing when offline. No audio is downloaded for offline use. Clear saved items and drafts from More.")
            paragraph("Network connections", "The app retrieves public content from GitHub and radio configuration and audio from High Life Radio’s configured services. These providers may receive ordinary connection information, such as an IP address. The app contains no advertising or analytics SDK.")
            paragraph("Permissions", "Notification permission is requested only when you choose an event reminder. This version does not request your contacts, microphone, camera or precise location. AirPlay and audio controls use Apple’s system interfaces.")
            paragraph("Sharing and external services", "Booking drafts are not submitted automatically. You choose a recipient through the system share sheet. External websites, tickets and videos have their own privacy policies and availability.")
            paragraph("Before public release", "This is a development build. The owner must approve public support and privacy-policy URLs, media rights, final branding and content before App Store submission.")
        }.navigationTitle("Privacy").navigationBarTitleDisplayMode(.inline)
    }
    private func paragraph(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) { Text(title).font(.headline); Text(body).font(.subheadline).foregroundStyle(.secondary).lineSpacing(4) }
    }
}
