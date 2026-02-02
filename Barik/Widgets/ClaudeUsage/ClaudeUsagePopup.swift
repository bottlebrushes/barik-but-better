import SwiftUI

struct ClaudeUsagePopup: View {
    @EnvironmentObject var configProvider: ConfigProvider
    @ObservedObject private var usageManager = ClaudeUsageManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if usageManager.usageData.isAvailable {
                titleBar
                Divider().background(Color.white.opacity(0.2))
                rateLimitSection(
                    icon: "clock",
                    title: "5-Hour Window",
                    percentage: usageManager.usageData.fiveHourPercentage,
                    count: usageManager.usageData.fiveHourCount,
                    limit: usageManager.usageData.fiveHourLimit,
                    resetDate: usageManager.usageData.fiveHourResetDate,
                    resetPrefix: "Resets in"
                )
                Divider().background(Color.white.opacity(0.2))
                rateLimitSection(
                    icon: "calendar",
                    title: "Weekly",
                    percentage: usageManager.usageData.weeklyPercentage,
                    count: usageManager.usageData.weeklyCount,
                    limit: usageManager.usageData.weeklyLimit,
                    resetDate: usageManager.usageData.weeklyResetDate,
                    resetPrefix: "Resets"
                )
                Divider().background(Color.white.opacity(0.2))
                todaySection
                Divider().background(Color.white.opacity(0.2))
                footerSection
            } else {
                unavailableView
            }
        }
        .frame(width: 280)
        .background(Color.black)
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack(spacing: 8) {
            Image("ClaudeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
            Text("Claude Usage")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            Text(usageManager.usageData.plan)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(planBadgeColor.opacity(0.3))
                .foregroundColor(planBadgeColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var planBadgeColor: Color {
        switch usageManager.usageData.plan.lowercased() {
        case "pro": return .orange
        case "max": return .purple
        case "team": return .blue
        case "free": return .gray
        default: return .orange
        }
    }

    // MARK: - Rate Limit Section

    private func rateLimitSection(
        icon: String,
        title: String,
        percentage: Double,
        count: Int,
        limit: Int,
        resetDate: Date?,
        resetPrefix: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .opacity(0.6)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Text("\(Int(min(percentage, 1.0) * 100))%")
                    .font(.system(size: 24, weight: .semibold))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor(for: percentage))
                        .frame(
                            width: geometry.size.width * min(percentage, 1.0),
                            height: 6
                        )
                        .animation(.easeOut(duration: 0.3), value: percentage)
                }
            }
            .frame(height: 6)

            if let resetDate = resetDate {
                Text("\(resetPrefix) \(resetTimeString(resetDate))")
                    .font(.system(size: 11))
                    .opacity(0.5)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func progressColor(for percentage: Double) -> Color {
        if percentage >= 0.8 { return .red }
        if percentage >= 0.6 { return .orange }
        return .white
    }

    private func resetTimeString(_ date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        if interval <= 0 { return "soon" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 24 {
            let formatter = DateFormatter()
            formatter.dateFormat = "E h:mm a"
            return formatter.string(from: date)
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - Today Section

    private var todaySection: some View {
        HStack {
            Text("Today")
                .font(.system(size: 13, weight: .medium))
                .opacity(0.7)
            Spacer()
            Text("\(usageManager.usageData.todayMessages) messages")
                .font(.system(size: 13, weight: .semibold))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Text("Updated \(timeAgoString(usageManager.usageData.lastUpdated))")
                .font(.system(size: 11))
                .opacity(0.4)

            Spacer()

            Button(action: {
                usageManager.refresh()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
                    .opacity(0.6)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func timeAgoString(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "\(seconds) sec ago" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes) min ago" }
        return "\(minutes / 60)h ago"
    }

    // MARK: - Unavailable

    private var unavailableView: some View {
        VStack(spacing: 12) {
            Image("ClaudeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .opacity(0.4)
            Text("Claude Code not found")
                .font(.system(size: 13, weight: .medium))
            Text("Install Claude Code to see usage stats")
                .font(.system(size: 11))
                .opacity(0.5)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}
