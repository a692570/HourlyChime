import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    private let settings: ChimeSettings
    private let dayNames = ["M", "T", "W", "T", "F", "S", "S"]

    init(viewModel: SettingsViewModel, settings: ChimeSettings) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.settings = settings
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Days")
                    .frame(width: 70, alignment: .leading)
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { index in
                        DayToggle(label: dayNames[index], isOn: Binding(
                            get: { viewModel.enabledDays[index] },
                            set: { viewModel.enabledDays[index] = $0 }
                        ))
                    }
                }
            }

            HStack {
                Text("Hours")
                    .frame(width: 70, alignment: .leading)
                Picker("", selection: $viewModel.startHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(formatHour(hour)).tag(hour)
                    }
                }
                .labelsHidden()
                .frame(width: 85)

                Text("to")

                Picker("", selection: $viewModel.endHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(formatHour(hour)).tag(hour)
                    }
                }
                .labelsHidden()
                .frame(width: 85)
            }

            HStack {
                Text("Every")
                    .frame(width: 70, alignment: .leading)
                HStack(spacing: 6) {
                    FrequencyButton(label: "15m", value: 15, selected: $viewModel.frequencyMinutes)
                    FrequencyButton(label: "30m", value: 30, selected: $viewModel.frequencyMinutes)
                    FrequencyButton(label: "1h", value: 60, selected: $viewModel.frequencyMinutes)
                    FrequencyButton(label: "2h", value: 120, selected: $viewModel.frequencyMinutes)
                }
            }

            Divider()

            HStack {
                Button("🔊 Test") {
                    SoundPlayer.playChime()
                }

                Spacer()

                Button("Cancel") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    viewModel.save(to: settings)
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 340, height: 180)
    }

    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }
}

struct DayToggle: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Button(action: { isOn.toggle() }) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 26, height: 26)
                .background(isOn ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(isOn ? .white : .primary)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

struct FrequencyButton: View {
    let label: String
    let value: Int
    @Binding var selected: Int

    var body: some View {
        Button(action: { selected = value }) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 36, height: 26)
                .background(selected == value ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(selected == value ? .white : .primary)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}
