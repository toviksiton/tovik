import SwiftUI
import SwiftData
import Charts

// MARK: - HomeView

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Challenge.completedAt, order: .reverse) private var challenges: [Challenge]
    @Query(sort: \CognitiveScore.recordedAt, order: .reverse) private var scores: [CognitiveScore]

    @State var viewModel: HomeViewModel

    var body: some View {
        ZStack {
            Color(hex: "#0E0C0A").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    topBar
                    streakCard
                    mainCTA
                    recentChallengesSection
                    weeklyTrendSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 80)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear { viewModel.loadData(challenges: challenges, scores: scores) }
        .onChange(of: challenges.count) { _, _ in viewModel.loadData(challenges: challenges, scores: scores) }
        // Overlays
        .fullScreenCover(isPresented: $viewModel.showOverlay) {
            if let ch = viewModel.currentChallenge {
                ChallengeOverlayView(
                    challenge: ch,
                    mandatoryMode: false,
                    onBegin: { viewModel.beginChallenge() },
                    onSkip:  { viewModel.skipChallenge() }
                )
            }
        }
        .fullScreenCover(isPresented: $viewModel.showActive) {
            if let ch = viewModel.currentChallenge {
                ActiveChallengeView(
                    challenge: ch,
                    onComplete: { modelContext.insert(ch); viewModel.completeChallenge() },
                    onSkip:    { viewModel.skipChallenge() }
                )
            }
        }
        .fullScreenCover(isPresented: $viewModel.showComplete) {
            if let ch = viewModel.currentChallenge {
                ChallengeCompleteView(
                    challenge: ch,
                    streak: viewModel.streak,
                    onDismiss: { viewModel.dismissComplete() }
                )
            }
        }
    }

    // MARK: - Sub-views

    private var topBar: some View {
        HStack {
            Text("Brain Gym")
                .font(.display(28, weight: "Bold"))
                .foregroundColor(Color(hex: "#F5F0E8"))

            Spacer()

            // Cognitive score badge
            if viewModel.latestCognitiveScore > 0 {
                VStack(spacing: 0) {
                    Text("\(viewModel.latestCognitiveScore)")
                        .font(.mono(24, weight: "Regular"))
                        .foregroundColor(Color(hex: "#C4622D"))
                    Text("ציון")
                        .font(.mono(10))
                        .foregroundColor(Color(hex: "#504540"))
                }
                .padding(12)
                .background(Color(hex: "#141210"))
                .cornerRadius(12)
            }
        }
        .padding(.top, 56)
    }

    private var streakCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.streak)")
                    .font(.mono(36, weight: "Regular"))
                    .foregroundColor(Color(hex: "#C4622D"))
                Text("אתגרים רצופים")
                    .font(.mono(13))
                    .foregroundColor(Color(hex: "#504540"))
            }
            Spacer()
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "#C4622D").opacity(viewModel.streak > 0 ? 1 : 0.2))
        }
        .padding(20)
        .background(Color(hex: "#141210"))
        .cornerRadius(16)
    }

    private var mainCTA: some View {
        Button(action: {
            haptic(.heavy)
            viewModel.requestChallenge(cognitiveScore: viewModel.latestCognitiveScore)
        }) {
            HStack {
                Text("אתגר עכשיו")
                    .font(.display(24, weight: "Bold"))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 22)
            .background(Color(hex: "#C4622D"))
            .cornerRadius(18)
        }
    }

    private var recentChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("אתגרים אחרונים")
                .font(.mono(14))
                .foregroundColor(Color(hex: "#504540"))

            if viewModel.recentChallenges.isEmpty {
                Text("עדיין אין אתגרים — בוא נתחיל!")
                    .font(.mono(13))
                    .foregroundColor(Color(hex: "#504540").opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color(hex: "#141210"))
                    .cornerRadius(12)
            } else {
                ForEach(viewModel.recentChallenges, id: \.id) { ch in
                    recentChallengeRow(ch)
                }
            }
        }
    }

    private func recentChallengeRow(_ ch: Challenge) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(ch.type.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(ch.type.displayNameHebrew)
                    .font(.mono(13, weight: "Medium"))
                    .foregroundColor(ch.type.color)
                Text(ch.prompt)
                    .font(.display(14, weight: "Regular"))
                    .foregroundColor(Color(hex: "#F5F0E8"))
                    .lineLimit(2)
            }

            Spacer()

            if let date = ch.completedAt {
                Text(relativeTime(date))
                    .font(.mono(11))
                    .foregroundColor(Color(hex: "#504540"))
            }
        }
        .padding(14)
        .background(Color(hex: "#141210"))
        .cornerRadius(12)
    }

    private var weeklyTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("מגמת שבוע")
                .font(.mono(14))
                .foregroundColor(Color(hex: "#504540"))

            if viewModel.weeklyScores.isEmpty {
                Text("נתונים יופיעו אחרי הבדיקה הראשונה")
                    .font(.mono(12))
                    .foregroundColor(Color(hex: "#504540").opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color(hex: "#141210"))
                    .cornerRadius(12)
            } else {
                Chart {
                    ForEach(Array(viewModel.weeklyScores.enumerated()), id: \.offset) { i, score in
                        LineMark(
                            x: .value("יום", i),
                            y: .value("ציון", score)
                        )
                        .foregroundStyle(Color(hex: "#C4622D"))
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("יום", i),
                            y: .value("ציון", score)
                        )
                        .foregroundStyle(Color(hex: "#C4622D").opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartXAxis(.hidden)
                .chartYScale(domain: 0...100)
                .frame(height: 100)
                .padding(16)
                .background(Color(hex: "#141210"))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Helpers

    private func relativeTime(_ date: Date) -> String {
        let mins = Int(Date().timeIntervalSince(date) / 60)
        if mins < 60 { return "לפני \(mins) דק'" }
        let hrs = mins / 60
        if hrs < 24 { return "לפני \(hrs) ש'" }
        return "אתמול"
    }
}
