import SwiftUI

// MARK: - StroopTestView
// 10 Hebrew color words shown in mismatching ink colors.
// User judges: does WORD MEANING match INK COLOR?
// Score = (correct / 10) × 100

struct StroopTestView: View {
    var onComplete: (Double) -> Void

    private static let totalTrials = 10

    // Hebrew color word + its Hebrew name for display
    private struct ColorWord {
        let word: String      // displayed text (Hebrew color name)
        let wordColor: Color  // ink color (always different from meaning)
        let meaningMatchesInk: Bool
    }

    @State private var trials: [ColorWord] = []
    @State private var trialIndex = 0
    @State private var correctCount = 0
    @State private var phase: Phase = .intro
    @State private var feedbackColor: Color? = nil

    enum Phase { case intro, running, results }

    // Hebrew color definitions
    private static let colorNames: [(name: String, color: Color)] = [
        ("אדום",  Color(hex: "#E53935")),
        ("כחול",  Color(hex: "#1E88E5")),
        ("ירוק",  Color(hex: "#43A047")),
        ("צהוב",  Color(hex: "#FDD835"))
    ]

    var body: some View {
        ZStack {
            Color(hex: "#0E0C0A").ignoresSafeArea()

            VStack(spacing: 32) {
                header
                Spacer()

                switch phase {
                case .intro:   introContent
                case .running: trialContent
                case .results: resultsContent
                }

                Spacer()

                if phase == .running { answerButtons }
            }
            .padding(.horizontal, 32)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Sub-views

    private var header: some View {
        HStack {
            Text("בדיקת סטרופ")
                .font(.custom("PlayfairDisplay-Regular", size: 20))
                .foregroundColor(Color(hex: "#F5F0E8"))
            Spacer()
            if phase == .running {
                Text("\(trialIndex + 1)/\(Self.totalTrials)")
                    .font(.custom("DMMono-Regular", size: 16))
                    .foregroundColor(Color(hex: "#504540"))
            }
        }
        .padding(.top, 48)
    }

    private var introContent: some View {
        VStack(spacing: 24) {
            Text("האם מובן המילה תואם את צבע הדיו?")
                .font(.custom("PlayfairDisplay-Regular", size: 22))
                .foregroundColor(Color(hex: "#F5F0E8"))
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                examplePill("כן", color: Color(hex: "#4A7B5C"))
                examplePill("לא", color: Color(hex: "#8B2500"))
            }

            Button(action: { haptic(.medium); buildTrials(); phase = .running }) {
                Text("התחל")
                    .font(.custom("PlayfairDisplay-Bold", size: 20))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(hex: "#C4622D"))
                    .cornerRadius(14)
            }
        }
    }

    private var trialContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(feedbackColor ?? Color(hex: "#141210"))
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .animation(.easeInOut(duration: 0.15), value: feedbackColor)

            if trialIndex < trials.count {
                Text(trials[trialIndex].word)
                    .font(.custom("PlayfairDisplay-Bold", size: 56))
                    .foregroundColor(trials[trialIndex].wordColor)
            }
        }
    }

    private var answerButtons: some View {
        HStack(spacing: 16) {
            answerButton("כן", isYes: true)
            answerButton("לא", isYes: false)
        }
        .padding(.bottom, 48)
    }

    private var resultsContent: some View {
        VStack(spacing: 16) {
            let score = Double(correctCount) / Double(Self.totalTrials) * 100
            Text("\(Int(score.rounded()))")
                .font(.custom("DMMono-Regular", size: 72))
                .foregroundColor(Color(hex: "#C4622D"))
            Text("ציון סטרופ")
                .font(.custom("DMMono-Regular", size: 16))
                .foregroundColor(Color(hex: "#504540"))

            Button(action: {
                haptic(.medium)
                let score = Double(correctCount) / Double(Self.totalTrials) * 100
                onComplete(score)
            }) {
                Text("המשך")
                    .font(.custom("PlayfairDisplay-Bold", size: 20))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(hex: "#C4622D"))
                    .cornerRadius(14)
            }
        }
    }

    // MARK: - Helpers

    private func examplePill(_ label: String, color: Color) -> some View {
        Text(label)
            .font(.custom("DMMono-Regular", size: 16))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(color)
            .cornerRadius(10)
    }

    private func answerButton(_ label: String, isYes: Bool) -> some View {
        Button(action: { handleAnswer(isYes: isYes) }) {
            Text(label)
                .font(.custom("PlayfairDisplay-Bold", size: 24))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(isYes ? Color(hex: "#4A7B5C") : Color(hex: "#8B2500"))
                .cornerRadius(16)
        }
    }

    // MARK: - Logic

    private func buildTrials() {
        var result = [ColorWord]()
        let colors = Self.colorNames

        for _ in 0..<Self.totalTrials {
            // Pick word and ink — make sure they differ ~70% of the time
            let wordIdx = Int.random(in: 0..<colors.count)
            var inkIdx: Int
            let shouldMismatch = Double.random(in: 0...1) > 0.3
            if shouldMismatch {
                var idx: Int
                repeat { idx = Int.random(in: 0..<colors.count) } while idx == wordIdx
                inkIdx = idx
            } else {
                inkIdx = wordIdx
            }
            result.append(ColorWord(
                word: colors[wordIdx].name,
                wordColor: colors[inkIdx].color,
                meaningMatchesInk: wordIdx == inkIdx
            ))
        }
        trials = result
    }

    private func handleAnswer(isYes: Bool) {
        guard trialIndex < trials.count else { return }
        let correct = isYes == trials[trialIndex].meaningMatchesInk
        if correct {
            correctCount += 1
            feedbackColor = Color(hex: "#4A7B5C")
        } else {
            feedbackColor = Color(hex: "#8B2500")
        }
        haptic(correct ? .medium : .heavy)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            feedbackColor = nil
            trialIndex += 1
            if trialIndex >= Self.totalTrials { phase = .results }
        }
    }
}
