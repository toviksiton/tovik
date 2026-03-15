import SwiftUI

// MARK: - AssessmentBattery
// Orchestrates all 4 tests and aggregates into a CognitiveScore.

@Observable
final class AssessmentBattery {

    enum Step {
        case intro
        case reactionTime
        case nBack
        case stroop
        case spatialMemory
        case results
    }

    var currentStep: Step = .intro
    var reactionTimeScore: Double = 0
    var nBackScore: Double = 0
    var stroopScore: Double = 0
    var spatialMemoryScore: Double = 0

    var overallScore: Double {
        (reactionTimeScore + nBackScore + stroopScore + spatialMemoryScore) / 4.0
    }

    var isComplete: Bool { currentStep == .results }

    func advance(score: Double) {
        switch currentStep {
        case .intro:
            currentStep = .reactionTime
        case .reactionTime:
            reactionTimeScore = score
            currentStep = .nBack
        case .nBack:
            nBackScore = score
            currentStep = .stroop
        case .stroop:
            stroopScore = score
            currentStep = .spatialMemory
        case .spatialMemory:
            spatialMemoryScore = score
            currentStep = .results
        case .results:
            break
        }
    }

    func toCognitiveScore() -> CognitiveScore {
        CognitiveScore(
            reactionTimeScore: reactionTimeScore,
            nBackScore: nBackScore,
            stroopScore: stroopScore,
            spatialMemoryScore: spatialMemoryScore
        )
    }
}

// MARK: - AssessmentView (orchestrator UI)

struct AssessmentView: View {
    @State private var battery = AssessmentBattery()
    var onComplete: (CognitiveScore) -> Void

    var body: some View {
        ZStack {
            Color(hex: "#0E0C0A").ignoresSafeArea()

            switch battery.currentStep {
            case .intro:
                AssessmentIntroView { battery.advance(score: 0) }

            case .reactionTime:
                ReactionTimeTestView { score in battery.advance(score: score) }

            case .nBack:
                NBackTestView { score in battery.advance(score: score) }

            case .stroop:
                StroopTestView { score in battery.advance(score: score) }

            case .spatialMemory:
                SpatialMemoryTestView { score in battery.advance(score: score) }

            case .results:
                AssessmentResultsView(battery: battery) {
                    onComplete(battery.toCognitiveScore())
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

// MARK: - Intro Screen

private struct AssessmentIntroView: View {
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Text("בדיקת כושר מוחי")
                    .font(.custom("PlayfairDisplay-Bold", size: 32))
                    .foregroundColor(Color(hex: "#F5F0E8"))
                    .multilineTextAlignment(.center)

                Text("4 בדיקות קצרות · כ-5 דקות")
                    .font(.custom("DMMono-Regular", size: 16))
                    .foregroundColor(Color(hex: "#504540"))
            }

            VStack(alignment: .leading, spacing: 12) {
                testRow(icon: "⚡", name: "זמן תגובה", desc: "מהירות עיבוד")
                testRow(icon: "🧠", name: "N-Back", desc: "זיכרון עבודה")
                testRow(icon: "🎨", name: "סטרופ", desc: "שליטה עיכובית")
                testRow(icon: "🔲", name: "זיכרון מרחבי", desc: "זיכרון ויזואלי")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: { haptic(.medium); onStart() }) {
                Text("התחל")
                    .font(.custom("PlayfairDisplay-Bold", size: 20))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(hex: "#C4622D"))
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    private func testRow(icon: String, name: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Text(icon).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.custom("PlayfairDisplay-Regular", size: 16))
                    .foregroundColor(Color(hex: "#F5F0E8"))
                Text(desc)
                    .font(.custom("DMMono-Regular", size: 12))
                    .foregroundColor(Color(hex: "#504540"))
            }
        }
    }
}

// MARK: - Results Screen

private struct AssessmentResultsView: View {
    let battery: AssessmentBattery
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("ציון כושר מוחי")
                .font(.custom("PlayfairDisplay-Regular", size: 22))
                .foregroundColor(Color(hex: "#504540"))

            Text("\(Int(battery.overallScore.rounded()))")
                .font(.custom("DMMono-Regular", size: 80))
                .foregroundColor(Color(hex: "#C4622D"))

            VStack(spacing: 12) {
                scoreRow("זמן תגובה",   battery.reactionTimeScore)
                scoreRow("N-Back",        battery.nBackScore)
                scoreRow("סטרופ",         battery.stroopScore)
                scoreRow("זיכרון מרחבי", battery.spatialMemoryScore)
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: { haptic(.medium); onContinue() }) {
                Text("המשך")
                    .font(.custom("PlayfairDisplay-Bold", size: 20))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(hex: "#C4622D"))
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    private func scoreRow(_ label: String, _ score: Double) -> some View {
        HStack {
            Text(label)
                .font(.custom("DMMono-Regular", size: 14))
                .foregroundColor(Color(hex: "#504540"))
            Spacer()
            Text("\(Int(score.rounded()))")
                .font(.custom("DMMono-Regular", size: 14))
                .foregroundColor(Color(hex: "#F5F0E8"))
        }
    }
}

// MARK: - Haptic helper (shared)

func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}
