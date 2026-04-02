import SwiftUI

struct AppearancePickerSheet: View {
    @EnvironmentObject private var appearance: AppearanceStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                VStack(spacing: 12) {
                    ForEach(AppearancePreference.allCases) { option in
                        appearanceOptionButton(option)
                    }
                }
                .cartoonPanelChrome()

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(TwelveTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TwelveTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Look & feel")
                        .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                        .foregroundStyle(TwelveTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(TwelveTheme.appFont(size: 17))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .font(TwelveTheme.appFont(size: 16))
    }

    private func appearanceOptionButton(_ option: AppearancePreference) -> some View {
        let isOn = appearance.preference == option
        return Button {
            appearance.setPreference(option)
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Text(option.title)
                    .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                    .foregroundStyle(TwelveTheme.textPrimary)

                Spacer(minLength: 8)

                if isOn {
                    Text("✓")
                        .font(TwelveTheme.appFont(size: 16, weight: .bold))
                        .foregroundStyle(TwelveTheme.primaryBlue)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isOn ? TwelveTheme.softBlue.opacity(0.22) : TwelveTheme.secondarySurface.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isOn ? TwelveTheme.primaryBlue.opacity(0.35) : TwelveTheme.hairline, lineWidth: isOn ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AppearancePickerSheet()
        .environmentObject(AppearanceStore())
}
