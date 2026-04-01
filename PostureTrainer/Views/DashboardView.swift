import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: PostureStore
    @State private var showingLogSheet = false
    @State private var showingMicroChecks = false
    @State private var showingActiveSession = false
    @State private var showStreakCelebration = false
    @State private var previousSessionCount = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if !store.programStarted {
                        startProgramCard
                    } else {
                        if store.isSessionDueToday {
                            streakNudgeBanner
                        }
                        currentWeekCard
                        streakCard
                        weekProgressCard
                        quickActionsCard
                    }
                }
                .padding()
            }
            .navigationTitle("Posture Trainer")
            .sheet(isPresented: $showingLogSheet) {
                LogSessionSheet()
            }
            .sheet(isPresented: $showingMicroChecks) {
                MicroCheckSheet()
            }
            .fullScreenCover(isPresented: $showingActiveSession) {
                ActiveSessionView()
            }
            .overlay {
                if showStreakCelebration {
                    StreakCelebrationOverlay(
                        streak: store.streakInfo.currentStreak,
                        isPresented: $showStreakCelebration
                    )
                }
            }
            .onAppear {
                previousSessionCount = store.sessions.count
            }
            .onChange(of: store.sessions.count) { oldCount, newCount in
                if newCount > oldCount, store.streakInfo.currentStreak > 1 {
                    withAnimation {
                        showStreakCelebration = true
                    }
                }
                previousSessionCount = newCount
            }
        }
    }

    // MARK: - Streak Nudge Banner

    private var streakNudgeBanner: some View {
        let streak = store.streakInfo.currentStreak
        return Button {
            showingActiveSession = true
        } label: {
            HStack(spacing: 14) {
                StreakFlameView(streak: streak)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    if streak > 0 {
                        Text("Don't break your \(streak)-day streak!")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                    } else {
                        Text("Start a new streak today!")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                    }

                    Text("Tap to start today's session")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.orange.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.orange.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Start Program

    private var startProgramCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.stand")
                .font(.system(size: 60))
                .foregroundStyle(.primary)

            Text("Welcome to Posture Trainer")
                .font(.title2.bold())

            Text("A customizable program to improve your posture using a posture brace, with gradual progression from daily use to occasional reminders.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                store.startProgram()
            } label: {
                Text("Start Program")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Current Week

    private var currentWeekCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if store.currentScheduleWeek != nil {
                        Text("Week \(store.currentWeek) of \(store.scheduleWeeks.count)")
                            .font(.title3.bold())
                    } else {
                        Text("Program Complete! 🎉")
                            .font(.title3.bold())
                    }
                }
                Spacer()
                Image(systemName: "figure.stand")
                    .font(.title)
                    .foregroundStyle(.primary)
            }

            if let week = store.currentScheduleWeek {
                Divider()

                HStack(spacing: 24) {
                    VStack {
                        Text("\(week.minutesPerDay)")
                            .font(.headline)
                        Text("min/day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack {
                        Text("\(week.daysPerWeek)")
                            .font(.headline)
                        Text("days/week")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Streak

    private var streakCard: some View {
        let info = store.streakInfo
        return HStack(spacing: 16) {
            streakStat(value: "\(info.currentStreak)", label: "Current\nStreak", icon: "flame.fill", color: .orange)
            streakStat(value: "\(info.longestStreak)", label: "Longest\nStreak", icon: "trophy.fill", color: .yellow)
            streakStat(value: "\(info.totalSessions)", label: "Total\nSessions", icon: "checkmark.circle.fill", color: .green)
            streakStat(value: "\(info.totalMinutes)", label: "Total\nMinutes", icon: "clock.fill", color: .blue)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func streakStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Week Progress

    private var weekProgressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("This Week")
                    .font(.headline)
                Spacer()
                if let week = store.currentScheduleWeek {
                    Text("\(store.sessionsThisWeek) / \(week.daysPerWeek) sessions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let week = store.currentScheduleWeek {
                let target = Double(week.daysPerWeek)
                let progress = min(Double(store.sessionsThisWeek) / max(target, 1), 1.0)
                ProgressView(value: progress)
                    .tint(.primary)
                    .scaleEffect(y: 2)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Quick Actions

    private var quickActionsCard: some View {
        VStack(spacing: 12) {
            Button {
                showingActiveSession = true
            } label: {
                Label("Start Session", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            HStack(spacing: 12) {
                Button {
                    showingLogSheet = true
                } label: {
                    Label("Log Past", systemImage: "plus.circle.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.secondary.opacity(0.15))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    showingMicroChecks = true
                } label: {
                    Label("Micro-Check", systemImage: "checklist")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.secondary.opacity(0.15))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }
}

// MARK: - Animated Streak Flame

struct StreakFlameView: View {
    let streak: Int
    @State private var flicker = false

    private var flameColor: Color {
        switch streak {
        case 0: return .gray
        case 1...3: return .orange
        case 4...7: return .red
        default: return .purple
        }
    }

    var body: some View {
        ZStack {
            // Outer glow
            Image(systemName: "flame.fill")
                .font(.system(size: 32))
                .foregroundStyle(flameColor.opacity(0.3))
                .blur(radius: 6)
                .scaleEffect(flicker ? 1.15 : 1.0)

            // Main flame
            Image(systemName: "flame.fill")
                .font(.system(size: 28))
                .foregroundStyle(flameColor)
                .scaleEffect(flicker ? 1.08 : 0.95)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                flicker = true
            }
        }
    }
}

// MARK: - Streak Celebration Overlay

struct StreakCelebrationOverlay: View {
    let streak: Int
    @Binding var isPresented: Bool

    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var flameScale: CGFloat = 0.1
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var particles: [CelebrationParticle] = []
    @State private var textOffset: CGFloat = 30

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.4 * opacity)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Burst ring
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [.orange, .red, .yellow, .orange],
                        center: .center
                    ),
                    lineWidth: 4
                )
                .frame(width: 200, height: 200)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            // Particles
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(particle.offset)
                    .opacity(particle.opacity)
            }

            // Central content
            VStack(spacing: 16) {
                ZStack {
                    // Glow
                    Image(systemName: "flame.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.orange.opacity(0.4))
                        .blur(radius: 20)
                        .scaleEffect(flameScale * 1.3)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.yellow, .orange, .red],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .scaleEffect(flameScale)
                }

                Text("\(streak) Day Streak!")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .offset(y: textOffset)

                Text("You're on fire! Keep it going!")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .offset(y: textOffset)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear { animate() }
    }

    private func animate() {
        // Spawn particles
        particles = (0..<20).map { _ in
            CelebrationParticle()
        }

        // Phase 1: Quick scale-up
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            scale = 1.0
            opacity = 1.0
        }

        // Phase 2: Flame pop
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.15)) {
            flameScale = 1.0
        }

        // Phase 3: Ring burst
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            ringScale = 2.5
            ringOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
            ringOpacity = 0
        }

        // Phase 4: Text slides in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.25)) {
            textOffset = 0
        }

        // Phase 5: Scatter particles
        for i in particles.indices {
            let delay = 0.2 + Double(i) * 0.02
            withAnimation(.easeOut(duration: 0.8).delay(delay)) {
                particles[i].offset = CGSize(
                    width: CGFloat.random(in: -160...160),
                    height: CGFloat.random(in: -250...250)
                )
            }
            withAnimation(.easeOut(duration: 0.5).delay(delay + 0.4)) {
                particles[i].opacity = 0
            }
        }

        // Auto-dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            dismiss()
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
            scale = 0.8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

struct CelebrationParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var offset: CGSize
    var opacity: Double

    init() {
        let colors: [Color] = [.orange, .yellow, .red, .white, .pink]
        color = colors.randomElement()!
        size = CGFloat.random(in: 4...10)
        offset = CGSize(
            width: CGFloat.random(in: -20...20),
            height: CGFloat.random(in: -20...20)
        )
        opacity = 1.0
    }
}
