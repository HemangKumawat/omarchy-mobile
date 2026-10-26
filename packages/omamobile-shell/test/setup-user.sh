#!/bin/bash
# SPDX-License-Identifier: MIT
# omamobile-setup-user against a scratch home and fake commands (omarchy-done,
# gsettings, systemctl, chromium): run twice, as two logins would, and check
# what it leaves in the user's files.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
pkg=$PWD
fail() { printf 'not ok - %s\n' "$1" >&2; exit 1; }
pass() { printf 'ok - %s\n' "$1"; }
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT

F=$t/fakes; H=$t/home; mkdir -p "$F" "$H/.config/hypr" "$H/.config/omarchy/extensions"
fake() { printf '#!/bin/bash\n%s\n' "$2" >"$F/$1"; chmod +x "$F/$1"; }
# omarchy-done: ensure succeeds once per name, mark records it
fake omarchy-done 'd=$HOME/.local/state/omarchy/done; mkdir -p "$d"
case $1 in
  ensure) [[ -e $d/$2 ]] && exit 1; touch "$d/$2" ;;
  mark) touch "$d/$2" ;;
esac'
fake gsettings 'echo "gsettings $*" >>"$HOME/calls"'
fake systemctl 'echo "systemctl $*" >>"$HOME/calls"'
fake chromium 'echo "Chromium 153.0.0.0"'
for f in monitors looknfeel autostart; do echo "-- $f" >"$H/.config/hypr/$f.lua"; done
echo 'local omarchy_monitor_scale = 2' >"$H/.config/hypr/monitors.lua"
# Omarchy's shipped extension file starts like this
printf '{\n  // Extend the Quickshell Omarchy menu with JSONC.\n  // "personal": {"icon":"","label":"Personal"},\n}\n' \
  >"$H/.config/omarchy/extensions/omarchy-menu.jsonc"

run() {
  env -i HOME="$H" PATH="$F:/usr/bin:/bin" XDG_RUNTIME_DIR="$t" OMAMOBILE_SHELL_SHARE="$pkg" \
    bash bin/omamobile-setup-user >"$t/out" 2>&1 || { cat "$t/out"; fail "omamobile-setup-user runs"; }
}
run
# A user who wants Logout back gives the row their own entry
ext=$H/.config/omarchy/extensions/omarchy-menu.jsonc
sed -i 's|^  "system.logout": {"when": "false"},$|  "system.logout": {"when": "true"},|' "$ext"
run

# The extension file as the menu reads it: JSONC with trailing commas
menu=$(python3 -I - "$ext" <<'PY'
import json, re, sys
text = open(sys.argv[1]).read()
text = re.sub(r'^\s*//.*$', '', text, flags=re.M)
text = re.sub(r',(\s*[}\]])', r'\1', text)
for key, value in json.loads(text).items():
    print(key, value.get("when", ""))
PY
) || fail "the menu extension file stays valid JSONC"
for id in update.channel update.channel.stable update.channel.rc update.channel.edge update.channel.dev \
          update.config.hyprland update.config.shell setup.direct-boot update.password.drive \
          learn.keybindings learn.tmux-keybindings learn.herdr-keybindings \
          style.bar.position.left style.bar.position.right style.bar.position.bottom \
          trigger.toggle.top-bar trigger.toggle.one-window-ratio trigger.toggle.workspace-layout \
          install.windows install.browser.chrome install.gaming.steam; do
  grep -qx "$id false" <<<"$menu" || fail "Menu row $id is hidden"
  [[ $(grep -c "\"$id\"" "$ext") == 1 ]] || fail "Menu row $id is named once after two logins"
done
grep -qx 'system.logout true' <<<"$menu" || fail "a row the user set is left as they set it"
for id in style.bar.position.top update.omarchy install.gaming.retroarch; do
  grep -q "^$id false" <<<"$menu" && fail "Menu row $id stays"
done
pass "menu rows that break the phone are hidden once, by content, and a user's own entry is kept"
