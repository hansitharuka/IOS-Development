import SwiftUI

struct ContentView: View {
    // Game state
    @State private var timeRemaining: Int = 10
    @State private var score: Int = 0
    @State private var isRunning: Bool = false
    @State private var showResult: Bool = false

    // Persist best score across launches
    @AppStorage("bestScore") private var bestScore: Int = 0

    // Timer
    @State private var timer: Timer? = nil

    var body: some View {
        ZStack {
            // Background
            Color(.black)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                // Title and score
                VStack(spacing: 8) {
                    Text("Tap Frenzy")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white.opacity(0.9))

                    Text("SCORE")
                        .font(.headline.smallCaps())
                        .foregroundStyle(.white.opacity(0.6))

                    Text("\(score)")
                        .font(.system(size: 64, weight: .heavy, design: .rounded))
                        .foregroundStyle(.green)
                        .monospacedDigit()
                }

                // Progress bar / time remaining
                VStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 10)
                        GeometryReader { geo in
                            let width = geo.size.width
                            let progress = CGFloat(timeRemaining) / 10.0
                            Capsule()
                                .fill(Color.green)
                                .frame(width: max(0, width * progress), height: 10)
                                .animation(.easeInOut(duration: 0.2), value: timeRemaining)
                        }
                        .frame(height: 10)
                    }

                    Text(isRunning ? "\(timeRemaining)s left" : (score == 0 ? "tap to start" : "time's up — tap to try again"))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .monospacedDigit()
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 16)

                // Big circular TAP button
                Button(action: handleTap) {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 220, height: 220)
                            .shadow(color: .green.opacity(0.5), radius: 24, x: 0, y: 12)

                        Text("TAP")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundStyle(Color.black)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isRunning == false && score > 0 && showResult == false) // disabled only while we wait to show result sheet
                .accessibilityLabel(isRunning ? "Tap to score" : "Start game")

                Spacer()
            }
        }
        .sheet(isPresented: $showResult, onDismiss: resetForNextRound) {
            ResultView(score: score, bestScore: bestScore, onPlayAgain: {
                showResult = false
                startGame()
            })
            .presentationDetents([.fraction(0.35)])
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
        }
        .onDisappear { timer?.invalidate(); timer = nil }
    }

    // MARK: - Actions

    private func handleTap() {
        if !isRunning {
            // Start a new game on first tap
            startGame()
            return
        }
        // Count taps only while running
        score += 1
    }

    private func startGame() {
        score = 0
        timeRemaining = 10
        isRunning = true
        showResult = false

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
            if timeRemaining == 0 {
                endGame()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func endGame() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        if score > bestScore { bestScore = score }
        // Show result
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showResult = true
        }
    }

    private func resetForNextRound() {
        // Keep last score visible in the main view text, allow immediate restart on tap
        isRunning = false
        timeRemaining = 10
    }
}

private struct ResultView: View {
    let score: Int
    let bestScore: Int
    let onPlayAgain: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            Text("Time's up!")
                .font(.title.bold())

            HStack(spacing: 24) {
                VStack {
                    Text("SCORE")
                        .font(.caption.smallCaps())
                        .foregroundStyle(.secondary)
                    Text("\(score)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                }
                VStack {
                    Text("BEST")
                        .font(.caption.smallCaps())
                        .foregroundStyle(.secondary)
                    Text("\(bestScore)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                }
            }

            Button(action: onPlayAgain) {
                Text("Try Again")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.black)
            }
            .padding(.top, 8)
        }
        .padding(24)
    }
}

#Preview {
    ContentView()
}
