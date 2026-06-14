# CrossOver Nix Derivation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a Nix derivation for CrossOver (crosshair overlay tool) that builds from source using npm and electron-builder, following nixpkgs conventions.

**Architecture:** Fetch source from GitHub, lock npm dependencies with fetchNpmDeps, build with electron-builder in directory mode, wrap the resulting electron app with proper flags for Wayland/X11 support.

**Tech Stack:** Nix, npm, electron-builder, electron_14 (or newer), makeWrapper, copyDesktopItems

---

## File Structure

**Files to create:**
- `pkgs/cross-over/default.nix` - Main derivation (local testing)

**Files to reference:**
- Design spec: `docs/superpowers/specs/2026-06-14-crossover-derivation-design.md`
- Reference examples: `pkgs/any-listen/default.nix`, `~/code/nixpkgs/pkgs/by-name/wh/whatsapp-electron/package.nix`

---

### Task 1: Write Initial Derivation Structure

**Files:**
- Create: `pkgs/cross-over/default.nix`

- [ ] **Step 1: Write the basic derivation skeleton**

```nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchNpmDeps,
  makeWrapper,
  nodejs,
  electron,
  copyDesktopItems,
  makeDesktopItem,
  npmHooks,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "crossover";
  version = "3.4.2";

  src = fetchFromGitHub {
    owner = "lacymorrow";
    repo = "crossover";
    rev = "v${finalAttrs.version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) pname version src;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  nativeBuildInputs = [
    makeWrapper
    nodejs
    npmHooks.npmConfigHook
    copyDesktopItems
  ];

  env.ELECTRON_SKIP_BINARY_DOWNLOAD = 1;

  buildPhase = ''
    runHook preBuild
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "crossover";
      exec = "crossover";
      icon = "crossover";
      desktopName = "CrossOver";
      comment = "Crosshair overlay for any screen";
      categories = [ "Game" "Utility" ];
      startupWMClass = "crossover";
    })
  ];

  meta = {
    description = "Crosshair overlay for any screen";
    homepage = "https://github.com/lacymorrow/crossover";
    changelog = "https://github.com/lacymorrow/crossover/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ msdone ];
    mainProgram = "crossover";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
  };
})
```

- [ ] **Step 2: Attempt initial build to get src hash**

Run: `cd ~/mynixos && nix-build -A crossover pkgs/cross-over`
Expected: Build fails with "hash mismatch" error showing actual hash

- [ ] **Step 3: Update src hash with actual value**

Replace the src hash placeholder with the actual hash from the error message.

```nix
src = fetchFromGitHub {
  owner = "lacymorrow";
  repo = "crossover";
  rev = "v${finalAttrs.version}";
  hash = "sha256-<actual-hash-from-error>";
};
```

- [ ] **Step 4: Attempt build to get npmDeps hash**

Run: `cd ~/mynixos && nix-build -A crossover pkgs/cross-over`
Expected: Build fails with npmDeps hash mismatch showing actual hash

- [ ] **Step 5: Update npmDeps hash with actual value**

Replace the npmDeps hash placeholder with the actual hash from the error message.

```nix
npmDeps = fetchNpmDeps {
  inherit (finalAttrs) pname version src;
  hash = "sha256-<actual-hash-from-error>";
};
```

- [ ] **Step 6: Commit the skeleton**

```bash
git add pkgs/cross-over/default.nix
git commit -m "wip: add crossover derivation skeleton with correct hashes"
```

---

### Task 2: Implement Build Phase

**Files:**
- Modify: `pkgs/cross-over/default.nix:38-40`

- [ ] **Step 1: Add electron-builder build command**

Replace the buildPhase with:

```nix
buildPhase = ''
  runHook preBuild

  npm install
  ./node_modules/.bin/electron-builder \
    --dir \
    -c.electronDist=${electron.dist} \
    -c.electronVersion=${electron.version}

  runHook postBuild
'';
```

- [ ] **Step 2: Attempt build**

Run: `cd ~/mynixos && nix-build -A crossover pkgs/cross-over`
Expected: May fail with various errors (missing electron, build config issues, etc.)

- [ ] **Step 3: Check build log for errors**

Run: `cat result 2>&1 | tail -100` or check the nix-build output
Action: Identify the specific error and proceed to Task 3 for fixes

---

### Task 3: Add Patches and Fixes

**Files:**
- Modify: `pkgs/cross-over/default.nix`
- Create (if needed): `pkgs/cross-over/*.patch`

- [ ] **Step 1: Add postPatch to disable auto-update**

Add after the `npmDeps` section:

```nix
postPatch = ''
  # Disable auto-update feature
  substituteInPlace src/main.js \
    --replace-fail "autoUpdater.checkForUpdates" "// autoUpdater.checkForUpdates" \
    || true
  
  # Fix electron path if needed
  substituteInPlace package.json \
    --replace-fail '"electron":' '"electron-disabled":'
'';
```

- [ ] **Step 2: Rebuild to test patches**

Run: `cd ~/mynixos && nix-build -A crossover pkgs/cross-over`
Expected: Build should progress further

- [ ] **Step 3: If build fails, analyze error log**

Check the error type:
- If "electron not found": verify ELECTRON_SKIP_BINARY_DOWNLOAD is set
- If "build config error": may need to patch electron-builder config
- If "missing dependencies": may need to add buildInputs

Continue to next step based on actual error.

- [ ] **Step 4: Add additional postPatch fixes based on errors**

Example if electron-builder config needs patching:

```nix
postPatch = ''
  # Disable auto-update feature
  substituteInPlace src/main.js \
    --replace-fail "autoUpdater.checkForUpdates" "// autoUpdater.checkForUpdates" \
    || true
  
  # Patch electron-builder config
  cat > electron-builder-override.js << 'EOF'
module.exports = {
  electronDist: process.env.ELECTRON_DIST || '${electron.dist}',
  electronVersion: '${electron.version}'
};
EOF
'';
```

- [ ] **Step 5: Commit working build phase**

```bash
git add pkgs/cross-over/default.nix
git commit -m "feat(crossover): add build phase with patches"
```

---

### Task 4: Implement Install Phase

**Files:**
- Modify: `pkgs/cross-over/default.nix:50-53`

- [ ] **Step 1: Add installation logic**

Replace the installPhase with:

```nix
installPhase = ''
  runHook preInstall

  mkdir -p "$out/share/crossover"
  cp -r dist/*-unpacked/{locales,resources{,.pak}} "$out/share/crossover"

  # Remove auto-update file
  rm -f "$out/share/crossover/app-update.yml"

  # Install icons - check actual icon location in source
  for size in 256 512; do
    if [ -f "assets/icon-''${size}x''${size}.png" ]; then
      install -Dm644 "assets/icon-''${size}x''${size}.png" \
        "$out/share/icons/hicolor/''${size}x''${size}/apps/crossover.png"
    fi
  done

  # Fallback: try build/icon.png or resources/icon.png
  if [ ! -f "$out/share/icons/hicolor/256x256/apps/crossover.png" ]; then
    for iconPath in build/icon.png resources/icon.png assets/icon.png; do
      if [ -f "$iconPath" ]; then
        install -Dm644 "$iconPath" "$out/share/icons/hicolor/256x256/apps/crossover.png"
        break
      fi
    done
  fi

  runHook postInstall
'';
```

- [ ] **Step 2: Rebuild to test installation**

Run: `cd ~/mynixos && nix-build -A crossover pkgs/cross-over`
Expected: Build should complete and create result symlink

- [ ] **Step 3: Verify installed files**

Run: `ls -la result/share/crossover/`
Expected: Should see resources/, locales/, and app.asar or similar

Run: `ls -la result/share/icons/hicolor/*/apps/`
Expected: Should see crossover.png icons

- [ ] **Step 4: If icon installation failed, fix the paths**

Check the actual source structure:
```bash
cd /tmp && tar -xzf $(nix-build ~/mynixos -A crossover.src --no-out-link) && find . -name "*icon*" -o -name "*logo*" | head -20
```

Update the icon paths in installPhase based on actual locations.

- [ ] **Step 5: Commit working install phase**

```bash
git add pkgs/cross-over/default.nix
git commit -m "feat(crossover): implement install phase"
```

---

### Task 5: Add Executable Wrapper

**Files:**
- Modify: `pkgs/cross-over/default.nix:55-58` (after installPhase)

- [ ] **Step 1: Add postFixup with wrapper**

Add after the installPhase:

```nix
postFixup = ''
  makeWrapper ${lib.getExe electron} "$out/bin/crossover" \
    --add-flags "$out/share/crossover/resources/app.asar" \
    --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
    --set-default ELECTRON_FORCE_IS_PACKAGED 1 \
    --set-default ELECTRON_IS_DEV 0 \
    --inherit-argv0
'';
```

- [ ] **Step 2: Rebuild to test wrapper**

Run: `cd ~/mynixos && nix-build -A crossover pkgs/cross-over`
Expected: Build completes successfully

- [ ] **Step 3: Verify wrapper exists and is executable**

Run: `ls -la result/bin/crossover`
Expected: Should exist and be executable

Run: `file result/bin/crossover`
Expected: Should be a shell script (wrapper)

- [ ] **Step 4: Check wrapper content**

Run: `cat result/bin/crossover`
Expected: Should contain electron path and flags

- [ ] **Step 5: Commit wrapper implementation**

```bash
git add pkgs/cross-over/default.nix
git commit -m "feat(crossover): add executable wrapper with Wayland support"
```

---

### Task 6: Test Runtime Execution

**Files:**
- Test only, no file changes

- [ ] **Step 1: Attempt to run crossover**

Run: `result/bin/crossover`
Expected: Application window should open (or error message)

Note: This may fail in a headless environment. Check for error messages.

- [ ] **Step 2: If app fails to start, check error log**

Common issues:
- Missing libraries: use `ldd result/bin/crossover` to check
- app.asar not found: verify path in wrapper
- Electron version mismatch: may need different electron version

- [ ] **Step 3: If missing libraries, add buildInputs**

Example if libraries are missing:

```nix
buildInputs = [
  xorg.libX11
  xorg.libXtst
  libxkbcommon
  gtk3
  nss
  nspr
];
```

- [ ] **Step 4: Rebuild and test again**

Run: `cd ~/mynixos && nix-build -A crossover pkgs/cross-over && result/bin/crossover`
Expected: App starts without library errors

- [ ] **Step 5: Document test results**

Create a comment in the derivation or commit message noting:
- Whether app starts successfully
- Any runtime warnings or issues
- Tested on X11/Wayland

```bash
git add pkgs/cross-over/default.nix
git commit -m "fix(crossover): add missing runtime dependencies"
```

---

### Task 7: Code Formatting and Final Verification

**Files:**
- Modify: `pkgs/cross-over/default.nix`

- [ ] **Step 1: Format with nixpkgs-fmt**

Run: `nixpkgs-fmt pkgs/cross-over/default.nix`
Expected: File is formatted according to nixpkgs style

- [ ] **Step 2: Verify all required meta fields**

Check that meta includes:
- description
- homepage
- changelog
- license (FSL-1.1-MIT is unfree)
- maintainers
- mainProgram
- platforms
- sourceProvenance

- [ ] **Step 3: Final build test**

Run: `cd ~/mynixos && nix-build -A crossover pkgs/cross-over`
Expected: Clean build with no warnings

- [ ] **Step 4: Check derivation with nix-review (if available)**

Run: `nix-shell -p nix-review --run "nix-review rev HEAD"`
Expected: No errors or warnings

- [ ] **Step 5: Commit final version**

```bash
git add pkgs/cross-over/default.nix
git commit -m "feat: add crossover package

CrossOver is a crosshair overlay for any screen, useful for gaming.

Built from source using electron-builder, following nixpkgs patterns
for Electron applications.

Includes:
- Wayland and X11 support
- Desktop integration
- Proper icon installation
"
```

---

### Task 8: Prepare for nixpkgs Submission

**Files:**
- Review: `pkgs/cross-over/default.nix`
- Document: Git commit message

- [ ] **Step 1: Review derivation against nixpkgs guidelines**

Check:
- Uses `lib.licenses.unfree` (FSL-1.1-MIT license)
- Follows by-name convention (will be moved to `pkgs/by-name/cr/crossover/package.nix`)
- Uses finalAttrs pattern correctly
- Has proper meta fields
- No hardcoded paths

- [ ] **Step 2: Test installation in user profile**

Run: `nix-env -f ~/mynixos -iA crossover`
Expected: Installs successfully

Run: `which crossover`
Expected: Shows path in ~/.nix-profile/bin/

- [ ] **Step 3: Test desktop integration**

Check: Desktop file should appear in application menu
Run: `ls ~/.nix-profile/share/applications/`
Expected: crossover.desktop exists

- [ ] **Step 4: Document migration steps for user**

Create a note for moving to nixpkgs:
```markdown
## Migration to nixpkgs

1. Fork nixpkgs repository
2. Create directory: pkgs/by-name/cr/crossover/
3. Move pkgs/cross-over/default.nix to pkgs/by-name/cr/crossover/package.nix
4. Test build: nix-build -A crossover
5. Create PR with commit message from Task 7, Step 5
```

- [ ] **Step 5: Create migration checklist**

Document in commit message or separate file:
- [ ] Fork nixpkgs
- [ ] Create by-name directory structure
- [ ] Move and rename derivation file
- [ ] Test build in nixpkgs context
- [ ] Submit PR with proper title and description
- [ ] Add yourself to maintainers list if needed

---

## Validation Checklist

After completing all tasks, verify:

- [ ] Derivation builds successfully: `nix-build -A crossover`
- [ ] Application runs without errors (if testable)
- [ ] Desktop file installed correctly
- [ ] Icons installed in correct locations
- [ ] Wrapper script has proper Wayland/X11 flags
- [ ] Code formatted with nixpkgs-fmt
- [ ] Meta fields complete and accurate
- [ ] License is correct (unfree for FSL-1.1-MIT)
- [ ] Commit messages follow conventional commits style

## Known Issues and Solutions

### Issue: electron-builder fails with "cannot find electron"
**Solution:** Verify ELECTRON_SKIP_BINARY_DOWNLOAD=1 is set and electron-builder config is patched

### Issue: App crashes on startup with "cannot load app.asar"
**Solution:** Check path in wrapper, may need to adjust resources path

### Issue: Missing uiohook-napi native module
**Solution:** May need to add additional buildInputs or patches for native module compilation

### Issue: Wayland flags not working
**Solution:** Verify NIXOS_OZONE_WL environment variable pattern in wrapper

---

## Post-Implementation

After successful local build and testing, user will:
1. Move derivation to nixpkgs fork at `pkgs/by-name/cr/crossover/package.nix`
2. Test in nixpkgs context
3. Create PR to nixpkgs repository
4. Reference this implementation plan in PR description
