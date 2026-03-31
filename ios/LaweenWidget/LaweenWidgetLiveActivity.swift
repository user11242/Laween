import ActivityKit
import WidgetKit
import SwiftUI

// --- Color Helpers ---
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// Brand Colors
let laweenTeal = Color(hex: "006D77")
let laweenTealLight = Color(hex: "83C5BE")
let laweenGold = Color(hex: "D4AF37")
let laweenDark = Color(hex: "004D55")

struct Participant: Codable, Identifiable {
    var id: String { name }
    let name: String
    let initial: String
    let photoUrl: String
    let eta: String
    let dist: String
    let progress: Double
    let isMe: Bool
}

struct ActivityData: Codable {
    let list: [Participant]
    let groupEta: String
}

struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState
    public struct ContentState: Codable, Hashable {
        var appGroupId: String
    }
    var id: UUID
}

// --- Ultra High Fidelity Logo Recreation ---
struct LaweenLogoView: View {
    var size: CGFloat = 46
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .frame(width: size, height: size)
            
            // Precision Vector Pin + Orbiters
            ZStack {
                // The Main Pin Loop
                Circle()
                    .trim(from: 0.15, to: 0.85)
                    .stroke(
                        LinearGradient(colors: [laweenTeal, laweenDark], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round)
                    )
                    .frame(width: size * 0.5, height: size * 0.5)
                    .rotationEffect(.degrees(90))
                
                // The Inner Pin Circle
                Circle()
                    .fill(laweenTeal)
                    .frame(width: size * 0.18, height: size * 0.18)
                
                // Orbiter 1 (Top Left)
                Circle()
                    .fill(laweenTeal)
                    .frame(width: size * 0.14, height: size * 0.14)
                    .offset(x: -size * 0.35, y: -size * 0.3)
                
                // Orbiter 2 (Right)
                Circle()
                    .fill(laweenTealLight)
                    .frame(width: size * 0.14, height: size * 0.14)
                    .offset(x: size * 0.4, y: -size * 0.05)
                
                // Orbiter 3 (Bottom Left)
                Circle()
                    .fill(laweenDark)
                    .frame(width: size * 0.14, height: size * 0.14)
                    .offset(x: -size * 0.25, y: size * 0.4)
            }
            .scaleEffect(0.9)
        }
        .shadow(color: .black.opacity(0.15), radius: 5)
    }
}

struct LaweenWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            LiveActivityView(id: context.attributes.id, appGroupId: context.state.appGroupId)
                .activityBackgroundTint(laweenTeal)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    DynamicIslandLeadingView(id: context.attributes.id, appGroupId: context.state.appGroupId)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    DynamicIslandTrailingView(id: context.attributes.id, appGroupId: context.state.appGroupId)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    DynamicIslandBottomView(id: context.attributes.id, appGroupId: context.state.appGroupId)
                }
            } compactLeading: {
                Image(systemName: "car.fill")
                    .foregroundColor(laweenTealLight)
            } compactTrailing: {
                CompactTrailingView(id: context.attributes.id, appGroupId: context.state.appGroupId)
            } minimal: {
                Image(systemName: "car.fill")
                    .foregroundColor(laweenTealLight)
            }
            .widgetURL(URL(string: "laween://tracking"))
            .keylineTint(laweenTeal)
        }
    }
}

// --- Main Lock Screen View ---
struct LiveActivityView: View {
    let id: UUID
    let appGroupId: String
    
    var body: some View {
        let sharedDefault = UserDefaults(suiteName: appGroupId)
        let prefix = id.uuidString
        let json = sharedDefault?.string(forKey: "\(prefix)_participants") ?? "{}"
        let destName = sharedDefault?.string(forKey: "\(prefix)_destinationName") ?? "Destination"
        
        let data = (try? JSONDecoder().decode(ActivityData.self, from: json.data(using: .utf8) ?? Data())) ?? ActivityData(list: [], groupEta: "0")
        
        return ZStack {
            // --- HIGH CONTRAST GRADIENT (VERY VISIBLE) ---
            LinearGradient(colors: [laweenTeal, laweenTealLight.opacity(0.4)], startPoint: .top, endPoint: .bottom)
            
            HStack(alignment: .top, spacing: 14) {
                VStack {
                    LaweenLogoView(size: 48)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(destName)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("Arriving in \(data.groupEta) min")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(data.list.prefix(3)) { p in
                            ParticipantHybridRow(participant: p)
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
        }
    }
}

// --- Hybrid Slider Row ---
struct ParticipantHybridRow: View {
    let participant: Participant
    
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(participant.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("\(participant.eta)m · \(participant.dist)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 4.5)
                    
                    Capsule()
                        .fill(participant.progress > 0.9 ? laweenGold : Color.white)
                        .frame(width: geometry.size.width * CGFloat(participant.progress), height: 4.5)
                    
                    ZStack {
                        Circle()
                            .fill(participant.progress > 0.9 ? laweenGold : laweenTealLight)
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        
                        Text(participant.initial)
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.black)
                    }
                    .offset(x: (geometry.size.width * CGFloat(participant.progress)) - 10, y: 0)
                }
            }
            .frame(height: 20)
        }
    }
}

// --- Polished Dynamic Island ---
struct DynamicIslandLeadingView: View {
    let id: UUID
    let appGroupId: String
    var body: some View {
        let sharedDefault = UserDefaults(suiteName: appGroupId)
        let prefix = id.uuidString
        let json = sharedDefault?.string(forKey: "\(prefix)_participants") ?? "{}"
        let data = (try? JSONDecoder().decode(ActivityData.self, from: json.data(using: .utf8) ?? Data())) ?? ActivityData(list: [], groupEta: "0")
        let myEta = data.list.first(where: { $0.isMe })?.eta ?? "0"
        
        return HStack(spacing: 8) {
            Image(systemName: "location.north.circle.fill").foregroundColor(laweenTealLight).font(.system(size: 16))
            Text(myEta + "m").font(.system(size: 22, weight: .black, design: .rounded)).foregroundColor(.white)
        }.padding(.leading, 12).padding(.top, 4)
    }
}

struct DynamicIslandTrailingView: View {
    let id: UUID
    let appGroupId: String
    var body: some View {
        let sharedDefault = UserDefaults(suiteName: appGroupId)
        let prefix = id.uuidString
        let json = sharedDefault?.string(forKey: "\(prefix)_participants") ?? "{}"
        let data = (try? JSONDecoder().decode(ActivityData.self, from: json.data(using: .utf8) ?? Data())) ?? ActivityData(list: [], groupEta: "0")
        let myDist = data.list.first(where: { $0.isMe })?.dist ?? "0 km"
        
        return Text(myDist).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.white.opacity(0.8)).padding(.trailing, 12).padding(.top, 4)
    }
}

struct DynamicIslandBottomView: View {
    let id: UUID
    let appGroupId: String
    var body: some View {
        let sharedDefault = UserDefaults(suiteName: appGroupId)
        let prefix = id.uuidString
        let json = sharedDefault?.string(forKey: "\(prefix)_participants") ?? "{}"
        let data = (try? JSONDecoder().decode(ActivityData.self, from: json.data(using: .utf8) ?? Data())) ?? ActivityData(list: [], groupEta: "0")
        
        return VStack(spacing: 12) {
            Divider().background(Color.white.opacity(0.15))
            ForEach(data.list.prefix(2)) { p in
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(laweenTealLight).frame(width: 24, height: 24)
                        Text(p.initial).font(.system(size: 11, weight: .black)).foregroundColor(.black)
                    }
                    Text(p.isMe ? "You" : p.name).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    Spacer()
                    Text(p.eta + "m").font(.system(size: 15, weight: .black)).foregroundColor(laweenTealLight)
                }
            }
        }.padding(.horizontal, 16).padding(.bottom, 12).background(laweenTeal.opacity(0.1)) // Subtle tint to bridge the look
    }
}

struct CompactTrailingView: View {
    let id: UUID
    let appGroupId: String
    var body: some View {
        let sharedDefault = UserDefaults(suiteName: appGroupId)
        let prefix = id.uuidString
        let json = sharedDefault?.string(forKey: "\(prefix)_participants") ?? "{}"
        let data = (try? JSONDecoder().decode(ActivityData.self, from: json.data(using: .utf8) ?? Data())) ?? ActivityData(list: [], groupEta: "0")
        let myEta = data.list.first(where: { $0.isMe })?.eta ?? "0"
        return Text(myEta + "m").font(.system(size: 13, weight: .black, design: .rounded)).foregroundColor(laweenTealLight).padding(.trailing, 4)
    }
}
