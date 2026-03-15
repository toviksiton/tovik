import SwiftUI

// MARK: - SpatialMemoryTestView
// 4×4 grid, show pattern 1.5s, recall it.
// 4 rounds: 3→4→5→6 cells
// Score = (correct rounds / 4) × 100

struct SpatialMemoryTestView: View {
    var onComplete: (Double) -> Void

    private static let gridSize = 4
    private static let totalRounds = 4
    private static let cellsPerRound = [3, 4, 5, 6]
    private static let showDuration: TimeInterval = 1.5

    @State private var phase: Phase = .intro
    @State private var roundIndex = 0
    @State private var pattern: Set<Int> = []
    @State private var userSelection: Set<Int> = []
    @State private var correctRounds = 0
    @State private var feedbackPhase: FeedbackPhase = .none
    @State private var showingPattern = false

    enum Phase { case intro, showing, recalling, feedback, results }
    enum FeedbackPhase { case none, correct, wrong }

    var body: some View {
        ZStack {
            Color(hex: "#0E0C0A").ignoresSafeArea()

            VStack(spacing: 28) {
                header
                Spacer()

                switch phase {
                case .intro:    introContent
                case .showing:  gridView(phase: .showing)
                case .recalling: gridView(phase: .recalling)
                case .feedback: feedbackView
                case .results:  resultsContent
                }

                Spacer()

                if phase == .recalling { submitButton }
            }
            .padding(.horizontal, 32)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Sub-views

    private var header: some View {
        HStack {
            Text("זיכרון מרחבי")
                .font(.custom("PlayfairDisplay-Regular", size: 20))
                .foregroundColor(Color(hex: "#F5F0E8"))
            Spacer()
            if phase != .intro && phase != .results {
                Text("סיבוב \(roundIndex + 1)/\(Self.totalRounds)")
                    .font(.custom("DMMono-Regular", size: 16))
                    .foregroundColor(Color(hex: "#504540"))
            }
        }
        .padding(.top, 48)
    }

    private var introContent: some View {
        VStack(spacing: 24) {
            Text("זכור את התבנית. בחר את התאים הנכונים.")
                .font(.custom("PlayfairDisplay-Regular", size: 20))
                .foregroundColor(Color(hex: "#F5F0E8"))
                .multilineTextAlignment(.center)

            Text("התבנית תוצג ל-1.5 שניות")
                .font(.custom("DMMono-Regular", size: 14))
                .foregroundColor(Color(hex: "#504540"))

            Button(action: { haptic(.medium); startRound() }) {
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

    private func gridView(phase currentPhase: Phase) -> some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: Self.gridSize)

        return LazyVGrid(columns: cols, spacing: 8) {
            ForEach(0..<(Self.gridSize * Self.gridSize), id: \.self) { idx in
                cellView(idx: idx, phase: currentPhase)
            }
        }
        .padding(8)
        .background(Color(hex: "#141210"))
        .cornerRadius(16)
    }

    private func cellView(idx: Int, phase: Phase) -> some View {
        let isInPattern = pattern.contains(idx)
        let isSelected = userSelection.contains(idx)

        return RoundedRectangle(cornerRadius: 8)
            .fill(cellColor(idx: idx, phase: phase, isInPattern: isInPattern, isSelected: isSelected))
            .aspectRatio(1, contentMode: .fit)
            .onTapGesture {
                guard phase == .recalling else { return }
                haptic(.light)
                if userSelection.contains(idx) {
                    userSelection.remove(idx)
                } else {
                    userSelection.insert(idx)
                }
            }
    }

    private func cellColor(idx: Int, phase: Phase, isInPattern: Bool, isSelected: Bool) -> Color {
        switch phase {
        case .showing:
            return isInPattern ? Color(hex: "#C4622D") : Color(hex: "#1C1A18")
        case .recalling:
            return isSelected ? Color(hex: "#5B7FA6") : Color(hex: "#1C1A18")
        case .feedback:
            if isInPattern && isSelected { return Color(hex: "#4A7B5C") }  // correct
            if isInPattern && !isSelected { return Color(hex: "#8B2500") } // missed
            if !isInPattern && isSelected { return Color(hex: "#B8860B") } // false alarm
            return Color(hex: "#1C1A18")
        default:
            return Color(hex: "#1C1A18")
        }
    }

    private var feedbackView: some View {
        VStack(spacing: 16) {
            gridView(phase: .feedback)
            Text(feedbackPhase == .correct ? "✓ נכון!" : "✗ שגוי")
                .font(.custom("DMMono-Regular", size: 20))
                .foregroundColor(feedbackPhase == .correct ? Color(hex: "#4A7B5C") : Color(hex: "#8B2500"))
        }
    }

    private var submitButton: some View {
        Button(action: checkAnswer) {
            Text("בדוק")
                .font(.custom("PlayfairDisplay-Bold", size: 20))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color(hex: "#C4622D"))
                .cornerRadius(14)
        }
        .padding(.bottom, 48)
        .disabled(userSelection.isEmpty)
    }

    private var resultsContent: some View {
        VStack(spacing: 16) {
            let score = Double(correctRounds) / Double(Self.totalRounds) * 100
            Text("\(Int(score.rounded()))")
                .font(.custom("DMMono-Regular", size: 72))
                .foregroundColor(Color(hex: "#C4622D"))
            Text("ציון זיכרון מרחבי")
                .font(.custom("DMMono-Regular", size: 16))
                .foregroundColor(Color(hex: "#504540"))

            Button(action: {
                haptic(.medium)
                let score = Double(correctRounds) / Double(Self.totalRounds) * 100
                onComplete(score)
            }) {
                Text("סיים")
                    .font(.custom("PlayfairDisplay-Bold", size: 20))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(hex: "#C4622D"))
                    .cornerRadius(14)
            }
        }
    }

    // MARK: - Logic

    private func startRound() {
        userSelection = []
        let cellCount = Self.cellsPerRound[roundIndex]
        var indices = Set<Int>()
        while indices.count < cellCount {
            indices.insert(Int.random(in: 0..<(Self.gridSize * Self.gridSize)))
        }
        pattern = indices
        phase = .showing
        haptic(.light)

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.showDuration) {
            phase = .recalling
        }
    }

    private func checkAnswer() {
        haptic(.medium)
        let isCorrect = userSelection == pattern
        if isCorrect { correctRounds += 1 }
        feedbackPhase = isCorrect ? .correct : .wrong
        phase = .feedback

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            roundIndex += 1
            if roundIndex >= Self.totalRounds {
                phase = .results
            } else {
                startRound()
            }
        }
    }
}
