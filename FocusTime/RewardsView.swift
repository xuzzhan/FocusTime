import SwiftUI

struct RewardsView: View {
    @ObservedObject var vm: PomodoroViewModel

    private let pagePadding: CGFloat = 20
    private let blockSpacing: CGFloat = 16
    private let cardCornerRadius: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: blockSpacing) {
            pageHeader(
                title: vm.appLanguage == .zh ? "金币兑换" : "Rewards",
                subtitle: vm.appLanguage == .zh
                ? "使用金币解锁主题与皮肤"
                : "Use coins to unlock themes and skins"
            )

            summaryCard

            contentCard

            Spacer(minLength: 0)
        }
        .padding(pagePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var summaryCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 26))
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 3) {
                Text(vm.appLanguage == .zh ? "当前金币" : "Current Coins")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(vm.totalCoins())")
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
            }

            Spacer()
        }
        .padding(16)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
    }

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(vm.appLanguage == .zh ? "主题商店" : "Theme Store")
                .font(.headline)
            
            Divider()

            VStack(alignment: .leading, spacing: 10) {
                placeholderRow(
                    title: vm.appLanguage == .zh ? "石墨 Graphite" : "Graphite",
                    cost: 6
                )
                placeholderRow(
                    title: vm.appLanguage == .zh ? "森林 Forest" : "Forest",
                    cost: 8
                )
                placeholderRow(
                    title: vm.appLanguage == .zh ? "午夜 Midnight" : "Midnight",
                    cost: 10
                )
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
    }

    @ViewBuilder
    private func pageHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.weight(.semibold))

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func placeholderRow(title: String, cost: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))

                Text(vm.appLanguage == .zh ? "主题预览占位" : "Theme preview placeholder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Label("\(cost)", systemImage: "dollarsign.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
#Preview("Content") {
    RewardsView(vm: PomodoroViewModel())
}
