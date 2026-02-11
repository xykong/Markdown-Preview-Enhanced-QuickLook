# Sparkle EdDSA Keys

**CRITICAL**: Private key is stored in macOS Keychain, NOT in files.

## Public Key (for Info.plist)

See `sparkle_public_key.txt`:

```
BDhsLBTgtRax5K78RrmvkB2wCcLeKM7FxsuHu47soaU=
```

This public key is already configured in `Sources/Markdown/Info.plist`.

## Private Key Location

**Stored in macOS Keychain**:
- **Service**: Generic Password
- **Account**: `markdown-quicklook`
- **Label**: `Private key for signing Sparkle updates`

To verify the key exists:

```bash
security find-generic-password -a "markdown-quicklook" -l "Private key for signing Sparkle updates"
```

## Usage

### Signing Updates

Use Sparkle's `sign_update` tool (automatically finds the key in Keychain):

```bash
# The sign_update tool is located in DerivedData after building
~/Library/Developer/Xcode/DerivedData/MarkdownPreviewEnhanced-*/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update \
  build/artifacts/MarkdownPreviewEnhanced.dmg
```

Or use the wrapper script:

```bash
./scripts/generate-appcast.sh build/artifacts/MarkdownPreviewEnhanced.dmg
```

### Generating New Keys

If you need to generate a new key pair (requires Sparkle tools):

```bash
# Use Sparkle's generate_keys tool
# This will store the private key in Keychain automatically
~/Library/Developer/Xcode/DerivedData/.../Sparkle/bin/generate_keys
```

## Key Management

### Backup Private Key from Keychain

To export the private key for backup (requires Keychain password):

```bash
security find-generic-password -a "markdown-quicklook" -w
```

**Store the backup in a secure location (password manager, encrypted storage).**

### Restore Private Key to Keychain

If you need to restore the key on a new machine:

```bash
security add-generic-password \
  -a "markdown-quicklook" \
  -s "markdown-quicklook" \
  -l "Private key for signing Sparkle updates" \
  -w "<your-private-key-here>" \
  -U
```

### Delete Private Key from Keychain

To remove the key (use with caution):

```bash
security delete-generic-password -a "markdown-quicklook"
```

## Security Notes

- ✅ Private key is stored in Keychain (secure)
- ✅ Public key is committed to git (safe to share)
- ✅ `.sparkle-keys/` directory does NOT contain private key files
- ⚠️  Never commit private keys to version control
- ⚠️  Backup the private key in a secure location

## Verification

To verify the setup is correct:

1. Check public key in Info.plist:
   ```bash
   grep -A 1 "SUPublicEDKey" Sources/Markdown/Info.plist
   ```

2. Check private key in Keychain:
   ```bash
   security find-generic-password -a "markdown-quicklook"
   ```

3. Test signing (should succeed):
   ```bash
   sign_update path/to/test.dmg
   ```

## Troubleshooting

### Error: "Could not find private key"

The private key is not in Keychain. Restore it from backup or generate a new key pair (requires updating the public key in Info.plist).

### Error: "sign_update command not found"

Build the project once to download Sparkle via Swift Package Manager:

```bash
make app
```

The `sign_update` tool will be available in DerivedData.
