import SwiftUI

// MARK: - ReactionTimeTestView
// 5 rounds. Random delay 1.5–4s. Tap the green circle.
// Score = clamp(100 - (avgMs - 150) / 4, 0, 100)

struct ReactionTimeTestView: View {
    var onComplete: (Double) -> Void

    @State private var phase: Phase = .waiting
    @State private var roundNumber = 0
    @State private var reactionTimes: [Double] = []
    @State private var circleAppearTime: Date?
    @State private var tooEarly = false
    @State private var showResult: Double? = nil

    private let totalRounds = 5

    enum Phase {
        case waiting    // showing "get ready" / countdown
        case ready      // green circle showing
        case tooEarly   // tapped before green
        case done       // all rounds finished
    }

    var body: some View {
        ZStack {
            Color(hex: "#0E0C0A").ignoresSafeArea()

            VStack(spacing: 32) {
                progressHeader

                Spacer()

                centerContent

                Spacer()

                instructionText
            }
            .padding(.horizontal, 32)
        }
        .onAppear { startRound() }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Sub-views

    private var progressHeader: some View {
        HStack {
            Text("זמן תגובה")
                .font(.custom("PlayfairDisplay-Regular", size: 20))
                .foregroundColor(Color(hex: "#F5F0E8"))
            Spacer()
            Text("\(roundNumber + 1)/\(totalRounds)")
                .font(.custom("DMMono-Regular", size: 16))
                .foregroundColor(Color(hex: "#504540"))
        }
        .padding(.top, 48)
    }

    private var centerContent: some View {
        Group {
            switch phase {
            case .waiting:
                Circle()
                    .fill(Color(hex: "#141210"))
                    .frame(width: 160, height: 160)
                    .overlay(
                        Text("המתן...")
                            .font(.custom("DMMono-Regular", size: 18))
                            .foregroundColor(Color(hex: "#504540"))
                    )

            case .ready:
                Button(action: handleTap) {
                    Circle()
                        .fill(Color(hex: "#4A7B5C"))
                        .frame(width: 160, height: 160)
                        .overlay(
                            Text("הקש!")
                                .font(.custom("PlayfairDisplay-Bold", size: 24))
                                .foregroundColor(.white)
                        )
                }

            case .tooEarly:
                Circle()
                    .fill(Color(hex: "#8B2500"))
                    .frame(width: 160, height: 160)
                    .overlay(
                        Text("מוקדם מדי")
                            .font(.custom("DMMono-Regular", size: 16))
                            .foregroundColor(.white)
                    )

            case .done:
                if let score = showResult {
                    VStack(spacing: 8) {
                        Text("\(Int(score.rounded()))")
                            .font(.custom("DMMono-Regular", size: 72))
                            .foregroundColor(Color(hex: "#C4622D"))
                        Text("ציון")
                            .font(.custom("DMMono-Regular", size: 16))
                            .foregroundColor(Color(hex: "#504540"))
                    }
                }
            }
        }
    }

    private var instructionText: some View {
        Group {
            if phase == .waiting {
                Text("הקש על המעגל כשיהפוך לירוק")
                    .font(.custom("DMMono-Regular", size: 14))
                    .foregroundColor(Color(hex: "#504540"))
                    .multilineTextAlignment(.center)
            } else if phase == .done {
                Button(action: finish) {
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
        .padding(.bottom, 48)
    }

    // MARK: - Logic

    private func startRound() {
        guard roundNumber < totalRounds else {
            finalise()
            return
        }
        phase = .waiting
        tooEarly = false
        let delay = Double.random(in: 1.5...4.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard phase == .waiting else { return }
            phase = .ready
            circleAppearTime = Date()
            haptic(.light)
        }
    }

    private func handleTap() {
        guard phase == .ready, let appeared = circleAppearTime else { return }
        let rt = Date().timeIntervalSince(appeared) * 1000 // ms
        reactionTimes.append(rt)
        haptic(.medium)
        roundNumber += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            startRound()
        }
    }

    private func tappedTooEarly() {
        phase = .tooEarly
        reactionTimes.append(1000) // penalise
        haptic(.heavy)
        roundNumber += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            startRound()
        }
    }

    private func finalise() {
        let avg = reactionTimes.isEmpty ? 500 : reactionTimes.reduce(0, +) / Double(reactionTimes.count)
        let score = max(0, min(100, 100 - (avg - 150) / 4))
        showResult = score
        phase = .done
    }

    private func finish() {
        haptic(.medium)
        onComplete(showResult ?? 0)
    }
}
