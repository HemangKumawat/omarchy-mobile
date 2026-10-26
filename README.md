# Omarchy Mobile

Native Omarchy on mobile devices: Arch Linux ARM, Hyprland and Omarchy's own packages running directly on the device with a mainline kernel, with Android apps in Waydroid as a later goal. The reference device is the Pixel 7 Pro (cheetah, gs201); community ports cover more Pixels, and the first non-Pixel ports are in review ([docs/DEVICES.md](docs/DEVICES.md)).

<p align="center">
  <img src="docs/screenshots/home.png" width="22%" alt="The home screen, with widgets and a dock">
  <img src="docs/screenshots/quick-settings.png" width="22%" alt="Quick settings">
  <img src="docs/screenshots/apps.png" width="22%" alt="The app list with the on-screen keyboard">
  <img src="docs/screenshots/terminal.png" width="22%" alt="A terminal running an AI agent">
</p>

**Status (2026-10-26), on the Pixel 7 Pro.** Each item's detail and the notes behind it: [docs/DEVICES.md](docs/DEVICES.md); what's missing and the plan to get there: [docs/ROADMAP.md](docs/ROADMAP.md).

- **Works:** display at 120 Hz, GPU, touch, buttons, USB networking, Wi-Fi, Bluetooth audio, battery, charging (on at boot under a battery temperature guard), haptics, torch, sensors with auto-rotate, GNSS (Location tile, GeoClue), NFC (reading and writing tags, opening a tag's link) and fingerprint unlock alongside the PIN pad or password, which keeps working across sleep (opt-in, because its first run writes Trusty's secure storage). All four cameras work in omacam ("Camera", [our own camera app](https://github.com/derekross/omacam), the default since omamobile-apps 0.2.0: one zoom control from the ultrawide to the telephoto, full-resolution photos, tap to focus, Night mode and an HDR chip) through libcamera: main, ultrawide, front and telephoto, at full size by default (`cam` with no options). The telephoto is fixed-focus for now: sharp on distant subjects, soft up close, because its focus motor isn't driven yet (it holds its I2C bus when driven). Single shots are still well below stock's quality: that is tuning.
- **Partial:** the speakers and microphones work but sound quiet and thin, with occasional static; a new speaker filter is built and not yet tuned on the phone.
- **In progress:** the modem boots Google's firmware and answers our IPC (SIM and radio state), but registration, SMS, data and calls need a SIM test that hasn't happened yet. Sleep on screen-off: s2idle passes repeated sleep and wake cycles with Wi-Fi staying connected (31 of 31 on 2026-10-19); the AoC and sensors across sleep, battery numbers and the screen-off policy come before it is on by default.
- **New on 2026-10-26:** a home pill that goes Home on a swipe up and opens recent apps on a swipe and hold, the dock hidden under apps, and Power waking a dark screen (`omamobile-shell` 0.2.17, [#43](https://github.com/derekross/omarchy-mobile/pull/43)), then the touch audit's quick wins: bigger hit areas, two taps for destructive actions, no text under 12 px (0.2.18, [#46](https://github.com/derekross/omarchy-mobile/pull/46), [docs/TOUCH-PLAN.md](docs/TOUCH-PLAN.md)); the Pixel 7 Pro's boot no longer reports a reserved-memory overlap ([kernel #58](https://github.com/derekross/linux-omarchy-mobile/pull/58)). Updates: `omarchy update` brings Omarchy's own packages over Wi-Fi, but Omarchy Mobile's packages aren't published yet, so they still come from your own build. Community ports: the Pixel Fold's volume and power keys and its cover touch chip id are in the kernel ([kernel #41](https://github.com/derekross/linux-omarchy-mobile/pull/41), [#32](https://github.com/derekross/linux-omarchy-mobile/pull/32)); the Pixel 7a reached first light with USB and SSH ([#36](https://github.com/derekross/omarchy-mobile/issues/36)); the Pixel 6 Pro runs Omarchy on our kernel, with its device package in review ([#41](https://github.com/derekross/omarchy-mobile/pull/41)); the Pixel 8 Pro's device package and storage plan are in review ([#42](https://github.com/derekross/omarchy-mobile/pull/42)); a tracking issue is open for the Pixel 11 Pro Fold ([#40](https://github.com/derekross/omarchy-mobile/issues/40)).
- **New on 2026-10-22:** Night mode and HDR in omacam 0.3.3: a burst of raw sensor frames aligned and merged on the phone before the colour processing (Night's 12 frames in about 4.6 s), on top of chroma noise reduction and defective pixel correction in our libcamera ([docs/CAMERA-QUALITY-PLAN.md](docs/CAMERA-QUALITY-PLAN.md)); images and updates follow Omarchy's stable channel, and `omarchy update` on the phone runs Omarchy's own update with the phone's safeguards (Omarchy Mobile's own packages aren't hosted yet). Community ports: the Pixel 8 Pro boots our mainline kernel with USB and SSH ([#1](https://github.com/derekross/omarchy-mobile/issues/1)), the Pixel 9a reached first light (in review), the Pixel 6 Pro has provisioning tools in review, and the POCO F3 is the first non-Pixel port proposed; tracking issues are open for the Pixel 10 Pro XL and Pixel 11 Pro.
- **New on 2026-10-19:** the Pixel Fold boots to its cover screen and the Pixel 6 builds, both community ports ([docs/DEVICES.md](docs/DEVICES.md)), and the Pixel 4 runs a read-only first-light probe; the Tensor phones share one initramfs, with each phone's quirks packed from its descriptor; our first kernel patch went upstream (the battery's charging status) and was reviewed; first login invites you to pick an AI agent, with none preinstalled.
- **New on 2026-10-13:** home screens with 47 built-in widgets (Simon Schubert's MIT-licensed omarchy-widgets, his OWL originals run by our own OWL runtime since 2026-10-14, plus an OWL widget Store tab with an approval sheet for what each widget may run) and your own widgets made with "Create with AI" through Omarchy's default agent, behind a crash guard; 19 quick-settings tiles with an editor; one app per screen, with a "Show with…" action; the phone's screen and input on a computer over USB (`omamobile-mirror`, `tools/phone-mirror`); a device descriptor (`device.conf`) for more than one phone; and a first installer (below), which passed its first clean reinstall.


## Google Pixel 4 XL (`coral`, Qualcomm SM8150) — What's Working & What's Not Working

> **Standalone Coral Source Tree (`v0.1.0`):** [`HemangKumawat/omarchy-mobile-coral`](https://github.com/HemangKumawat/omarchy-mobile-coral/tree/v0.1.0) · **Full Device Matrix:** [`docs/DEVICES.md`](docs/DEVICES.md) · **Bring-Up Runbook:** [`device/coral/BRINGUP-M1.md`](device/coral/BRINGUP-M1.md) · **Hardware Log:** [`device/coral/NOTES.md`](device/coral/NOTES.md)

| Subsystem | Status | Hardware / Driver | Details & Verification |
| :--- | :---: | :--- | :--- |
| **Boot** | **WIP** | `c2f2-0.5-8906123` ABL (`android-v2`), `6.17.0-sm8150` | Boots to Arch Linux ARM (`systemd`) via direct ABL header-v2 (`text_offset = 0x80000`, `lz4 -9` frame `04 22 4d 18`, 12-entry board-matched `sm8150-google-coral.dtb` + 12-entry no-op `dtbo.img`), RAM overlay on `ext4` `userdata` (`LABEL=omarchy-root`), and kernel `qcom-pon` reboot-reason latch (`0x88f = 2`). |
| **Storage** | **testing** | UFS 2.1 (`ufshcd-qcom`, `sda`..`sdf`) | All 6 UFS LUNs enumerate; all 79 `sd*` block nodes forced `ro=1` via `blockdev --setro` in PID 1 (`userdata` mounted `ro,noload`). |
| **Display** | **testing** | Samsung `AMB623RT01` (`panel-samsung-s6e3hc2`) | Native **1440x3040 @ 60 Hz** (`19:9`), VESA DSC 1.1 (`720x1520` slices, 8 bpc), 10-bit MIPI DCS backlight (`0..1023`), Wayland (`cage`) + DRM atomic KMS. |
| **GPU** | **testing** | Qualcomm Adreno 640 (`msm_dreno` / Freedreno `FD640`) | `a640_sqe.fw` + `a640_gmu.bin` at `180..585 MHz`; OpenGL ES 3.2 & Vulkan 1.3 (Mesa Turnip). |
| **Touch** | **testing** | STMicroelectronics FingerTip `fts` (`0x49` on `spi0`) | 10-finger multitouch (`1439x3039`) + double-tap wake (`KEY_WAKEUP`); all NVRAM/flash/calibration/CRC auto-reflash paths blocked in kernel (`coral-fts-readonly.patch`). |
| **Buttons** | **testing** | `gpio-keys` + PM8150 `pon` `resin` | Volume Up (`KEY_VOLUMEUP`) and Power (`KEY_POWER`) verified via `libinput`. |
| **USB net** | **testing** | `dwc3-qcom` ConfigFS (`ncm.usb0` + `rndis.usb0`) | Static `172.16.42.1/24` + DHCP (`172.16.42.2`..`172.16.42.50`) + `sshd`. |
| **Wi-Fi** | **testing** | Qualcomm `WCN3990` (`ath10k_snoc`, `wlan0`) | Dual-band 802.11ac WPA2 association, DHCP, DNS, and HTTPS verified with `rmtfs -r -P -s` and read-only `tqftpserv`. |
| **Bluetooth** | **WIP** | Qualcomm `WCN3990` (`btqca` / `hci_uart` on `serial0-0`) | `serial0-0` UART (`qcom,wcn3990-bt`) configured in DT; `bluetoothd` HCI bring-up in progress. |
| **Battery** | **testing** | PM8150B `qcom-fg` (`pm8150b-fg`) + Maxim `max1720x` (`0x36`) | Dual fuel gauges live; PMIC SRAM word 328 die/batt temperature (`coral-fg-temp.patch`) and `max17301` non-volatile alert guard (`coral-gauge1730x.patch`). |
| **Charging** | **testing** | PM8150B SMB5 (`qcom-smbx`) | Corrected SMB5 scaling (`3.60 V + N * 10 mV`, `50 mA` steps) clamped in kernel `smb_probe` to **`4.20 V` (`0x1070 = 0x3c`)** and **`500 mA` (`0x1061 = 0x0a`)**; stock hardware JEITA (`0x1090 = 0xdf`) untouched. |
| **Haptics** | **testing** | Cirrus Logic `CS40L25A` (`0x43` on `i2c9`) | Ported `cs40l2x` + `input_ff` (`FF_PERIODIC`, `FF_CONSTANT`, `FF_GAIN`); bounded closed-loop `Redc` / `F0` read from read-only `/run/coral-persist/haptics/cs40l25a.cal`. |
| **Torch** | **testing** | PM8150L `qcom,spmi-flash-led` (`led-0` / `led-1`) | Dual rear warm/cool white LEDs capped in DT at `60 mA` torch (`led-max-microamp = <60000>`). |
| **GNSS** | **no** | PDS service on MPSS/QDSP6 | Not brought up yet. |
| **AoC / DSPs** | **testing** | Qualcomm `ADSP`, `CDSP`, `SLPI` (`remoteproc` + FastRPC) | All 4 Hexagon DSPs (`adsp`, `cdsp`, `slpi`, `mpss`) running; `hexagonrpcd` serves SLPI registry from RAM-backed `tmpfs` (`openat2` guard; 123/123 `persist` files SHA-256 verified unchanged). |
| **Speakers / mics** | **testing** | QDSP6 + dual `CS35L36` (`0x40`/`0x41`) + Knowles `IA8508` (`spi2.0`) | Stereo speakers clamped in kernel to **`-26.0 dB` (`608`)** digital ceiling, **`0 dB` (`0`)** read-only analog gain, and **`4.5 V` / `1600 mA`** boost limit (verified in a 23m10s continuous voice soak with 0 XRUNs); 3-mic capture live via `IA8508` runtime firmware push. |
| **Sensors** | **testing** | SLPI SSC QMI (`qcom_ssc_boroughs`) | Accelerometer (`BMI160`), gyroscope (`BMI160`), magnetometer (`AK0991X`), barometric pressure (`BMP380`), ambient light (`TCS3701`), and proximity (`TCS3701`) live at 10–100 Hz. |
| **Soli 60 GHz Radar** | **testing** | Infineon BGT60TR13C (`google.sensor.radar` on SLPI) | Presence, range (cm), approach/depart speed, and reach gesture streaming over SLPI QMI without proprietary vendor daemon. |
| **Modem** | **testing** | Snapdragon X24 (`qcom-q6v5-mss`, `remoteproc3`) | MPSS boots to `running` via `rmtfs -r -P -s` (RAM-only EFS) and read-only `tqftpserv` serving `mcfg_sw.mbn`; cellular data/voice not enabled yet. |
| **NFC** | **no** | ST21NFCD | Not in DT yet. |
| **Cameras** | **testing** | Qualcomm Titan 170 `sm8150-camss` (5 sensors) | All 5 sensors (`IMX363` wide, `IMX481` tele, `IMX355` front, dual `VD6281` NIR) stream pristine 10-bit bayer/mono frames; **`LM36011` (`0x64` flood / `0x65` dot projector) IR drivers unbound/unloaded (`OFF`)**. |
| **Suspend** | **WIP** | System / display idle | Screen blanking via DPMS/backlight (`0`) and double-tap touch wake (`KEY_WAKEUP`) work; deep PSCI system `s2idle` / `mem` suspend is `WIP`. |
| **Fingerprint** | **-** | N/A | Hardware does not have a fingerprint reader (`coral` uses dual NIR cameras; IR emitters kept `OFF`). |

---

## Quick start

The installer is new: expect rough edges. You need a Pixel 7 Pro with an unlocked bootloader, an Omarchy (Arch) laptop with Docker, `android-tools` and `e2fsprogs`, and Google's factory image for the phone. Stock Android stays on slot A as the way back; installing erases `userdata`.

```sh
tools/build-packages                 # Omarchy Mobile's packages for aarch64 (out/repo)
tools/build-rootfs                   # the root image: Arch Linux ARM, Omarchy, our packages
tools/install-phone --dry-run        # phone in fastboot: checks it, asks for your user, shows every command
tools/install-phone                  # writes only slot B's boot images and userdata
tools/phone-provision FACTORY.zip    # after the first boot: firmware from your own factory image
```

The kernel and boot images come from `bin/omamobile kernel`, `modules`, `initramfs` and `images` (CONTRIBUTING.md §4). Step by step, with what to expect at each point: [device/cheetah/REINSTALL-RUNBOOK.md](device/cheetah/REINSTALL-RUNBOOK.md).

## Layout

| Path | What it is |
| --- | --- |
| `bin/omamobile` | Build and flash tooling: `capture`, `kernel`, `modules`, `initramfs`, `images`, `flash`, `push`, `kexec`, `fastboot` |
| `tools/build-packages`, `tools/build-rootfs`, `tools/install-phone`, `tools/phone-provision`, `tools/make-bundle` | The installer: aarch64 packages and the root image built on the laptop, the narrow fastboot installer, per-phone provisioning, release bundles (`rootfs/` holds the image's package lists; `tests/` their tests) |
| `tools/` | Staged bring-up and capture tools, on-phone probes, firmware extraction from the user's factory image, package and repository helpers |
| `packages/` | pacman packages: `omamobile-shell` (the phone profile for Omarchy's shell), `omamobile-apps` (the mobile apps desktop Omarchy lacks: Camera, Maps, NFC), `omacam` (the camera app, built from its own repository), `omamobile-device-cheetah` (Pixel 7 Pro support), `omamobile-device-felix` (Pixel Fold), `omamobile-sensors` (sensors and auto-rotate through the AoC), `omamobile-gnss` (location on demand), `omamobile-mirror` (the phone's screen and input on a computer over USB, VNC), `omamobile-audio` (PipeWire and speaker protection), `omamobile-speaker-tuning` (stock's speaker tuning, off by default), `omamobile-fingerprint` with a patched `libfprint`, `omamobile-modem` (the modem's vendor chroot profile), `omamobile-modem-sit` (the SIT client daemon; talks to the modem, registration untested), `omamobile-mmd` (ModemManager's D-Bus API in front of it, for GNOME Calls, Chatty and NetworkManager), `neard`, `omamobile-keyring` (the `[omamobile]` repository's signing key), patched `mesa` and `hyprland`. `tools/phone-install-package` builds one on the phone and installs it |
| `patches/omarchy/` | Changes to Omarchy for touch devices, to send upstream (`bridge-*` ones are stopgaps for the phone's older Omarchy); a link to `packages/omamobile-omarchy/patches`, whose pacman hook re-applies them after every Omarchy upgrade |
| `bin/lineage-ref` | Builds LineageOS for the phone. Used as a rooted reference Android (M0) and, later, for Waydroid images |
| `kernel/configs/` | Our kernel config fragment, merged on top of arm64 `defconfig` |
| `device/cheetah/` | Pixel 7 Pro bring-up notes, one plan per subsystem, overlays, the initramfs and the device descriptor (`device.conf`) |
| `device/<codename>/` | The other devices' descriptors, notes and bring-up plans (`felix`, `oriole`, `flame`, `husky`, `tegu`) |
| `omamobile.conf` | Shared settings (source dir, jobs, container image). Override in `omamobile.local.conf` |
| `docker/` | Ubuntu 24.04 build environment |
| `docs/DEVICES.md` | Supported-devices matrix |
| `docs/ROADMAP.md` | Where things stand and the plan to a working phone |
| `docs/RELEASES.md` | How builds and releases work for several devices: device descriptors, the kernel package, release bundles |

Large trees live outside the repo, under `~/android/`:

| Path | Contents |
| --- | --- |
| `~/android/omamobile` | LineageOS 24.0 source. Includes Google's GPL Pixel 7 kernel at `out-kernel/google/gs-6.1` |
| `~/android/mainline/linux` | Our kernel repo: branch `omamobile` on mainline v7.3-rc6 (remote `upstream` is Linus's tree), one commit per subsystem so patches can go upstream. Published to [derekross/linux-omarchy-mobile](https://github.com/derekross/linux-omarchy-mobile) by `tools/publish-kernel` (a squashed upstream base, our commits unchanged on top) |
| `~/android/mainline/pmos-tensor` | postmarketOS Tensor kernel, for reference |
| `~/android/reference` | Captures from the phone. Contains serial numbers and partition backups: never commit |
| `~/android/factory` | Verified stock factory images, used to restore the phone |

## Ground rules

- We only ever flash the boot images and userdata. Never `bootloader`, `radio`, `devinfo`, `persist` or calibration partitions.
- **Licensing:** this repository is MIT ([LICENSE](LICENSE)) except where a file's SPDX header says otherwise. Kernel patches (and the board dtbo source) are GPL-2.0. The port of Google's Apache-2.0 boot-control code keeps that licence and Google's notice (`packages/omamobile-device-cheetah/src/omamobile-bootctl.c`). Every file we write carries an SPDX header.
- Google's proprietary firmware and binaries are never committed: our scripts extract them from the user's own factory image.
- No code from unlicensed sources. Google's GPL kernel, upstream Linux, postmarketOS and Mesa are fine.

## Contributing

Bringing up another device, fixing a driver or improving the phone shell: start with [CONTRIBUTING.md](CONTRIBUTING.md). It covers the safety model (stock Android stays on slot A, the read-only storage guard, backups, dead-man switches), the build and flash loop, a step-by-step guide to bringing up a new device, and how to submit kernel and package changes. AI coding agents should also read [AGENTS.md](AGENTS.md). The status of each device is in [docs/DEVICES.md](docs/DEVICES.md), and what's next in [docs/ROADMAP.md](docs/ROADMAP.md).
