import SwiftUI

extension SettingsView {

    // MARK: - Pet section

    var petSection: some View {
        settingsSection("Notch Pet", subtitle: "A tiny companion that lives near the notch and reacts to your Claude usage. Click to poke!") {
            settingsRow("Enable pet") {
                Toggle("", isOn: $settings.petEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
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
                settingsRow("Chattiness") {
                    Picker("", selection: $settings.petChattiness) {
                        ForEach(PetChattiness.allCases) { chat in
                            Text(chat.displayName).tag(chat)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .accessibilityLabel("Pet chattiness")
                    .fixedSize()
                    .onChange(of: settings.petChattiness) { _, v in AppSettings.petChattiness = v }
                }
                VStack(alignment: .leading, spacing: 4) {
                    settingsRow("Position") {
                        Picker("", selection: $settings.petPosition) {
                            ForEach(PetPosition.allCases) { pos in
                                Text(pos.rawValue).tag(pos)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
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
                settingsRow("Size") {
                    Picker("", selection: $settings.petSize) {
                        ForEach(PetSize.allCases) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .accessibilityLabel("Pet size")
                    .fixedSize()
                    .onChange(of: settings.petSize) { _, v in
                        AppSettings.petSize = v
                        NotificationCenter.default.post(name: .petPositionDidChange, object: nil)
                    }
                }
                settingsRow("Wellness reminders") {
                    Toggle("", isOn: $settings.petWellnessReminders)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
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
            HStack(spacing: 8) {
                ForEach(PetCharacter.allCases) { char in
                    let isSelected = settings.petCharacter == char
                    Button {
                        settings.petCharacter = char
                        AppSettings.petCharacter = char
                        settings.petVariant = PetVariant.defaultVariant(for: char)
                        AppSettings.petVariant = settings.petVariant
                        NotificationCenter.default.post(name: .petCharacterDidChange, object: nil)
                    } label: {
                        VStack(spacing: 3) {
                            AnimatedSpriteView(
                                animation: isSelected ? .happy : .idle,
                                pixelSize: 2.0,
                                character: char,
                                variant: PetVariant.defaultVariant(for: char)
                            )
                            .frame(width: 24, height: 24)
                            Text(char.displayName)
                                .font(.system(size: 9, weight: isSelected ? .bold : .regular))
                                .foregroundStyle(isSelected ? .primary : .secondary)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 6)
                        .background {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Pet character: \(char.displayName)")
                }
            }
        }
        .padding(.vertical, 2)
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
                    .controlSize(.mini)
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
                    .controlSize(.mini)
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
            HStack(spacing: 6) {
                ForEach(variants) { v in
                    let isSelected = settings.petVariant == v
                    Button {
                        settings.petVariant = v
                        AppSettings.petVariant = v
                        NotificationCenter.default.post(name: .petCharacterDidChange, object: nil)
                    } label: {
                        VStack(spacing: 3) {
                            AnimatedSpriteView(
                                animation: isSelected ? .happy : .idle,
                                pixelSize: 2.0,
                                character: v.character,
                                variant: v
                            )
                            .frame(width: 24, height: 24)
                            Text(v.shortName)
                                .font(.system(size: 9, weight: isSelected ? .bold : .regular))
                                .foregroundStyle(isSelected ? .primary : .secondary)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 4)
                        .background {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Pet variant: \(v.shortName)")
                }
            }
        }
        .padding(.vertical, 2)
    }

}
