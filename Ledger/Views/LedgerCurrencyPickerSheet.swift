import SwiftUI

struct LedgerCurrencyPickerSheet: View {
    @ObservedObject var currency: LedgerCurrencyStore
    @Environment(\.dismiss) private var dismiss
    @State private var customCode: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Common")
                            .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        VStack(spacing: 10) {
                            ForEach(LedgerCurrencyStore.commonCodes, id: \.self) { code in
                                currencyRow(code: code, isOn: currency.currencyCode == code)
                            }
                        }
                        .cartoonPanelChrome()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom code (ISO 4217)")
                            .font(TwelveTheme.appFont(size: 13, weight: .medium))
                            .foregroundStyle(TwelveTheme.textSecondary)
                        HStack(spacing: 10) {
                            TextField("e.g. THB", text: $customCode)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .font(TwelveTheme.appFont(size: 16))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(TwelveTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            Button("Apply") {
                                currency.setCurrencyCode(customCode)
                                dismiss()
                            }
                            .buttonStyle(TwelvePillButtonStyle(accent: TwelveTheme.softBlue))
                            .disabled(customCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(TwelveTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TwelveTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Currency")
                        .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                        .foregroundStyle(TwelveTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(TwelveTheme.appFont(size: 17))
                }
            }
            .onAppear {
                customCode = currency.currencyCode
            }
        }
        .presentationDetents([.medium, .large])
        .font(TwelveTheme.appFont(size: 16))
    }

    private func currencyRow(code: String, isOn: Bool) -> some View {
        Button {
            currency.setCurrencyCode(code)
            dismiss()
        } label: {
            HStack {
                Text(code)
                    .font(TwelveTheme.appFont(size: 17, weight: .semibold))
                    .foregroundStyle(TwelveTheme.textPrimary)
                Spacer()
                if isOn {
                    Image(systemName: "checkmark")
                        .font(TwelveTheme.appFont(size: 14, weight: .bold))
                        .foregroundStyle(TwelveTheme.primaryBlue)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isOn ? TwelveTheme.softBlue.opacity(0.22) : TwelveTheme.secondarySurface.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isOn ? TwelveTheme.primaryBlue.opacity(0.35) : TwelveTheme.hairline, lineWidth: isOn ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
