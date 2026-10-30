import SwiftUI

struct QuotaRhythmDay: Identifiable {
    let date: Date
    let weeklyLimit: Double
    let monthlyLimit: Double?
    let isToday: Bool

    var id: Date { date }
}

struct QuotaTodayRemaining {
    let value: Int
    let limit: Int
    let used: Int
    let isMonthly: Bool

    var signedText: String {
        value >= 0 ? "+\(value)%" : "\(value)%"
    }

    var menuLabel: String {
        isMonthly ? "月" : "7D"
    }
}

enum QuotaRhythm {
    static func todayRemaining(for quota: KimiQuota?, now: Date = Date(), calendar: Calendar = .current) -> QuotaTodayRemaining? {
        guard let weekly = quota?.weekly,
              let weeklyLimit = timeLimit(
                resetTime: quota?.weekly?.resetTime,
                days: 7,
                now: now,
                calendar: calendar
              ) else { return nil }
        let weeklyRemaining = weeklyLimit - weekly.percentage

        if let monthly = quota?.monthly,
           let monthlyLimit = timeLimit(resetTime: monthly.resetTime, days: 30, now: now, calendar: calendar) {
            let monthlyRemaining = monthlyLimit - monthly.percentage
            if monthlyRemaining < weeklyRemaining {
                return QuotaTodayRemaining(value: monthlyRemaining, limit: monthlyLimit, used: monthly.percentage, isMonthly: true)
            }
        }

        return QuotaTodayRemaining(value: weeklyRemaining, limit: weeklyLimit, used: weekly.percentage, isMonthly: false)
    }

    private static func timeLimit(resetTime: Date?, days: Int, now: Date, calendar: Calendar) -> Int? {
        guard let resetTime,
              let startTime = calendar.date(byAdding: .day, value: -days, to: resetTime),
              resetTime > startTime else { return nil }
        let progress = now.timeIntervalSince(startTime) / resetTime.timeIntervalSince(startTime)
        return Int((min(1, max(0, progress)) * 100).rounded())
    }

    static func days(for quota: KimiQuota, now: Date = Date(), calendar: Calendar = .current) -> [QuotaRhythmDay] {
        guard let weeklyReset = quota.weekly?.resetTime,
              let weeklyStart = calendar.date(byAdding: .day, value: -7, to: weeklyReset) else { return [] }

        let monthlyReset = quota.monthly?.resetTime
        let monthlyStart = monthlyReset.flatMap { calendar.date(byAdding: .day, value: -30, to: $0) }
        let firstDate = calendar.startOfDay(for: weeklyStart)

        return (0...7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: firstDate) else { return nil }
            let monthlyLimit: Double?
            if let monthlyStart, let monthlyReset, monthlyReset > monthlyStart {
                let progress = date.timeIntervalSince(monthlyStart) / monthlyReset.timeIntervalSince(monthlyStart)
                monthlyLimit = min(1, max(0, progress)) * 100
            } else {
                monthlyLimit = nil
            }
            return QuotaRhythmDay(
                date: date,
                weeklyLimit: Double(offset) / 7 * 100,
                monthlyLimit: monthlyLimit,
                isToday: calendar.isDate(date, inSameDayAs: now)
            )
        }
    }

    static func weekday(_ date: Date, calendar: Calendar = .current) -> String {
        let names = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return LanguageManager.tr(names[calendar.component(.weekday, from: date) - 1])
    }

    static func shortWeekday(_ date: Date, calendar: Calendar = .current) -> String {
        let names = ["日", "一", "二", "三", "四", "五", "六"]
        return LanguageManager.tr(names[calendar.component(.weekday, from: date) - 1])
    }

    static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }

    static func percentageText(_ value: Double?) -> String {
        guard let value else { return "--" }
        return String(format: "%.1f", value)
    }
}

struct WeeklyQuotaRhythmView: View {
    let quota: KimiQuota
    let style: MultiAccountCardStyle
    var now: Date = Date()

    @StateObject private var languageManager = LanguageManager.shared

    private var days: [QuotaRhythmDay] {
        QuotaRhythm.days(for: quota, now: now)
    }

    private var periodText: String {
        guard let first = days.first?.date, let last = days.last?.date else { return "" }
        return "\(QuotaRhythm.dateText(first)) → \(QuotaRhythm.dateText(last))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                LText(style == .classic ? "本周使用节奏" : "本周节奏")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.kimiTextPrimary)
                Spacer()
                if style == .classic {
                    Text(periodText)
                        .font(.system(size: 9))
                        .foregroundStyle(.kimiTextTertiary)
                } else {
                    HStack(spacing: 3) {
                        Text(LanguageManager.tr("周")).foregroundStyle(Color.kimiBlue)
                        Text("/").foregroundStyle(.kimiTextTertiary)
                        Text(LanguageManager.tr("月")).foregroundStyle(.green)
                        Text("(%)").foregroundStyle(.kimiTextTertiary)
                    }
                    .font(.system(size: 9))
                }
            }

            switch style {
            case .classic:
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                    ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                        ClassicRhythmDayView(day: day, color: rhythmColors[index])
                    }
                }
            case .minimal:
                HStack(spacing: 2) {
                    ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                        MinimalRhythmDayView(day: day, color: rhythmColors[index])
                    }
                }
            }

            HStack {
                if style == .classic {
                    LText("每日平均上限")
                        .foregroundStyle(.kimiTextTertiary)
                    Spacer()
                }
                Text(dailyAverageText)
                    .foregroundStyle(.kimiTextSecondary)
                if style == .minimal { Spacer() }
            }
            .font(.system(size: 9, weight: .medium))
            .padding(.top, 7)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.kimiTextPrimary.opacity(0.06))
                    .frame(height: 1)
            }
        }
        .padding(12)
        .background(Color.kimiCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var dailyAverageText: String {
        LanguageManager.tr(
            style == .classic ? "周 14.3% / 天 · 月 3.3% / 天" : "日均 周 14.3% · 月 3.3%"
        )
    }

    private var rhythmColors: [Color] {
        [
            Color(red: 0.42, green: 0.59, blue: 0.94),
            Color(red: 0.61, green: 0.51, blue: 0.91),
            Color(red: 0.82, green: 0.50, blue: 0.74),
            Color(red: 0.87, green: 0.53, blue: 0.49),
            Color(red: 0.86, green: 0.64, blue: 0.37),
            Color(red: 0.65, green: 0.68, blue: 0.32),
            Color(red: 0.38, green: 0.72, blue: 0.57),
            Color(red: 0.35, green: 0.66, blue: 0.78)
        ]
    }
}

private struct ClassicRhythmDayView: View {
    let day: QuotaRhythmDay
    let color: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(QuotaRhythm.weekday(day.date))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(day.isToday ? color : .kimiTextPrimary)
                Text(QuotaRhythm.dateText(day.date))
                    .font(.system(size: 8))
                    .foregroundStyle(day.isToday ? color.opacity(0.85) : .kimiTextTertiary)
            }
            RhythmValueLine(label: LanguageManager.tr("周"), value: day.weeklyLimit)
            RhythmValueLine(label: LanguageManager.tr("月"), value: day.monthlyLimit)
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
        .padding(.bottom, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(day.isToday && colorScheme == .light ? 0.14 : 0.08))
        .overlay(alignment: .top) {
            Capsule()
                .fill(color)
                .frame(height: day.isToday ? 4 : 2)
                .padding(.horizontal, 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    color.opacity(day.isToday ? (colorScheme == .dark ? 0.85 : 0.38) : 0.18),
                    lineWidth: day.isToday ? 1.5 : 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(
            color: day.isToday ? (colorScheme == .dark ? color.opacity(0.36) : Color.black.opacity(0.10)) : .clear,
            radius: day.isToday && colorScheme == .dark ? 6 : 3,
            x: 0,
            y: day.isToday && colorScheme == .dark ? 3 : 1
        )
    }
}

private struct RhythmValueLine: View {
    let label: String
    let value: Double?

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(.kimiTextTertiary)
            Spacer(minLength: 1)
            Text("≤\(QuotaRhythm.percentageText(value))%")
                .font(.system(size: 9, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.kimiTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

private struct MinimalRhythmDayView: View {
    let day: QuotaRhythmDay
    let color: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 3) {
            Text("\(QuotaRhythm.shortWeekday(day.date))\(day.date.formatted(.dateTime.day(.twoDigits)))")
                .font(.system(size: 8))
                .foregroundStyle(day.isToday ? color : .kimiTextTertiary)
                .lineLimit(1)
            Text(QuotaRhythm.percentageText(day.weeklyLimit))
                .font(.system(size: 9, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Color.kimiBlue)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(QuotaRhythm.percentageText(day.monthlyLimit))
                .font(.system(size: 9, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.green)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(color.opacity(day.isToday ? (colorScheme == .dark ? 0.04 : 0.12) : 0))
        .overlay(alignment: .top) {
            Capsule()
                .fill(color)
                .frame(height: day.isToday ? 3 : 2)
                .padding(.horizontal, 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(color.opacity(day.isToday ? (colorScheme == .dark ? 0.75 : 0.30) : 0), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(
            color: day.isToday ? (colorScheme == .dark ? color.opacity(0.32) : Color.black.opacity(0.08)) : .clear,
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

extension QuotaDetail {
    var resetWithDateText: String {
        guard resetTime != nil else { return timeUntilReset }
        return "\(timeUntilReset)\n\(resetTimeText)"
    }
}

struct UnifiedQuotaCard: View {
    let quota: KimiQuota?
    let isLoading: Bool
    let style: MultiAccountCardStyle

    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch style {
                case .classic: classicContent
                case .minimal: minimalContent
                }
            }

            if quota?.monthlyKimiPercentage != nil || quota?.monthlyCodePercentage != nil {
                QuotaSeparator()
                MonthlyBreakdownRow(quota: quota)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
        }
        .background(Color.kimiCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var classicContent: some View {
        HStack(spacing: 0) {
            if let monthly = quota?.monthly {
                ClassicQuotaPeriod(
                    title: languageManager.tr("本月用量"),
                    detail: monthly,
                    color: .green,
                    isLoading: isLoading
                )
                QuotaSeparator(vertical: true)
            }

            if quota == nil || quota?.weekly != nil {
                ClassicQuotaPeriod(
                    title: languageManager.tr("本周用量"),
                    detail: quota?.weekly,
                    color: .kimiBlue,
                    isLoading: isLoading
                )
                QuotaSeparator(vertical: true)
            }

            ClassicQuotaPeriod(
                title: languageManager.tr("5小时用量"),
                detail: quota?.fiveHour,
                color: .orange,
                isLoading: isLoading
            )
        }
        .padding(.vertical, 14)
    }

    private var minimalContent: some View {
        VStack(spacing: 0) {
            if let monthly = quota?.monthly {
                MinimalUnifiedQuotaRow(
                    title: languageManager.tr("月"),
                    detail: monthly,
                    color: .green,
                    isLoading: isLoading
                )
            }

            if quota?.monthly != nil, quota == nil || quota?.weekly != nil {
                QuotaSeparator()
            }

            if quota == nil || quota?.weekly != nil {
                MinimalUnifiedQuotaRow(
                    title: languageManager.tr("周"),
                    detail: quota?.weekly,
                    color: .kimiBlue,
                    isLoading: isLoading
                )
            }

            QuotaSeparator()

            MinimalUnifiedQuotaRow(
                title: languageManager.tr("5时"),
                detail: quota?.fiveHour,
                color: .orange,
                isLoading: isLoading
            )
        }
        .padding(.horizontal, 14)
    }
}

private struct MonthlyBreakdownRow: View {
    let quota: KimiQuota?

    var body: some View {
        HStack(spacing: 14) {
            LText("月度用量构成")
                .foregroundStyle(.kimiTextTertiary)
            Spacer()
            if let kimi = quota?.monthlyKimiPercentage {
                legend(title: "Kimi \(kimi)%", color: .kimiTextTertiary)
            }
            if let code = quota?.monthlyCodePercentage {
                legend(title: "Code \(code)%", color: .kimiBlue)
            }
        }
        .font(.system(size: 9, weight: .medium))
    }

    private func legend(title: String, color: Color) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(color)
                .frame(width: 7, height: 7)
            Text(title)
                .foregroundStyle(color)
        }
    }
}

private struct ClassicQuotaPeriod: View {
    let title: String
    let detail: QuotaDetail?
    let color: Color
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.kimiTextPrimary)
                .lineLimit(1)
                .frame(height: 18, alignment: .leading)

            QuotaPercentage(percentage: detail?.percentage, isLoading: isLoading, size: 28)
            QuotaProgress(percentage: detail?.percentage, color: color)

            QuotaResetText(detail: detail, allowsWrap: true)
                .frame(height: 28, alignment: .topLeading)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct MinimalUnifiedQuotaRow: View {
    let title: String
    let detail: QuotaDetail?
    let color: Color
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.kimiTextSecondary)
                .frame(width: 24, alignment: .leading)

            QuotaPercentage(percentage: detail?.percentage, isLoading: isLoading, size: 18)
                .frame(width: 48, alignment: .leading)

            QuotaProgress(percentage: detail?.percentage, color: color)

            QuotaResetText(detail: detail, allowsWrap: true)
                .frame(width: 112, alignment: .trailing)
        }
        .padding(.vertical, 10)
    }
}

private struct QuotaPercentage: View {
    let percentage: Int?
    let isLoading: Bool
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            if isLoading {
                LoadingRing()
                    .frame(width: size * 0.7, height: size * 0.7)
            } else {
                Text("\(percentage ?? 0)%")
                    .font(.system(size: size, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.kimiTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(minHeight: size + 4, alignment: .leading)
    }
}

private struct QuotaProgress: View {
    let percentage: Int?
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .frame(height: 3)
                    .foregroundStyle(Color.kimiTextPrimary.opacity(0.10))
                Capsule()
                    .frame(width: proxy.size.width * CGFloat(min(percentage ?? 0, 100)) / 100, height: 3)
                    .foregroundStyle(color)
            }
        }
        .frame(height: 3)
    }
}

private struct QuotaResetText: View {
    let detail: QuotaDetail?
    let allowsWrap: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(detail?.timeUntilReset.replacingOccurrences(of: "钟", with: "").replacingOccurrences(of: "后重置", with: "重置") ?? "--")
                .foregroundStyle(.kimiTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(1)
            if detail?.resetTime != nil, let resetText = detail?.resetTimeText {
                Text(resetText)
                    .foregroundStyle(.kimiTextTertiary)
                    .lineLimit(1)
            }
        }
        .font(.system(size: 10))
        .lineLimit(allowsWrap ? 2 : 1)
        .minimumScaleFactor(0.75)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct QuotaSeparator: View {
    var vertical = false

    var body: some View {
        Rectangle()
            .fill(Color.kimiTextPrimary.opacity(0.08))
            .frame(width: vertical ? 1 : nil, height: vertical ? nil : 1)
            .padding(.vertical, vertical ? 4 : 0)
    }
}
