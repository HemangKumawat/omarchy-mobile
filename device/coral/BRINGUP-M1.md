<!-- SPDX-License-Identifier: MIT -->
# Pixel 4 XL (coral): direct ABL boot and guarded storage bring-up

Status (2026-10-22): direct Android Bootloader (`ABL`) boot to native Arch Linux
ARM / Omarchy 4.0.4 + Hyprland on `6.17.0-sm8150`, built from
[the SM8150 kernel tree, tag `v6.17.0-sm8150`][sm8150-kernel] (`6963e3800a8e`),
plus the `coral` device trees, kernel patches, userspace patches, and initramfs
published in [`HemangKumawat/omarchy-mobile-coral`, tag `v0.1.0`][coral-repo]
(`e59e1a035d786b8e392080adec10fa28bd55f4ad`).

This bring-up is not yet built by `bin/omamobile` in this repository. The
`device/coral/device.conf` descriptor sets `BOOT_METHOD=android-v2` and
`COMPATIBLE="google,coral"` (matching line 1 of
[`sm8150-google-coral.dts`][coral-dts]) so `bin/omamobile` and
`tools/install-phone` refuse `DEVICE=coral` before touching a phone (`coral`
uses Android boot image header v2 with `boot` and `dtbo` partitions only; there
is no `vendor_boot`, `init_boot`, or `vendor_kernel_boot`).

[sm8150-kernel]: https://gitlab.postmarketos.org/soc/qualcomm-sm8150/linux/-/tree/v6.17.0-sm8150
[coral-repo]: https://github.com/HemangKumawat/omarchy-mobile-coral/tree/v0.1.0
[coral-dts]: https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/dts/sm8150-google-coral.dts

## 1. Sources

- **Kernel base:** [the SM8150 kernel tree, tag `v6.17.0-sm8150`][sm8150-kernel]
  (commit `6963e3800a8e`).
- **Coral DTS and kernel patches:** [`HemangKumawat/omarchy-mobile-coral` (`v0.1.0`)][coral-repo]:
  - Device trees:
    [`kernel/dts/sm8150-google-coral.dts`][coral-dts],
    [`kernel/dts/sm8150-google-coral-audio.dtsi`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/dts/sm8150-google-coral-audio.dtsi),
    [`kernel/dts/sm8150-google-coral-cameras.dtsi`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/dts/sm8150-google-coral-cameras.dtsi).
  - Base DTS & S6E3HC2 panel:
    [`0001-coral-base-dts-and-s6e3hc2-panel.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/0001-coral-base-dts-and-s6e3hc2-panel.patch),
    [`0002-coral-wifi-bt-firmware-dts.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/0002-coral-wifi-bt-firmware-dts.patch),
    [`coral-dt1.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-dt1.patch),
    [`coral-daily-dt.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-daily-dt.patch),
    [`coral-safety-dt.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-safety-dt.patch).
  - Early-boot PON Fastboot recovery latch:
    [`qcom-pon-recovery.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/qcom-pon-recovery.patch).
  - DSI & display:
    [`coral-dsi-clock.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-dsi-clock.patch),
    [`coral-dsi-transfer-clocks.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-dsi-transfer-clocks.patch),
    [`coral-panel-brightness.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-panel-brightness.patch),
    [`coral-panel-daily.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-panel-daily.patch),
    [`coral-panel-power-mode-daily.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-panel-power-mode-daily.patch).
  - Touchscreen read-only guard & wake:
    [`coral-fts-readonly.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-fts-readonly.patch),
    [`coral-touch-wake.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-touch-wake.patch).
  - Charger, fuel gauge & haptics:
    [`coral-charge.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-charge.patch),
    [`coral-fg-temp.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-fg-temp.patch),
    [`coral-gauge1730x.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-gauge1730x.patch),
    [`coral-cs40l2x-port.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-cs40l2x-port.patch).
  - SLPI, audio & cameras:
    [`coral-slpi.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-slpi.patch),
    [`coral-audio.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/coral-audio.patch),
    [`kernel/audio/sm8150-coral.h`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/audio/sm8150-coral.h),
    [`kernel/patches/camera/001..033`](https://github.com/HemangKumawat/omarchy-mobile-coral/tree/v0.1.0/kernel/patches/camera),
    [`kernel/patches/face/leds-lm3601x-coral-off.h`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/face/leds-lm3601x-coral-off.h).
- **Userspace patches, initramfs & build scripts:**
  - [`userspace/hexagonrpc/hexagonrpc-ram-registry.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/userspace/hexagonrpc/hexagonrpc-ram-registry.patch) (against [`linux-msm/hexagonrpc`](https://github.com/linux-msm/hexagonrpc) `da7a3742ab8d`),
  - [`userspace/tqftpserv/0001-translate-serve-readonly-vendor-mbn-Pixel-MCFG-from-.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/userspace/tqftpserv/0001-translate-serve-readonly-vendor-mbn-Pixel-MCFG-from-.patch) (against [`linux-msm/tqftpserv`](https://github.com/linux-msm/tqftpserv) `a9bde2f`),
  - [`initramfs/init`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/initramfs/init) and [`initramfs/omarchy-userspace.sh`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/initramfs/omarchy-userspace.sh),
  - [`tools/build-kernel.sh`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/tools/build-kernel.sh), [`tools/pack-matched-dtb.py`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/tools/pack-matched-dtb.py), [`tools/pack-bootimg.py`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/tools/pack-bootimg.py), and [`tools/build-rootfs.py`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/tools/build-rootfs.py).

## 2. Slots and development handset state

- **Bootloader versions on both slots [V]:**
  Both slot A and slot B run bootloader **`c2f2-0.5-8906123`** (from Google's
  final Android 13 build `TP1A.221005.002.B2`, `coral-tp1a.221005.002.b2`).
- **Development handset slot history (`boot_a` / `dtbo_a`) [V]:**
  - On our development handset, the installed mainline `boot` and matched
    12-entry no-op `dtbo` images are on **slot A** (`boot_a` and `dtbo_a`, with
    `vbmeta_a` verification disabled), and `userdata` holds the `ext4` root
    filesystem (`LABEL=omarchy-root`).
  - Why slot A was used on this handset: during initial Oct 12–13 trials with
    legacy LZ4 (`lz4 -l`) on `boot_a` before the `04 22 4d 18` frame requirement
    was identified, `c2f2` ABL decremented `slot-retry-count:a` to `0`, marked
    `slot-unbootable:a: yes`, and fell back to `slot b` (`current-slot: b`,
    `slot-successful:b: yes`, `slot-unbootable:b: no`, `slot-retry-count:b: 0`),
    where stock Android's `boot_b` and `dtbo_b` remained untouched. However,
    once shared `userdata` was formatted as unencrypted `ext4` (`omarchy-root`),
    stock Android on slot B could no longer complete userspace boot without
    reformatting `userdata`.
  - On the Pixel 4 / 4 XL family, slot flags live in the UFS LUN 0 (`sda`) GPT
    partition entry attributes (`boot_a` at `/dev/sda6`, `boot_b` at
    `/dev/sda7`), and running `fastboot flash boot_<slot>` clears GPT bit 54
    (`slot-successful:<slot>: no`) while resetting `slot-retry-count:<slot>` to
    `3`.
  - Recorded `fastboot getvar` slot variables on the development handset
    immediately after `fastboot flash boot_a`:
    ```
    version-bootloader: c2f2-0.5-8906123
    current-slot: a
    slot-successful:a: no
    slot-unbootable:a: no
    slot-retry-count:a: 3
    slot-successful:b: yes
    slot-unbootable:b: no
    slot-retry-count:b: 0
    ```
  - After RAM-proving the candidate image and setting GPT attribute bit 54 on
    `boot_a` (`attrs="GUID:48,49,50,51,54"` alongside `boot_b`
    `attrs="GUID:49,54"`), the steady-state `fastboot getvar` values across
    M1–M6 are:
    ```
    version-bootloader: c2f2-0.5-8906123
    current-slot: a
    slot-successful:a: yes
    slot-unbootable:a: no
    slot-retry-count:a: 3
    slot-successful:b: yes
    slot-unbootable:b: no
    slot-retry-count:b: 0
    ```
- **Prescribed slot for dual-boot / runbook reproduction (`boot_b` / `dtbo_b`):**
  On a stock phone where slot A is preserved as a working stock Android slot
  (with `userdata` untouched during RAM-only bring-up), always target **slot B**
  explicitly (`fastboot --set-active=b`, `fastboot flash boot_b boot.img`,
  `fastboot flash dtbo_b dtbo.img`), and roll back by flashing stock `boot_b`
  and `dtbo_b`.

## 3. Why stock SM8150 ABL rejects unmodified mainline boot images (and the fix)

On the Pixel 4 / 4 XL bootloader (`c2f2-0.5-8906123`, `msmnile` / `SM8150`),
flashing or `fastboot boot`-ing a standard mainline `Image.gz` or legacy-LZ4
`boot.img` fails in `ABL` before the kernel reaches `earlycon`. Three distinct
bootloader invariants must be satisfied for direct `ABL` boot without a U-Boot
intermediate stage:

1. **ARM64 `Image` `text_offset` must be `0x80000`, not `0x0` [V]:**
   - Stock Android 13 (`4.14.276`) was built before Linux 5.8 changed the
     ARM64 `Image` header `text_offset` from `0x80000` to `0x0`.
   - `c2f2` ABL's Linux loader does not honour `text_offset = 0x0` properly when
     placing the decompressed kernel at `base + kernel_offset` (`0x00008000`),
     causing an immediate placement failure prior to kernel entry.
   - Setting the 64-bit little-endian `text_offset` field at byte offset `8` of
     `arch/arm64/boot/Image` to `0x80000` (`struct.pack_into('<Q', raw, 8, 0x80000)`
     in [`tools/pack-bootimg.py`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/tools/pack-bootimg.py),
     or `emit_64(0x80000)` in `arch/arm64/kernel/head.S`) makes the mainline
     `Image` header byte-compatible with `c2f2` ABL's placement logic.

2. **Modern LZ4 frame magic (`04 22 4d 18`), not legacy LZ4 (`02 21 4c 18`) or gzip [V]:**
   - Stock `boot.img` on `coral` packs its kernel payload as a **modern LZ4 frame**
     (`lz4 -9 -q Image.offset80000 Image.offset80000.lz4`, magic bytes
     `04 22 4d 18`), whereas `lz4 -l` emits legacy framing (`02 21 4c 18`) used
     by later Tensor bootloaders.
   - `c2f2` ABL's decompressor expects the `04 22 4d 18` frame magic and rejects
     legacy `02 21 4c 18` payloads.

3. **Board-matched appended DTB (`qcom,msm-id` + `qcom,board-id`) and matched 12-entry no-op `dtbo.img` [V]:**
   - `c2f2` ABL selects the base DTB from the `boot.img` DTB payload by matching
     `qcom,msm-id` (`<0x153 0x20000>` for SM8150 v2 and `<0x153 0x10000>` for
     SM8150 v1) and `qcom,board-id`.
   - Each DTB is compiled with `dtc -@` so `/__symbols__` is present for ABL's
     `libufdt` overlay pass. In [`tools/pack-matched-dtb.py`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/tools/pack-matched-dtb.py),
     12 copies of `sm8150-google-coral.dtb` are stamped with the 12 factory
     `(qcom,msm-id, qcom,board-id)` selector pairs from stock `dtbo.img`
     (with MP1.0 matching index 11: `board-id = <0x00020305 0x00010000>`), and
     paired with a 12-entry no-op `dtbo.img` (`fragment@0` targeting
     `target-path = "/"` with an empty `__overlay__ {}`) so ABL's `libufdt`
     merge succeeds cleanly without mutating any mainline DT node.

## 4. Boot image parameters (`mkbootimg` header v2)

| Parameter | Value | Source |
| --- | --- | --- |
| Header version | `2` | [V] stock `boot.img` header |
| Page size | `4096` | [V] stock `boot.img` header |
| Base / kernel / ramdisk / second / tags / dtb offsets | `0x00000000` / `0x00008000` / `0x01000000` / `0x00000000` / `0x00000100` / `0x01f00000` | [V] `unpack_bootimg` on stock `TP1A.221005.002.B2` |
| OS version / patch level | `13.0.0` / `2022-10` | [V] stock `boot.img` header |
| Kernel payload | `Image.offset80000.lz4` (`04 22 4d 18` frame, `text_offset=0x80000`) | [V] [`tools/pack-bootimg.py`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/tools/pack-bootimg.py) |
| DTB payload | 12-entry board-matched `sm8150-google-coral.dtb` (`qcom,msm-id` + `qcom,board-id`, built with `dtc -@`) | [V] [`tools/pack-matched-dtb.py`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/tools/pack-matched-dtb.py) |
| Command line (`CONFIG_CMDLINE_FORCE=y`) | `rootwait ro rdinit=/init console=ttyAMA0,115200 console=ttyMSM0,115200n8 console=tty0 clk_ignore_unused pd_ignore_unused loglevel=7 coral.rescue panic=10 panic_on_oops=1 softlockup_panic=1 hung_task_panic=1 hung_task_timeout_secs=30` | [V] [`tools/build-kernel.sh`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/tools/build-kernel.sh) |

*Note on root device discovery vs UFS LUN ordering:* Rather than trusting a
hardcoded `root=/dev/sda15` on the kernel command line,
[`initramfs/omarchy-userspace.sh`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/initramfs/omarchy-userspace.sh)
resolves the root partition dynamically via **`findfs LABEL=omarchy-root`** (with
`PARTLABEL=userdata` / `UUID=` recommended over `/dev/sda15`). On SM8150 UFS,
SCSI disk letters can reorder across reboots (`userdata` was observed shifting
from `/dev/sda15` to `/dev/sdb15` during display gate testing).

## 5. Storage guard, watchdog across `chroot`, and kernel `qcom-pon` recovery latch

1. **Read-only UFS block guard (`blockdev --setro`) [V]:**
   - In [`initramfs/omarchy-userspace.sh`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/initramfs/omarchy-userspace.sh),
     PID 1 runs a two-pass `for device in /dev/sd* /dev/vd* /dev/mmcblk*; do blockdev --setro "$device"; done`
     loop before starting `systemd`: once immediately after `findfs LABEL=omarchy-root`
     (before mounting `/lower`), and a second time after mounting the read-only
     radio/vendor layers right before `exec chroot`. (It is a two-pass boot
     guard rather than a continuous background uevent watcher for PID 1's whole
     life.)
   - `userdata` (`LABEL=omarchy-root`) is mounted `ro,noload` at `/lower` under
     a RAM `overlayfs` (`upperdir=/run/overlay/upper`,
     `workdir=/run/overlay/work`).
   - *Why the installed image stays on the RAM overlay rather than persistent
     `sda15` writes:* in an experimental persistent-overlay test on 2026-10-22,
     making `/dev/sda15` writable required clearing the kernel read-only flag on
     **both `/dev/sda15` and its parent whole-disk node `/dev/sda`** (`sda=0,
     sda15=0`, while `sda1`..`sda14` and `sdb`..`sdf` remained `ro=1`), because
     Linux's `bdev_read_only()` checks both the partition `bd_read_only` flag
     and the parent `gendisk` read-only flag. Because `sda=0` would leave raw
     whole-disk `/dev/sda` LBA writes unblocked by `bdev_read_only()`, the
     installed `boot_a` image keeps all 79 `sd*` nodes (including `sda` and
     `sda15`) at `ro=1`.
   - Modem EFS/NV serving (`rmtfs`) runs strictly with `-r -P -s` (read-only
     memory mode, zero writes to `modemst1`, `modemst2`, `fsg`, or `fsc`).

2. **Hardware watchdog (`qcom-wdt`) across `chroot` into Arch [V]:**
   - [`initramfs/init`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/initramfs/init)
     starts BusyBox `watchdog -T 20 -t 5 /dev/watchdog0` (`17c10000.watchdog`
     built-in with `CONFIG_QCOM_WDT=y` and `CONFIG_WATCHDOG_NOWAYOUT=y`, 20 s
     hardware timeout, 5 s pet interval) in the initramfs root namespace.
   - Instead of `switch_root`, [`initramfs/omarchy-userspace.sh`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/initramfs/omarchy-userspace.sh)
     transitions into Arch via
     `exec chroot /newroot /usr/lib/systemd/systemd --unit=graphical.target`.
     Because `chroot` keeps the initramfs root alive, the BusyBox `watchdog`
     daemon continues running under PID 1 for the entire lifetime of the Arch
     session and pets `/dev/watchdog0` every 5 seconds.

3. **Kernel `qcom-pon` Fastboot recovery latch (`qcom-pon-recovery.patch`) [V]:**
   - **No userspace code writes PMIC registers.** In
     [`kernel/patches/qcom-pon-recovery.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.1.0/kernel/patches/qcom-pon-recovery.patch),
     `qcom_pon_probe()` in `drivers/power/reset/qcom-pon.c` checks
     `of_machine_is_compatible("google,coral")` and immediately writes `2`
     (bootloader/Fastboot) to `PON_SOFT_RB_SPARE` (`0x88f`) via the kernel's
     SPMI `regmap`, logging `"coral Fastboot recovery armed before userspace"`.
   - The driver registers a kernel reboot notifier (`coral_reboot_notify`) and
     a boolean driver sysfs attribute `coral_healthy` (initialized to `0`). Any
     kernel panic, `emergency_restart`, hardware watchdog bite, or reboot while
     `coral_healthy == 0` leaves `PON_SOFT_RB_SPARE` at `2` so `c2f2` ABL stops
     in Fastboot.
   - After 120 seconds of healthy uptime (USB gadget configured + `systemd` PID
     1 + `sshd` running), the initramfs health loop writes `1` to the boolean
     flag `/sys/bus/platform/drivers/qcom-pon/*/coral_healthy`. Only when
     `coral_healthy == 1` does an orderly normal reboot cause the kernel's
     `coral_reboot_notify()` callback to clear `PON_SOFT_RB_SPARE` back to `0`.

## 6. Evidence from the phone and owner confirmation

**Owner confirmation:** `@HemangKumawat`, as the owner of the Pixel 4 XL
development handset, explicitly authorized and approved every flash performed
during this bring-up.

Why `tools/phone-smoke` was not run directly: the bring-up was completed on
2026-10-18..2026-10-22 prior to opening PR #52, the handset is currently powered
off after the 2026-10-22 standalone unplugged test, and the image uses the
SM8150 `chroot` overlay layout without Tensor `devinfo`. Below are the exact
outputs recorded from the handset over SSH (`root@172.16.42.1`) during bring-up
verification (with the USB serial redacted to `<SERIAL>`):

- **`uname -a` / `uname -r`:**
  ```
  Linux localhost 6.17.0-sm8150 #3 SMP PREEMPT Sun Oct 18 00:34:15 CEST 2026 aarch64 GNU/Linux
  ```
  (and on the daily/camera kernel build:
  `Linux coral 6.17.0-sm8150 #25 SMP PREEMPT Mon Oct 19 06:07:50 CEST 2026 aarch64 GNU/Linux`).

- **Read-only state across all 79 UFS block nodes (`lsblk -o NAME,RO,RM,SIZE,TYPE,MOUNTPOINTS` / `/sys/class/block/sd*/ro`):**
  Every `sd*` whole-disk and partition node (`sda`..`sdf` and `sda1`..`sdf5`,
  79 nodes total) reports `RO=1`:
  ```
  NAME    RO RM  SIZE TYPE MOUNTPOINTS
  sda      1  0 58.1G disk
  |-sda1   1  0    8K part
  |-sda2   1  0   32M part
  |-sda3   1  0    1M part
  |-sda4   1  0  512K part
  |-sda5   1  0  512K part
  |-sda6   1  0   64M part
  |-sda7   1  0   64M part
  |-sda8   1  0   96M part
  |-sda9   1  0   96M part
  |-sda10  1  0   64M part
  |-sda11  1  0   64M part
  |-sda12  1  0    8M part
  |-sda13  1  0    8M part
  |-sda14  1  0  9.1G part
  `-sda15  1  0 48.7G part /lower
  sdb      1  0    4M disk
  `-sdb1   1  0    3M part
  sdc      1  0    4M disk
  `-sdc1   1  0    3M part
  sdd      1  0  128M disk
  |-sdd1   1  0   32K part
  ...
  sdf      1  0  256M disk
  |-sdf1   1  0    4K part
  |-sdf2   1  0    2M part
  |-sdf3   1  0    2M part
  |-sdf4   1  0    2M part
  |-sdf5   1  0  128K part
  `-sdf6   1  0    4K part
  ```

- **Root filesystem and read-only lower mount (`/proc/mounts` / `findmnt /` equivalent):**
  ```
  overlay / overlay rw,relatime,lowerdir=/lower,upperdir=/run/overlay/upper,workdir=/run/overlay/work,uuid=on 0 0
  /dev/sda15 /lower ext4 ro,relatime,norecovery 0 0
  ```

## 7. Gates and rollback

| Gate | Expect / pass | Stop condition | Rollback |
| --- | --- | --- | --- |
| Stock capture & partition backups | Off-device backups of stock `boot_a/b`, `dtbo_a/b`, `persist`, and factory image verified before flashing | Any unreadable partition | None (read-only) |
| Direct ABL boot & USB NCM | `uname -r` reports `6.17.0-sm8150`; `ssh root@172.16.42.1` connects over `usb0`; `qcom-wdt` active | Hang, watchdog reset, or no USB enumeration within 60 s | Hold Power ~15 s (PON latch enters Fastboot) or Volume Down + Power; flash stock `boot_b` and `dtbo_b` (or `boot_a` and `dtbo_a` on the dev handset) |
| Read-only storage boundary | Every `/sys/class/block/sd*/ro` reads `1`; `/` is `overlay` over `ro,norecovery` `/lower` (`LABEL=omarchy-root`) | Any physical partition reports `ro=0` in default mode | Stop immediately; reboot to Fastboot and flash stock `boot_b` and `dtbo_b` |
| KMS display, GPU & touch | `msm_dpu` + `panel-samsung-s6e3hc2` at `1440x3040@60Hz`; Adreno 640 (`FD640`) renders Hyprland; `fts` touch events with flash-write path disabled | Blank panel, FIFO underrun storm, or touch I2C/SPI fault | Revert overlay/module in initramfs and reflash `boot_b` and `dtbo_b` |
