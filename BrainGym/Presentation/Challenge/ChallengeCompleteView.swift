import SwiftUI

// MARK: - ChallengeCompleteView
// Celebration screen shown after completing a challenge.

struct ChallengeCompleteView: View {
    let challenge: Challenge
    let streak: Int
    var onDismiss: () -> Void

    @State private var show = false

    var body: some View {
        ZStack {
            Color(hex: "#0E0C0A").ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Type badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(challenge.type.color)
                        .frame(width: 10, height: 10)
                    Text(challenge.type.displayNameHebrew)
                        .font(.mono(14, weight: "Medium"))
                        .foregroundColor(challenge.type.color)
                }
                .opacity(show ? 1 : 0)
                .animation(.easeOut(duration: 0.4), value: show)

                // Big checkmark
                ZStack {
                    Circle()
                        .fill(challenge.type.color.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(challenge.type.color)
                }
                .scaleEffect(show ? 1 : 0.4)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: show)

                // Title
                Text("כל הכבוד!")
                    .font(.display(36, weight: "Bold"))
                    .foregroundColor(Color(hex: "#F5F0E8"))
                    .opacity(show ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: show)

                // Streak
                VStack(spacing: 4) {
                    Text("\(streak)")
                        .font(.mono(48, weight: "Regular"))
                        .foregroundColor(challenge.type.color)
                    Text("אתגרים רצופים")
                        .font(.mono(14))
                        .foregroundColor(Color(hex: "#504540"))
                }
                .opacity(show ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: show)

                // Research note if present
                if let note = challenge.researchNote {
                    Text(note)
                        .font(.mono(12))
                        .foregroundColor(Color(hex: "#504540"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(show ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.4), value: show)
                }

                Spacer()

                Button(action: {
                    haptic(.medium)
                    onDismiss()
                }) {
                    Text("חזור")
                        .font(.display(20, weight: "Bold"))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(challenge.type.color)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .opacity(show ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.5), value: show)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            haptic(.heavy)
            show = true
        }
    }
}
