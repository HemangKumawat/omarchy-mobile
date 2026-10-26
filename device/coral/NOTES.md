<!-- SPDX-License-Identifier: MIT -->
# Pixel 4 XL (coral) bring-up notes

Findings from real hardware (`google,coral`, Qualcomm `SM8150` / Snapdragon 855,
kernel `6.17.0-sm8150` built from
[the SM8150 kernel tree, tag `v6.17.0-sm8150`][sm8150-kernel] (`6963e3800a8e`),
plus the `coral` patches, device trees, userspace patches, and initramfs in
[`HemangKumawat/omarchy-mobile-coral`, tag `v0.1.0`][coral-repo]
(`e59e1a035d786b8e392080adec10fa28bd55f4ad`)), newest first.

[sm8150-kernel]: https://gitlab.postmarketos.org/soc/qualcomm-sm8150/linux/-/tree/v6.17.0-sm8150
[coral-repo]: https://github.com/HemangKumawat/omarchy-mobile-coral/tree/v0.1.0

## 2026-10-22: standalone unplugged boot, guarded persistence, and mobile shell

- **Unplugged boot and reboot verified on battery power [V]:**
  - Decoupled the early-bringup USB-disconnect `reboot-bootloader` trap from
    the USB gadget helper while retaining BusyBox `watchdog -T 20 -t 5 /dev/watchdog0`
    (`qcom-wdt`, 20 s hardware timeout petted every 5 s across `chroot`) and
    the kernel `qcom-pon` Fastboot reboot-reason latch
    ([`qcom-pon-recovery.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/qcom-pon-recovery.patch)).
  - **How the `qcom-pon` reboot-reason latch works (kernel SPMI `regmap`, zero userspace PMIC writes) [V]:**
    - In `drivers/power/reset/qcom-pon.c`
      ([`qcom-pon-recovery.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/qcom-pon-recovery.patch)),
      `qcom_pon_probe()` checks `of_machine_is_compatible("google,coral")` and
      immediately writes `2` (bootloader/Fastboot) to `PON_SOFT_RB_SPARE`
      (`0x88f`) via the kernel's SPMI `regmap` (`qcom_pon_reboot_mode_write()`),
      before userspace starts.
    - The driver registers a kernel reboot notifier (`coral_reboot_notify`) and
      exposes a boolean driver sysfs flag `coral_healthy` (initialized to `0`).
      Any kernel panic, `emergency_restart`, hardware watchdog bite, or reboot
      while `coral_healthy == 0` leaves `PON_SOFT_RB_SPARE` at `2` so `c2f2`
      ABL stops in Fastboot.
    - After 120 seconds of healthy uptime (USB gadget + `systemd` + `sshd`), the
      initramfs health loop writes `1` to `coral_healthy`. Only when
      `coral_healthy == 1` does an orderly normal reboot cause the kernel's
      `coral_reboot_notify()` callback to write `0` to `PON_SOFT_RB_SPARE`.
      Userspace never touches PMIC registers directly.
  - **How `qcom-wdt` is fed after transitioning to Arch [V]:**
    - [`initramfs/init`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/initramfs/init)
      starts BusyBox `watchdog -T 20 -t 5 /dev/watchdog0` in the initramfs root
      namespace, and
      [`initramfs/omarchy-userspace.sh`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/initramfs/omarchy-userspace.sh)
      transitions into Arch via
      `exec chroot /newroot /usr/lib/systemd/systemd --unit=graphical.target`
      rather than `switch_root`. Because `chroot` retains the initramfs root
      namespace, the BusyBox `watchdog` daemon stays alive under PID 1 for the
      entire Arch session and pets `/dev/watchdog0` every 5 seconds.
  - Verified across an unplugged cold boot and an orderly `systemctl reboot`
    with USB disconnected: the phone boots to Hyprland (`1440x3040@60Hz`),
    associates to WPA2 Wi-Fi automatically (`wlan0`), and answers SSH over Wi-Fi
    while keeping `usb0` (`172.16.42.1/30`, CDC NCM + ACM) ready for hotplug.
- **Read-only UFS guard (`blockdev --setro`) and experimental persistent-overlay finding [V]:**
  - In [`initramfs/omarchy-userspace.sh`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/initramfs/omarchy-userspace.sh),
    PID 1 runs a two-pass `for device in /dev/sd* /dev/vd* /dev/mmcblk*; do blockdev --setro "$device"; done`
    guard before starting `systemd` (once right after `findfs LABEL=omarchy-root`
    before mounting `/lower`, and a second time after mounting the read-only
    radio/vendor layers right before `exec chroot`), and mounts `userdata`
    (`LABEL=omarchy-root`) `ro,noload` under a RAM `overlayfs`.
  - In an experimental persistent-overlay test on 2026-10-22 (run via RAM boot,
    not installed in `boot_a`), making `/dev/sda15` writable required clearing
    the read-only flag on **both `/dev/sda15` (`userdata`) and its parent
    whole-disk node `/dev/sda`** (`sda=0, sda15=0`, while `sda1`..`sda14` and
    `sdb`..`sdf` stayed `ro=1`), because Linux's `bdev_read_only()` checks both
    the partition node and the parent `gendisk` read-only flag. Because `sda=0`
    would leave raw whole-disk `/dev/sda` LBA writes unblocked by
    `bdev_read_only()`, the installed image remains on the default RAM-only
    overlay where all 79 `sd*` nodes (including `sda` and `sda15`) stay `ro=1`.

## 2026-10-21: five-camera CAMSS streaming, dual OV7251 NIR stereo, LM36011 off-proof, and torch proof

- **All five camera sensors verified streaming over `sm8150-camss` [V]:**
  - Patched `sm8150-camss`
    ([`kernel/patches/camera/001..033`](https://github.com/HemangKumawat/omarchy-mobile-coral/tree/v0.1.0/kernel/patches/camera))
    with a 150 MHz `camnoc_axi` floor (`clk_set_min_rate` in `camss.c`),
    CAMNOC QoS programming (`camss-vfe-17x.c`), 3-phase C-PHY configuration
    (`camss-csiphy-3ph-1-0.c` + `camss-csiphy-sm8150-combo.h`), and 4-VC
    `csid-gen2` routing for all five sensors on `coral`
    ([`sm8150-google-coral-cameras.dtsi`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/dts/sm8150-google-coral-cameras.dtsi)):
    1. **Rear wide (`imx363`, 12.2 MP, CCI0):** continuous V4L2 raw streaming
       (`1932` frames over 60 s, `0` sequence gaps) and full-resolution colour
       capture via `libcamera` 0.7.2 simple pipeline + CPU software ISP.
    2. **Rear telephoto (`imx481`, 16 MP, CCI0):** continuous V4L2 raw streaming
       (`1832` frames over 60 s, `0` sequence gaps) and `libcamera` software ISP
       capture.
    3. **Front selfie (`imx520`, 8 MP, CCI1):** continuous V4L2 raw streaming
       (`1828` frames over 60 s, `0` sequence gaps) and `libcamera` software ISP
       capture.
    4. **Front NIR stereo pair (`ov7251` master `5-0072` & slave `5-0070`, `640x480` Y10/Y8):**
       both sensors share CCI I2C bus 1 and `mclk4` (`24 MHz`), with separate
       resets (`GPIO 118` master, `GPIO 109` slave) and hardware frame sync
       (`FSIN` wired from master `STROBE` `0x3005=0x08` to slave `FSIN`
       `0x3006=0x00`, `0x3823=0x30`, `0x3826=0x23`). Verified simultaneous
       stereo streaming (`1829` + `1828` frames over 60 s, `0` sequence gaps)
       and rectified stereo depth map generation.
- **Confirmation that nothing writes to the `LM36011` IR emitters (`0x64` flood and `0x65` dot projector) [V]:**
  - On `coral`, `i2c1` (`geniqup@8c0000/i2c@88c000`) hosts two TI `LM36011` IR
    laser/LED drivers behind a Silego/Dialog GreenPAK hardware safety state
    machine: `0x64` (`lm36011_flood`, flood illuminator) and `0x65`
    (`lm36011_dot`, dot projector).
  - **In the installed kernel and rootfs:** no `LM36011` or GreenPAK driver is
    bound or loaded (`ir_emitters: "inhibited; lm36011 unbound and unloaded"`),
    and no userspace tool ever writes to `i2c1` `0x64` or `0x65`.
  - **In the isolated RAM-boot `leds-lm3601x-coral-off.h` diagnostic**
    ([`kernel/patches/face/leds-lm3601x-coral-off.h`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/face/leds-lm3601x-coral-off.h)):
    any non-zero brightness request is unconditionally refused (`-EPERM`,
    `"coral safety gate refuses IR emitter activation"`), and the probe path
    only writes `LM3601X_ENABLE_REG (0x01) = 0x00` (Mode=00 Standby) and reads
    back `ENABLE (0x01) == 0x00`, `LED_CUR (0x03)`, and `DEV_ID (0x06) == 0x01`
    to prove both emitters remain strictly `OFF`.
- **Torch (`led:torch_0`, `led:torch_1`) optical verification [V]:**
  - PM8150L flash LED driver exposes `/sys/class/leds/led:torch_0` and
    `led:torch_1` (plus `led:switch_0`). Verified `0 -> 1 -> 0` state transitions
    with dark-bracketed rear-camera optical response (`Y_mean` rising from
    `1.04` dark baseline to `95.36` with torch on, returning to `1.04` when
    turned off) and wired to the quick-settings Torch tile.

## 2026-10-19: QDSP6 audio (dual CS35L36 + Knowles IA8508), SLPI sensors, Bluetooth, haptics, and battery/charger

- **Speakers and microphones (`Pixel4XL` ALSA card via QDSP6) and hardware gain ceiling [V]:**
  - Brought up `qcom_q6v5_pas` (`adsp`), `q6afe`, `q6asm`, `q6adm`, `q6routing`,
    and the `sm8150-coral` machine driver
    ([`coral-audio.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-audio.patch)
    + [`sm8150-coral.h`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/audio/sm8150-coral.h)
    + [`sm8150-google-coral-audio.dtsi`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/dts/sm8150-google-coral-audio.dtsi))
    with:
    - **Dual Cirrus Logic `CS35L36` speaker amplifiers** on `i2c@c94000` (`0x40`
      bottom speaker, `0x41` top/earpiece speaker) over Tertiary MI2S (`1.536 MHz`
      bitclk, 2-slot 16-bit TDM) + Quaternary MI2S VMON/IMON feedback slots.
    - **Knowles `IA8508` smart mic DSP** over SPI (`spi@a8c000` / `spi11.0`,
      firmware `RomeApp.bin` v`6739055.p`) feeding Primary/Secondary TDM capture
      links.
  - **Enforced kernel speaker ceiling and 23-minute soak levels [V]:**
    - Because no DSP speaker-protection algorithm is running yet, the kernel
      sound card driver (`sm8150_coral_late_probe()` in
      [`sm8150-coral.h`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/audio/sm8150-coral.h))
      enforces a hard ceiling in the kernel:
      - `Top Digital PCM Volume` and `Bottom Digital PCM Volume` have their
        kernel `platform_max` clamped to **`608` (`-26.0 dB`)**
        (`#define CORAL_DIGITAL_MAX 608 /* -26 dB; speaker-protection DSP is absent. */`),
        matching [`userspace/audio/ucm2/Pixel4XL/HiFi.conf`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/userspace/audio/ucm2/Pixel4XL/HiFi.conf).
      - `Top Analog PCM Volume` and `Bottom Analog PCM Volume` are forced to
        **`0` (`0 dB`, `CORAL_ANALOG_SAFE = 0`)** in `sm8150_coral_late_probe()`
        and have `SNDRV_CTL_ELEM_ACCESS_WRITE` stripped so userspace cannot
        raise analog gain above `0`.
      - In `sound/soc/codecs/cs35l36.c`
        ([`coral-audio.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-audio.patch))
        and [`sm8150-google-coral-audio.dtsi`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/dts/sm8150-google-coral-audio.dtsi),
        the `CS35L36` boost converter is clamped to **`4.5 V`
        (`cirrus,boost-ctl-millivolt = <4500>`)** (fixing an upstream
        `cs35l36.c` bug that overwrote `bst_vctl` with `10 V`), with peak
        inductor current clamped to **`1600 mA`
        (`cirrus,boost-peak-milliamp = <1600>`)**, hardware boost current limit
        enabled (`CS35L36_AMP_DIG_VOL_CTRL2 & 7 == 5`), and thermal warning
        threshold set to `1`.
    - The 23-minute 10-second (`1,390,234 ms`, `66,707,611` PCM frames, 48 kHz
      stereo) voice/meditation soak ran under this exact kernel ceiling
      (`digital_value = 608` / `-26.0 dB`, `analogue_value = 0`, boost `4.5 V` /
      `1600 mA`, `0` XRUNs, `0` amplifier faults), and synthetic test tones in
      `coral-phone` are additionally capped at `0.25` (`-12 dBFS`) digital peak
      (`-38 dB` combined).
  - *Known gap:* on cold boot, `qcom_q6v5_pas` (`adsp`) occasionally hits a
    GLINK/APR readiness race requiring a service restart before the ALSA card
    registers; kept at `testing` until startup ordering is race-free.
- **SLPI sensor hub (`slpi.mdt` + FastRPC + QMI/QRTR SSC) and `persist` checksum verification [V]:**
  - Enabled `remoteproc_slpi` (`5c00000.remoteproc`,
    `qcom/sm8150/google/coral/slpi.mdt`), `fastrpc`
    ([`coral-slpi.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-slpi.patch)),
    and `hexagonrpcd` patched with a RAM-backed sensor registry
    ([`hexagonrpc-ram-registry.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/userspace/hexagonrpc/hexagonrpc-ram-registry.patch)).
  - At service startup
    ([`sensor-runtime.sh`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/userspace/services/sensor-runtime.sh)),
    `persist` is mounted `ro,noload,nodev,nosuid,noexec` at `/run/coral-persist`,
    copied into `tmpfs` at `/run/coral-qcom/sensors/registry`, and confined via
    `openat2(..., RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS)`. All 123 files in
    `/run/coral-persist/sensors/registry/registry` (`83,565` bytes) were SHA-256
    verified before and after the SLPI sensor and Soli sessions, matching 123/123
    on-flash files with zero writes to `persist`.
  - Verified all **7 hardware sensor streams** live over QMI/QRTR SSC (plus the
    Infineon `BGT60TR13C` 60 GHz Soli radar):
    1. Accelerometer (`LSM6DSR`, ~50 Hz, gravity vector `z ≈ 9.8 m/s²`)
    2. Gyroscope (`LSM6DSR`, ~50 Hz)
    3. Magnetometer (`~50 Hz`)
    4. Ambient light (`lux` updates verified)
    5. Proximity (`near/far` state transitions verified for screen blanking)
    6. Barometer (`~1013 hPa`)
    7. Active Edge squeeze ADC (`elmyra_raw` / `MAX11261` streaming 4 channels
       at `115 Hz`)
- **Bluetooth (`WCN3990` `hci_qca`) [V]:**
  - Loaded `btqca` and `hci_uart` over `serial0-0` with `qca/coral/crbtfw21.tlv`
    and `qca/coral/crnv21.bin` (`QCA Rome 0x3020100`, ROM `0201`).
  - `bluetoothctl show` confirms `hci0` `Powered: yes` and BLE/BR-EDR device
    discovery works. Audio routing (A2DP/HFP) and persistent pairing are still
    open (`WIP`).
- **Haptics (`CS40L25A`) [V]:**
  - Ported `cs40l2x` (`1-0043` on `i2c9`, reset GPIO, wavetable DSP;
    [`coral-cs40l2x-port.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-cs40l2x-port.patch))
    and verified stock click waveform playback.
- **Battery fuel gauge (`MAX1720x`/`MAX1730x`) and PM8150B SMB5 charger clamp (`FV 0x3c`, `FCC 0x0a`, `JEITA 0xdf`, `DMA 0x00`) [V]:**
  - **What writes the charger registers:** The **kernel driver**
    `drivers/power/supply/qcom_smbx.c` (`smb_probe()` in
    [`coral-charge.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-charge.patch))
    via SPMI `regmap`, **not** userspace.
  - **Where the values come from (SMB2 vs SMB5 step math in `qcom_smbx.c`):**
    - Upstream `qcom_smbx.c` used PMI8998/SMB2 step math (`3.4875 V + N * 7.5 mV`
      float voltage, `25 mA` current steps) on PM8150B, which is an **SMB5**
      charger (`3.60 V + N * 10 mV` at `CHGR_FLOAT_VOLTAGE_CFG` `0x1070` with
      valid codes `0x00..0x77` = `3.60..4.79 V`, and `50 mA` steps at
      `CHGR_FAST_CHARGE_CURRENT_CFG` `0x1061`, per Google's stock `qpnp-smb5.c` /
      `smb5-reg.h` / `smb5-lib.c` at commit `82a738b32e3f`).
    - Under the unpatched SMB2 formula, a `4.40 V` battery DT target wrote
      `(4400000 - 3487500) / 7500 = 121.6 -> 0x7a` (`122`) to `0x1070`, exceeding
      PM8150B's maximum valid SMB5 code (`0x77` = `4.79 V`) and pushing rested
      cell voltage to `4.447 V`.
    - [`coral-charge.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-charge.patch)
      updates `qcom_smbx.c` to use SMB5 step scaling on `pm8150b` and sets
      `voltage-max-design-microvolt = <4200000>` and
      `constant-charge-current-max-microamp = <500000>` in DT. During
      `smb_probe()`, the kernel driver disables charging (`0x1042 = 0x00`),
      writes `0x1070 = 0x3c` (`60` -> `3.60 V + 60 * 10 mV = 4.20 V`) and
      `0x1061 = 0x0a` (`10` -> `10 * 50 mA = 500 mA`), and re-enables
      `0x1042 = 0x01`.
  - **`JEITA 0xdf` vs stock:** `0x1090` (`CHGR_JEITA_EN_CFG = 0xdf`, with
    threshold registers `0x1094..0x109b = 18 11 58 1c`) is **stock's hardware /
    bootloader register configuration left completely untouched**
    (`coral-charge.patch` never writes `0x1090..0x109b`). We only read `0x1090`
    and `0x1094..0x109b` back via debugfs regmap to verify that stock's hardware
    JEITA protection (`0xdf`) remained active.
  - **`DMA 0x00`:** In `drivers/power/supply/qcom_fg.c`
    ([`coral-fg-temp.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-fg-temp.patch)),
    GEN4 fuel-gauge SRAM temperature reads (word 328) check `MEM_INTF_DMA_STS`
    (`0x4370`) for latched DMA errors (`0x00` = clean; if an earlier transaction
    latched `0x04`, the kernel driver pulses `MEM_INTF_CTL` bit 2 to clear it,
    matching stock's FG driver).

## 2026-10-16: Wi-Fi (`WCN3990`), Display (`S6E3HC2` DSC 1.1), GPU (`Adreno 640`), and Touch (`FTS`)

- **Wi-Fi (`WCN3990` via `ath10k_snoc` + `mpss` + read-only `rmtfs -r`) and modem partition protection [V]:**
  - `WCN3990` on SM8150 requires `mpss` (`4080000.remoteproc`,
    `qcom/sm8150/google/coral/modem.mdt`), `pd-mapper`, `rmtfs -r -P -s`
    serving memory-backed read-only copies of `modemst1`, `modemst2`, `fsg`, and
    `fsc`, `tqftpserv`
    ([`0001-translate-serve-readonly-vendor-mbn-Pixel-MCFG-from-.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/userspace/tqftpserv/0001-translate-serve-readonly-vendor-mbn-Pixel-MCFG-from-.patch),
    mapping `/readonly/vendor/mbn/` requests to `<rproc fw dir>/mbn/`), and
    vendor board data (`bdwlan-coral` repackaged as
    `ath10k/WCN3990/hw1.0/board-2.bin` for
    `bus=snoc,qmi-board-id=ff,qmi-chip-id=30214,variant=Google_coral`).
  - *Note on `modemst1`, `modemst2`, `fsg`, `fsc`, and `persist` backups and
    checksums:* before the initial Oct 12 bring-up, we archived the partition
    table, `getprop`, extracted vendor firmware, and factory images, and backed
    up `boot_a/b`, `dtbo_a/b`, and `persist`, but skipped taking raw `dd` image
    dumps of `modemst1`, `modemst2`, `fsg`, and `fsc`. Accordingly, we do not
    have a pre-Oct-12 raw EFS image SHA-256 to compare against. What was verified
    across every session is that: (1) `modemst1` (`sdf2`), `modemst2` (`sdf3`),
    `fsg` (`sdf4`), `fsc` (`sdf5`), and `persist` (`sda2`/`sdb2`) are locked
    `ro=1` via `blockdev --setro` in PID 1 before any service starts; (2)
    `rmtfs` runs strictly with `-r -P -s` (read-only memory mode); and (3) all
    123 files in `/run/coral-persist/sensors/registry/registry` (`83,565` bytes
    on `persist`) matched their SHA-256 checksums before and after the DSP
    sessions.
  - Verified 2.4/5 GHz scan, WPA2-PSK association (`<SSID>`), DHCPv4 lease, DNS,
    and HTTPS traffic.
- **Display (`Samsung S6E3HC2` `1440x3040@60Hz` DSC 1.1) and Backlight [V]:**
  - Mainline `msm_dpu` + `panel-samsung-s6e3hc2`
    ([`0001-coral-base-dts-and-s6e3hc2-panel.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/0001-coral-base-dts-and-s6e3hc2-panel.patch))
    drives the `1440x3040` AMOLED panel over `DSI-1` with Display Stream
    Compression (DSC 1.1, 2 slices per line, slice `720x40`, 8 bpc, `vddio`
    `1.84 V`, `vci` `3.0 V` on `l4c`, reset `tlmm 67`).
  - Patched `dsi_host.c`
    ([`coral-dsi-clock.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-dsi-clock.patch)
    and [`coral-dsi-transfer-clocks.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-dsi-transfer-clocks.patch))
    to program `DSI_6G_FIFO_TIMING = 0x0bc` and keep DSI link clocks enabled
    around `msm_dsi_host_xfer_prepare()` / `unprepare()` so 10-bit big-endian
    brightness updates (`0..1023` on `/sys/class/backlight/ae94000.dsi.0`,
    [`coral-panel-brightness.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-panel-brightness.patch))
    and DPMS off/on transitions never race link power-down.
  - *Note on 90 Hz:* 60 Hz is clean (`0` DPU underruns); an experimental 90 Hz
    mode showed startup FIFO underruns before OPP/bandwidth scaling settled and
    is left disabled by default.
- **GPU (`Qualcomm Adreno 640` / `FD640`) [V]:**
  - Loaded `msm` DRM + `a630_sqe.fw` / `a640_gmu.bin` / `a640_zap.mdt` on
    `2c00000.gpu` (`698000 kHz` max OPP); Mesa `freedreno` (`FD640`) runs
    Hyprland hardware-accelerated at `1440x3040@60Hz` (scale `3.2`) with
    `omamobile-shell` and OWL widgets.
- **Touchscreen (`STMicroelectronics FingerTip S` / `fts` on `spi0.0`) and full calibration/flash write guard [V]:**
  - In [`coral-fts-readonly.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-fts-readonly.patch)
    (`drivers/input/touchscreen/fts_touch/`), when `!info->board->auto_fw_update`
    (`st,disable-auto-fw-update` in `sm8150-google-coral.dts`), **every**
    firmware flash, panel init, CX tuning, MP-flag write, and CRC-error
    auto-reflash path is blocked:
    1. **CRC-error auto-reflash & firmware update (`fts_fw_update()` in `fts.c`):**
       returns `fts_init_sensing(info)` directly *before* `"Fw Auto Update is
       starting..."`, before `fts_crc_check()`, and before `fts_fw_updater()`,
       logging `"coral fts flash-write guard: cfgAfeVer=%02X cxAfeVer=%02X mpFlag=%02X; sensing only"`.
       In `fts_chip_powercycle()` (`fts_lib/ftsCore.c`), the reset-timeout
       recovery path also skips `fts_fw_update()`.
    2. **Panel init, CX tuning & MP-flag writes (`fts_chip_initialization()` in `fts.c`):**
       returns `ERROR_OP_NOT_ALLOW` immediately (`"coral fts: calibration flash
       writes forbidden"`), blocking `fts_production_test_main()` (panel init and
       CX tuning) and `save_mp_flag()`.
    3. **Low-level system commands (`writeSysCmd()` in `fts_lib/ftsCore.c`):**
       hard-blocks `SYS_CMD_SAVE_FLASH` and `SYS_CMD_SPECIAL` with
       `SPECIAL_PANEL_INIT`, `SPECIAL_FULL_PANEL_INIT`, or
       `SPECIAL_WRITE_HOST_MEM_TO_FLASH`, returning `ERROR_OP_NOT_ALLOW`.
    4. **Flash unlock (`flash_unlock()` in `fts_lib/ftsFlash.c`):** body replaced
       with `return ERROR_OP_NOT_ALLOW`.
    5. **Userspace maintenance interfaces (`fts.c`):** `/proc/fts`
       (`fts_driver_test_init`) is never registered, and sysfs attributes
       `fwupdate`, `autotune`, `stm_fts_cmd`, and `infoblock_getdata` are
       removed (verified absent from `System.map` by
       [`tools/pack-bootimg.py`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/tools/pack-bootimg.py)).
  - Verified full `0..1439` x `0..3039` multitouch input in Hyprland plus
    double-tap wake (`KEY_WAKEUP` / `143`,
    [`coral-touch-wake.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-touch-wake.patch)).

## 2026-10-13: stock facts and direct ABL first light

| Fact | Value | Source |
| --- | --- | --- |
| Device, codename, SoC | Google Pixel 4 XL (`coral`), Qualcomm `SM8150` (`msmnile`, SoC ID `339` rev `2.2`) | [V] stock Android 13 capture |
| Stock build, bootloader | `TP1A.221005.002.B2`, bootloader `c2f2-0.5-8906123` (both slots A and B) | [V] `fastboot getvar version-bootloader` |
| Board revision, DTBO index | `MP1.0`, `dtbo` index `11` (`board_id 0x00020305`, `board_rev 0x00010000`) | [V] stock `dtbo.img` table & `fastboot` |
| Boot partitions | `boot_a/b` (64 MiB, header v2, page size 4096, modern LZ4 kernel `04 22 4d 18`), `dtbo_a/b` (8 MiB); no `vendor_boot` or `init_boot` | [V] `unpack_bootimg` |
| RAM, storage | 6 GiB LPDDR4X, 64 GB UFS (`sda` main LUN with `sda1`..`sda15`, `sda15` = `userdata` / `LABEL=omarchy-root`) | [V] `/proc/meminfo`, `/sys/class/block` |
| Panel | Samsung `S6E3HC2` (`1440x3040`, DSC 1.1, 60/90 Hz) on `ae94000.dsi` | [V] stock DT & `msm_dpu` |
| Touch | STMicroelectronics `fts` on `spi@890000` (`spi0.0`), IRQ `tlmm 122`, reset `tlmm 123` | [V] stock DT & `/proc/bus/input/devices` |
| Wi-Fi / BT | Qualcomm `WCN3990` (`ath10k_snoc` + `hci_qca`), variant `Google_coral` | [V] stock DT & firmware |
| Audio | Qualcomm QDSP6 (`adsp`) + 2x Cirrus Logic `CS35L36` (`i2c@c94000` `0x40`/`0x41`) + Knowles `IA8508` (`spi@a8c000`) | [V] stock DT & ALSA |
| Haptics, Torch | Cirrus Logic `CS40L25A` (`i2c9` `0x43`), PM8150L flash LEDs (`led:torch_0/1`) | [V] stock DT & sysfs |
| Cameras | Rear wide `IMX363` (12.2 MP), rear tele `IMX481` (16 MP), front `IMX520` (8 MP), dual front NIR `OV7251` (`5-0072` / `5-0070`); `LM36011` (`0x64` flood, `0x65` dot) unbound/OFF | [V] media-ctl & V4L2 |
