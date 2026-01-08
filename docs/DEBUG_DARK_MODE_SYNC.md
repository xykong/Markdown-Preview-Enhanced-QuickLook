# How to Enable Dark Mode Sync (App Groups)

To make the **Main App**'s appearance setting apply to the **QuickLook Extension**, we use **App Groups**.

We have already added the configuration to the code and entitlements files:
1. `Sources/Shared/AppearancePreference.swift`: Updated to use `UserDefaults(suiteName: "group.com.xykong.Markdown")`.
2. `*.entitlements`: Added `com.apple.security.application-groups`.

## ⚠️ Critical Step: Xcode Configuration

Since App Groups require a valid provisioning profile from the Apple Developer Portal, you **must** perform these steps manually in Xcode if you change the Bundle ID or Team:

1. Open `Markdown.xcodeproj` (generate it first with `make generate`).
2. Select the project root in the Project Navigator.
3. Select the **Markdown** (Main App) target -> **Signing & Capabilities**.
   - Ensure **App Groups** is present.
   - If there's an error (Red), click the "+" button to register the group `group.com.xykong.Markdown` with your Apple ID.
4. Select the **MarkdownPreview** (Extension) target -> **Signing & Capabilities**.
   - Ensure **App Groups** is present.
   - Ensure the SAME group `group.com.xykong.Markdown` is checked.

## Troubleshooting

- **Setting doesn't sync?** 
  - Check if both targets have the exact same App Group ID selected.
  - Clean Build Folder (`Cmd+Shift+K`).
  - Run `./install.sh` again to re-register the plugin.

- **Build Error: "Provisioning profile doesn't include the App Group"?**
  - You need to log in to Xcode with an Apple ID (Personal Team is fine).
  - Xcode should offer a "Fix" or "Register" button. Click it.
