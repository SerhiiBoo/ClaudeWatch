import SwiftUI

extension SettingsView {

    // MARK: - Pet section

    var petSection: some View {
        settingsSection("Notch Pet", systemImage: "pawprint.fill", subtitle: "A tiny companion that lives near the notch and reacts to your Claude usage. Click to poke!") {
            settingsRow("Enable pet", systemImage: "pawprint.fill") {
                Toggle("", isOn: $settings.petEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .accessibilityLabel("Enable notch pet")
                    .onChange(of: settings.petEnabled) { _, v in
                        petService.isEnabled = v
                        NotificationCenter.default.post(name: .petPositionDidChange, object: nil)
                    }
            }
            if settings.petEnabled {
                characterPicker
                variantPicker
                #if DEBUG
                petTestPanel
                #endif
                settingsRow("Chattiness", systemImage: "bubble.left.and.bubble.right.fill") {
                    Picker("", selection: $settings.petChattiness) {
                        ForEach(PetChattiness.allCases) { chat in
                            Text(chat.displayName).tag(chat)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .controlSize(.regular)
                    .accessibilityLabel("Pet chattiness")
                    .fixedSize()
                    .onChange(of: settings.petChattiness) { _, v in AppSettings.petChattiness = v }
                }
                VStack(alignment: .leading, spacing: 4) {
                    settingsRow("Position", systemImage: "arrow.up.left.and.arrow.down.right") {
                        Picker("", selection: $settings.petPosition) {
                            ForEach(PetPosition.allCases) { pos in
                                Text(pos.rawValue).tag(pos)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .controlSize(.regular)
                        .accessibilityLabel("Pet position")
                        .fixedSize()
                        .onChange(of: settings.petPosition) { _, v in
                            AppSettings.petPosition = v
                            NotificationCenter.default.post(name: .petPositionDidChange, object: nil)
                        }
                    }
                    Text(settings.petPosition.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                settingsRow("Size", systemImage: "ruler") {
                    Picker("", selection: $settings.petSize) {
                        ForEach(PetSize.allCases) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .controlSize(.regular)
                    .accessibilityLabel("Pet size")
                    .fixedSize()
                    .onChange(of: settings.petSize) { _, v in
                        AppSettings.petSize = v
                        NotificationCenter.default.post(name: .petPositionDidChange, object: nil)
                    }
                }
                settingsRow("Wellness reminders", systemImage: "heart.fill") {
                    Toggle("", isOn: $settings.petWellnessReminders)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .labelsHidden()
                        .accessibilityLabel("Wellness reminders")
                        .onChange(of: settings.petWellnessReminders) { _, v in AppSettings.petWellnessReminders = v }
                }
            }
        }
    }

    // MARK: - Character picker

    private var characterPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Character")
                .font(.caption)
                .foregroundStyle(.secondary)
            FlowLayout(spacing: 8) {
                ForEach(PetCharacter.allCases) { char in
                    let isSelected = settings.petCharacter == char
                    Button {
                        settings.petCharacter = char
                        AppSettings.petCharacter = char
                        settings.petVariant = PetVariant.defaultVariant(for: char)
                        AppSettings.petVariant = settings.petVariant
                        NotificationCenter.default.post(name: .petCharacterDidChange, object: nil)
                    } label: {
                        petPickerCell(
                            name: char.displayName,
                            isSelected: isSelected,
                            character: char,
                            variant: PetVariant.defaultVariant(for: char)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Pet character: \(char.displayName)")
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func petPickerCell(name: String, isSelected: Bool, character: PetCharacter, variant: PetVariant) -> some View {
        VStack(spacing: 3) {
            AnimatedSpriteView(
                animation: isSelected ? .happy : .idle,
                pixelSize: 2.0,
                character: character,
                variant: variant
            )
            .frame(width: 30, height: 30)
            Text(name)
                .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.center)
                .frame(minWidth: 46)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 8)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2.0)
        }
    }

    // MARK: - Preview-only movement test panel

    private var petTestPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Preview: Test movements")
                .font(.caption)
                .foregroundStyle(.secondary)
            FlowLayout(spacing: 4) {
                ForEach(PetMovement.allCases) { movement in
                    Button(movement.displayName) {
                        NotificationCenter.default.post(
                            name: .petTriggerAnimation,
                            object: nil,
                            userInfo: ["movement": movement.rawValue]
                        )
                    }
                    .font(.system(size: 9))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            Text("Preview: Ambient animations")
                .font(.caption)
                .foregroundStyle(.secondary)
            FlowLayout(spacing: 4) {
                ForEach([PetAnimation.coding, .debugging, .compiling], id: \.self) { anim in
                    Button(anim.rawValue) {
                        NotificationCenter.default.post(
                            name: .petTriggerAnimation,
                            object: nil,
                            userInfo: ["animation": anim.rawValue]
                        )
                    }
                    .font(.system(size: 9))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Variant picker

    private var variantPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Variant")
                .font(.caption)
                .foregroundStyle(.secondary)
            let variants = PetVariant.variants(for: settings.petCharacter)
            FlowLayout(spacing: 6) {
                ForEach(variants) { v in
                    let isSelected = settings.petVariant == v
                    Button {
                        settings.petVariant = v
                        AppSettings.petVariant = v
                        NotificationCenter.default.post(name: .petCharacterDidChange, object: nil)
                    } label: {
                        petPickerCell(
                            name: v.shortName,
                            isSelected: isSelected,
                            character: v.character,
                            variant: v
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Pet variant: \(v.shortName)")
                }
            }
        }
        .padding(.vertical, 2)
    }

}
