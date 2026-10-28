import SwiftUI

struct QuotaRhythmDay: Identifiable {
    let date: Date
    let weeklyLimit: Double
    let monthlyLimit: Double?
    let isToday: Bool

    var id: Date { date }
}

enum QuotaRhythm {
    static func todayWeeklyLimit(for quota: KimiQuota?, now: Date = Date(), calendar: Calendar = .current) -> Int? {
        guard let resetTime = quota?.weekly?.resetTime,
              let startTime = calendar.date(byAdding: .day, value: -7, to: resetTime),
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(QuotaRhythm.weekday(day.date))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.kimiTextPrimary)
                Text(QuotaRhythm.dateText(day.date))
                    .font(.system(size: 8))
                    .foregroundStyle(.kimiTextTertiary)
            }
            RhythmValueLine(label: LanguageManager.tr("周"), value: day.weeklyLimit)
            RhythmValueLine(label: LanguageManager.tr("月"), value: day.monthlyLimit)
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
        .padding(.bottom, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .overlay(alignment: .top) {
            Capsule()
                .fill(color)
                .frame(height: 2)
                .padding(.horizontal, 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.18), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: day.isToday ? Color.black.opacity(0.14) : .clear, radius: 4, x: 0, y: 2)
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

    var body: some View {
        VStack(spacing: 3) {
            Text("\(QuotaRhythm.shortWeekday(day.date))\(day.date.formatted(.dateTime.day(.twoDigits)))")
                .font(.system(size: 8))
                .foregroundStyle(.kimiTextTertiary)
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
        .background(Color.clear)
        .overlay(alignment: .top) {
            Capsule()
                .fill(color)
                .frame(height: 2)
                .padding(.horizontal, 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: day.isToday ? Color.black.opacity(0.12) : .clear, radius: 3, x: 0, y: 2)
    }
}

extension QuotaDetail {
    var resetWithDateText: String {
        guard resetTime != nil else { return timeUntilReset }
        return "\(resetTimeText)\n\(timeUntilReset)"
    }
}
