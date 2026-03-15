import SwiftUI
import SwiftData
import Charts

// MARK: - ProgressView

struct BrainGymProgressView: View {
    @Query(sort: \CognitiveScore.recordedAt, order: .reverse) private var scores: [CognitiveScore]
    @Query(sort: \Challenge.completedAt, order: .reverse)      private var challenges: [Challenge]

    var body: some View {
        ZStack {
            Color(hex: "#0E0C0A").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    header
                    overallScoreCard
                    subScoresCard
                    challengeHistoryCard
                    typeDistributionCard
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 80)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Sub-views

    private var header: some View {
        HStack {
            Text("התקדמות")
                .font(.display(28, weight: "Bold"))
                .foregroundColor(Color(hex: "#F5F0E8"))
            Spacer()
        }
        .padding(.top, 56)
    }

    private var overallScoreCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("ציון מוחי")
                    .font(.mono(14))
                    .foregroundColor(Color(hex: "#504540"))
                Spacer()
                if let latest = scores.first {
                    Text(latestDateString(latest.recordedAt))
                        .font(.mono(11))
                        .foregroundColor(Color(hex: "#504540"))
                }
            }

            if let latest = scores.first {
                HStack(alignment: .bottom, spacing: 8) {
                    Text("\(latest.overallInt)")
                        .font(.mono(64, weight: "Regular"))
                        .foregroundColor(Color(hex: "#C4622D"))
                    Text("/ 100")
                        .font(.mono(20))
                        .foregroundColor(Color(hex: "#504540"))
                        .padding(.bottom, 10)
                }

                // Trend sparkline
                if scores.count > 1 {
                    let data = scores.prefix(7).map { $0.overallInt }.reversed()
                    Chart {
                        ForEach(Array(data.enumerated()), id: \.offset) { i, score in
                            LineMark(x: .value("n", i), y: .value("ציון", score))
                                .foregroundStyle(Color(hex: "#C4622D"))
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYScale(domain: 0...100)
                    .frame(height: 60)
                }
            } else {
                Text("עדיין אין בדיקות")
                    .font(.mono(14))
                    .foregroundColor(Color(hex: "#504540"))
                    .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(Color(hex: "#141210"))
        .cornerRadius(16)
    }

    private var subScoresCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("תת-ציונים")
                .font(.mono(14))
                .foregroundColor(Color(hex: "#504540"))

            if let latest = scores.first {
                subScoreRow("זמן תגובה",   latest.reactionTimeScore, color: "#5B7FA6")
                subScoreRow("N-Back",        latest.nBackScore,        color: "#C4622D")
                subScoreRow("סטרופ",         latest.stroopScore,       color: "#4A7B5C")
                subScoreRow("זיכרון מרחבי", latest.spatialMemoryScore, color: "#B8860B")
            } else {
                Text("נתונים יופיעו אחרי הבדיקה הראשונה")
                    .font(.mono(12))
                    .foregroundColor(Color(hex: "#504540").opacity(0.6))
                    .padding(.vertical, 8)
            }
        }
        .padding(20)
        .background(Color(hex: "#141210"))
        .cornerRadius(16)
    }

    private func subScoreRow(_ label: String, _ score: Double, color: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.mono(13))
                    .foregroundColor(Color(hex: "#F5F0E8"))
                Spacer()
                Text("\(Int(score.rounded()))")
                    .font(.mono(13, weight: "Medium"))
                    .foregroundColor(Color(hex: color))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#1C1A18"))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: color))
                        .frame(width: geo.size.width * score / 100, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private var challengeHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("היסטוריית אתגרים")
                .font(.mono(14))
                .foregroundColor(Color(hex: "#504540"))

            let completed = challenges.filter { $0.completedAt != nil }.prefix(10)
            if completed.isEmpty {
                Text("עדיין אין אתגרים שהושלמו")
                    .font(.mono(12))
                    .foregroundColor(Color(hex: "#504540").opacity(0.6))
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(completed), id: \.id) { ch in
                    HStack(spacing: 12) {
                        Circle().fill(ch.type.color).frame(width: 8, height: 8)
                        Text(ch.type.displayNameHebrew)
                            .font(.mono(12, weight: "Medium"))
                            .foregroundColor(ch.type.color)
                        Spacer()
                        Text(shortDate(ch.completedAt))
                            .font(.mono(11))
                            .foregroundColor(Color(hex: "#504540"))
                    }
                }
            }
        }
        .padding(20)
        .background(Color(hex: "#141210"))
        .cornerRadius(16)
    }

    private var typeDistributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("סוגי אתגרים")
                .font(.mono(14))
                .foregroundColor(Color(hex: "#504540"))

            let counts = typeCounts()
            if counts.isEmpty {
                Text("נתונים יופיעו אחרי האתגר הראשון")
                    .font(.mono(12))
                    .foregroundColor(Color(hex: "#504540").opacity(0.6))
                    .padding(.vertical, 8)
            } else {
                Chart {
                    ForEach(counts, id: \.type) { item in
                        BarMark(
                            x: .value("count", item.count),
                            y: .value("type", item.type.displayNameHebrew)
                        )
                        .foregroundStyle(item.type.color)
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(counts.count) * 28)
            }
        }
        .padding(20)
        .background(Color(hex: "#141210"))
        .cornerRadius(16)
    }

    // MARK: - Helpers

    private func typeCounts() -> [(type: ChallengeType, count: Int)] {
        let completed = challenges.filter { $0.completedAt != nil }
        var counts = [ChallengeType: Int]()
        for ch in completed { counts[ch.type, default: 0] += 1 }
        return counts.map { ($0.key, $0.value) }.sorted { $0.count > $1.count }
    }

    private func shortDate(_ date: Date?) -> String {
        guard let d = date else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "dd/MM"
        return fmt.string(from: d)
    }

    private func latestDateString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "dd/MM/yy"
        return fmt.string(from: date)
    }
}
