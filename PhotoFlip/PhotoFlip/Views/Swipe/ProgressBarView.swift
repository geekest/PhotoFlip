import SwiftUI

struct ProgressBarView: View {
    let current: Int
    let total: Int

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.25))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.easeInOut(duration: 0.2), value: progress)
                }
            }
            .frame(height: 6)

            Text("\(current) / \(total)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
}
