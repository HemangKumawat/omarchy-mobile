<!-- SPDX-License-Identifier: MIT -->
# Pixel 4 XL (coral): direct ABL boot and guarded storage bring-up

Status (2026-10-22): direct Android Bootloader (`ABL`) boot to native Arch Linux
ARM / Omarchy 4.0.4 + Hyprland on `6.17.0-sm8150`, built from
[the SM8150 kernel tree at commit `6963e3800a8e`][sm8150-kernel] (three commits
past tag [`v6.17.0-sm8150` (`379d8fe35c7c`)][sm8150-tag]), plus the ordered
`coral` kernel patch series, device trees, userspace patches, and initramfs
published in [`HemangKumawat/omarchy-mobile-coral`, tag `v0.2.2`][coral-repo]
(`8f9d23841b6caf667dc2d37e95a842d63dd9e047`, which is `v0.2.1`
(`a77eedd13359ad91df05508ebe6ce6bdbbf992bc`) plus a corrected kernel commit list
in `PROVENANCE.md`; see
[`PROVENANCE.md`][coral-provenance] for byte-level verification of the installed
kernel `Image` and 12-entry DTB).

This bring-up is not yet built by `bin/omamobile` in this repository, and
`coral` does not yet have a `CONTRIBUTING.md` §3.1 GPT boot-success exception or
`tools/install-phone` integration. The `device/coral/device.conf` descriptor
sets `BOOT_METHOD=android-v2` and `COMPATIBLE="google,coral"` (matching line 1
of [`sm8150-google-coral.dts`][coral-dts]) so `bin/omamobile` and
`tools/install-phone` refuse `DEVICE=coral` before touching a phone (`coral`
uses Android boot image header v2 with `boot` and `dtbo` partitions only; there
is no `vendor_boot`, `init_boot`, or `vendor_kernel_boot`).

[sm8150-kernel]: https://gitlab.postmarketos.org/soc/qualcomm-sm8150/linux/-/commit/6963e3800a8e5bf05d198c4481690814c8ab8651
[sm8150-tag]: https://gitlab.postmarketos.org/soc/qualcomm-sm8150/linux/-/tree/v6.17.0-sm8150
[coral-repo]: https://github.com/HemangKumawat/omarchy-mobile-coral/tree/v0.2.2
[coral-provenance]: https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/PROVENANCE.md
[coral-dts]: https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/dts/sm8150-google-coral.dts

## 1. Sources and provenance

- **Kernel base:** [the SM8150 kernel tree at commit `6963e3800a8e`][sm8150-kernel]
  ("power: supply: idtp9418: remove unused variable"), which is three commits
  ahead of tag [`v6.17.0-sm8150` (`379d8fe35c7c`)][sm8150-tag] on `sm8150/6.17`
  (`53a8b55839d1`, `01fc3dd3c831`, `6963e3800a8e`, each the parent of the next).
- **Authoritative ordered kernel series ([`PROVENANCE.md`][coral-provenance]):**
  - [`kernel/series/coral-30/`](https://github.com/HemangKumawat/omarchy-mobile-coral/tree/v0.2.2/kernel/series/coral-30)
    (patches `0001`..`0007` + `config`): `git am` on `6963e3800a8e` produces git
    tree `21eb1828b205f86d87333e77179e03a8f5b930b3`, which built the installed
    Kernel `#30` `Image` (`6.17.0-sm8150 #30 SMP PREEMPT Mon Oct 19 21:29:48 CEST 2026`,
    proven byte-identical to the installed `boot_a` `Image` except byte 10 where
    `tools/pack-bootimg.py` sets `text_offset = 0x80000`).
  - [`kernel/series/coral-fec40357/`](https://github.com/HemangKumawat/omarchy-mobile-coral/tree/v0.2.2/kernel/series/coral-fec40357)
    (patches `0008`..`0011` + `config`, and combined [`kernel/patches/series`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/series)):
    `git am` on top of `coral-30` produces git tree
    `6d4115553ae5a9aec7b9e4ae23f77b2e4c4d7c4e`, which built the 12-entry
    installed DTB (`tools/build-kernel.sh <src> <out> --with-fec40357`, proven
    byte-for-byte identical at `sha256: 3efe241aa349ff260ef0312e1b0a3a611943f71b0939261729c42e3842c90058`)
    and the SLPI, audio, and camera modules.
- **Per-topic kernel DTS and patches in [`HemangKumawat/omarchy-mobile-coral` (`v0.2.2`)][coral-repo]:**
  - Device trees:
    [`kernel/dts/sm8150-google-coral.dts`][coral-dts],
    [`kernel/dts/sm8150-google-coral-audio.dtsi`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/dts/sm8150-google-coral-audio.dtsi),
    [`kernel/dts/sm8150-google-coral-cameras.dtsi`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/dts/sm8150-google-coral-cameras.dtsi).
  - Base DTS & S6E3HC2 panel:
    [`0001-coral-base-dts-and-s6e3hc2-panel.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/0001-coral-base-dts-and-s6e3hc2-panel.patch),
    [`0002-coral-wifi-bt-firmware-dts.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/0002-coral-wifi-bt-firmware-dts.patch),
    [`coral-dt1.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/coral-dt1.patch),
    [`coral-daily-dt.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/coral-daily-dt.patch),
    [`coral-safety-dt.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/coral-safety-dt.patch).
  - Early-boot PON Fastboot recovery latch:
    [`qcom-pon-recovery.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/qcom-pon-recovery.patch).
  - DSI & display:
    [`coral-dsi-clock.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/coral-dsi-clock.patch),
    [`coral-dsi-transfer-clocks.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/coral-dsi-transfer-clocks.patch),
    [`coral-panel-brightness.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/coral-panel-brightness.patch),
    [`coral-panel-daily.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/coral-panel-daily.patch),
    [`coral-panel-power-mode-daily.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/coral-panel-power-mode-daily.patch).
  - Touchscreen read-only guard & wake:
    [`coral-fts-readonly.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/coral-fts-readonly.patch),
    [`coral-touch-wake.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/coral-touch-wake.patch).
  - Charger, fuel gauge & haptics:
    [`coral-charge.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/coral-charge.patch),
    [`coral-fg-temp.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/coral-fg-temp.patch),
    [`coral-gauge1730x.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/coral-gauge1730x.patch),
    [`coral-cs40l2x-port.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/coral-cs40l2x-port.patch).
  - SLPI, audio & cameras:
    [`coral-slpi.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/coral-slpi.patch),
    [`coral-audio.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/coral-audio.patch),
    [`kernel/audio/sm8150-coral.h`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/audio/sm8150-coral.h),
    [`kernel/patches/camera/001..033`](https://github.com/HemangKumawat/omarchy-mobile-coral/tree/v0.2.2/kernel/patches/camera),
    [`kernel/patches/face/leds-lm3601x-coral-off.h`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/face/leds-lm3601x-coral-off.h).
- **Userspace patches, initramfs & self-contained build tools (`v0.2.2`):**
  - [`userspace/hexagonrpc/hexagonrpc-ram-registry.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/userspace/hexagonrpc/hexagonrpc-ram-registry.patch) (against [`linux-msm/hexagonrpc`](https://github.com/linux-msm/hexagonrpc) `da7a3742ab8d`),
  - [`userspace/tqftpserv/0001-translate-serve-readonly-vendor-mbn-Pixel-MCFG-from-.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/userspace/tqftpserv/0001-translate-serve-readonly-vendor-mbn-Pixel-MCFG-from-.patch) (against [`linux-msm/tqftpserv`](https://github.com/linux-msm/tqftpserv) `a9bde2f`),
  - [`initramfs/init`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/initramfs/init) and [`initramfs/omarchy-userspace.sh`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/initramfs/omarchy-userspace.sh),
  - [`tools/build-kernel.sh`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/tools/build-kernel.sh), [`tools/pack-matched-dtb.py`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/tools/pack-matched-dtb.py), [`tools/pack-bootimg.py`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/tools/pack-bootimg.py), [`tools/build-rootfs.py`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/tools/build-rootfs.py), and [`tools/battery-status.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/tools/battery-status.patch).

## 2. Slots, development handset state (do not copy), and guarded install path

- **Bootloader versions on both slots [V]:**
  Both slot A and slot B run bootloader **`c2f2-0.5-8906123`** (from Google's
  final Android 13 build `TP1A.221005.002.B2`, `coral-tp1a.221005.002.b2`).

- **Development handset state — historical record, do not copy [V]:**
  - On our development handset, the installed mainline `boot` and matched
    12-entry no-op `dtbo` images are on **slot A** (`boot_a` and `dtbo_a`),
    `vbmeta_a` was flashed with verification disabled (`--disable-verity
    --disable-verification`), and `userdata` (`sda15`) was formatted as
    unencrypted `ext4` (`LABEL=omarchy-root`).
  - **Do not copy this handset state.** Under `omarchy-mobile` rules
    ([`CONTRIBUTING.md` §3.1](../../CONTRIBUTING.md#31-stock-android-stays-on-slot-a)),
    `vbmeta` and slot A must never be modified. Because `userdata` on this
    development handset was formatted `ext4` and our kernel occupies `boot_a`,
    stock Android's untouched `boot_b`/`dtbo_b` on slot B cannot complete
    userspace boot without reformatting `userdata`. **This unit has no working
    stock fallback slot; recovery requires reaching Fastboot (via buttons, the
    `qcom-wdt` hardware watchdog, or the `qcom-pon` reboot latch) and flashing
    a Google factory image, which wipes the Arch root.**
  - Why slot A ended up carrying our image on this unit: during initial Oct
    12–13 trials with legacy LZ4 (`lz4 -l`) on `boot_a` before the `04 22 4d 18`
    frame requirement was found, `c2f2` ABL decremented `slot-retry-count:a` to
    `0`, marked `slot-unbootable:a: yes`, and fell back to `slot b`
    (`current-slot: b`, `slot-successful:b: yes`, `slot-unbootable:b: no`,
    `slot-retry-count:b: 0`). Subsequent bring-up flashed `boot_a`/`dtbo_a` and
    formatted `userdata` as `ext4` `omarchy-root`.
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

- **How GPT attribute bit 54 on `boot_a` was set once on 2026-10-18 (historical, do not repeat) [V]:**
  - On the Pixel 4 / 4 XL family, slot flags live in the UFS LUN 0 (`/dev/sda`)
    GPT partition entry attributes (`boot_a` is partition 6 `/dev/sda6`,
    `boot_b` is partition 7 `/dev/sda7`), and `fastboot flash boot_<slot>` clears
    bit 54 (`slot-successful:<slot>: no`) while resetting
    `slot-retry-count:<slot>` to `3`.
  - On 2026-10-18, after RAM-proving the candidate image and confirming SSH over
    USB NCM, GPT attribute bit 54 on `/dev/sda6` (`boot_a`) was set **once by
    hand over SSH** (never from a service or boot script) as follows:
    1. Verified `blockdev --getro /dev/sda15` (`userdata`) reported `1` (read-only)
       and backed up the primary/backup GPT sectors to `/run/coral-gpt-backup`
       with `sfdisk --backup-pt-sectors=/run/coral-gpt-backup /dev/sda` plus
       `sfdisk --json /dev/sda > /run/coral-gpt-before.json` (`boot_a`
       `attrs="GUID:48,49,50,51"`, `boot_b` `attrs="GUID:49,54"`).
    2. Under `trap 'blockdev --setro /dev/sda' EXIT HUP INT TERM`, briefly cleared
       the whole-disk read-only flag (`blockdev --setrw /dev/sda`), ran:
       ```sh
       sfdisk --no-reread --no-tell-kernel --lock=yes \
         --part-attrs /dev/sda 6 "GUID:48,49,50,51,54"
       ```
       and immediately restored `blockdev --setro /dev/sda`.
    3. Verified with `sfdisk --verify /dev/sda`, `blockdev --getro /dev/sda` (`1`),
       `blockdev --getro /dev/sda15` (`1`), and a `diff` of `sfdisk --json /dev/sda`
       confirming that only partition 6's `attrs` field changed from
       `"GUID:48,49,50,51"` to `"GUID:48,49,50,51,54"`.
  - Steady-state `fastboot getvar` values recorded afterwards:
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
  - **Policy note (`CONTRIBUTING.md` §3.1):** Writing GPT sectors on `/dev/sda`
    from Linux is **not** permitted until `coral` has its own explicit entry in
    [`CONTRIBUTING.md` §3.1](../../CONTRIBUTING.md#31-stock-android-stays-on-slot-a)
    naming the device (`coral`), the UFS LUN (`/dev/sda`), the four GPT sectors
    (LBAs 1, 2, last-1, and last), the attribute bit (`bit 54`), the header and
    entry-array CRCs rewritten, the before/after slot flags, the GPT rollback
    procedure, and the recovery path. `coral` cannot inherit `flame`'s pending
    entry ([#58](https://github.com/derekross/omarchy-mobile/pull/58)).

- **Guarded install and slot B recipe (untested on this handset; pending `CONTRIBUTING.md` §3.1 entry):**
  - Any permanent installation on a second `coral` phone must go through the
    guarded installer (`tools/install-phone`, which pins the device serial,
    requires typing the codename, checks an allowlist, and runs a `--dry-run`
    first) once `coral`'s `CONTRIBUTING.md` §3.1 entry and `android-v2` support
    land, keeping stock Android untouched on **slot A** (`boot_a`, `dtbo_a`, and
    stock `vbmeta` untouched) and flashing only **slot B** (`fastboot
    --set-active=b`, `fastboot flash boot_b boot.img`, `fastboot flash dtbo_b
    dtbo.img`) and `userdata`.
  - **Untested on this handset:**
    1. *Slot B installation:* Because this bring-up ran on `boot_a`/`dtbo_a`,
       the slot B recipe (`--set-active=b`, `boot_b`, `dtbo_b`) has **not** been
       tested on this `coral` unit.
    2. *Stock `vbmeta` verification with unsigned `boot.img`:* Our `boot.img`
       carries an unsigned 64 MiB AVB hash footer (`avbtool add_hash_footer
       --algorithm NONE`). Because `vbmeta_a` on the test handset had already
       been flashed with `--disable-verity --disable-verification` prior to this
       bring-up, whether `c2f2-0.5-8906123` ABL accepts an unsigned
       `--algorithm NONE` `boot_b` image when stock `vbmeta_b` verification is
       still enabled is **untested on `coral`**.
    3. *3-unmarked-boots ABL fallback and stock `userdata` prompt:* Flashing
       `boot_b` clears `slot-successful:b` (`no`) and sets `slot-retry-count:b`
       to `3`. Without a `CONTRIBUTING.md` §3.1 boot-success step, `c2f2` ABL
       allows 3 unmarked boots on slot B before marking `slot-unbootable:b: yes`
       and falling back to stock Android on slot A. If `userdata` holds an Arch
       `ext4` filesystem, stock Android on slot A cannot mount `userdata` and
       displays a recovery screen prompting for a **Factory data reset**—**decline
       it** and reboot to Fastboot so the Arch root is not wiped. If stock
       Android ever boots on slot A, take a fresh modem/persist backup afterwards
       ([`CONTRIBUTING.md` §3.3](../../CONTRIBUTING.md#33-back-up-and-checksum-before-anything-risky))
       because stock's modem stack writes `modemst1`, `modemst2`, and `persist`.

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
     in [`tools/pack-bootimg.py`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/tools/pack-bootimg.py),
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
     `libufdt` overlay pass. In [`tools/pack-matched-dtb.py`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/tools/pack-matched-dtb.py)
     (and `tools/build-kernel.sh --with-fec40357`), 12 copies of
     `sm8150-google-coral.dtb` are stamped with the 12 factory
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
| Kernel payload | `Image.offset80000.lz4` (`04 22 4d 18` frame, `text_offset=0x80000`) | [V] [`tools/pack-bootimg.py`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/tools/pack-bootimg.py) |
| DTB payload | 12-entry board-matched `sm8150-google-coral.dtb` (`qcom,msm-id` + `qcom,board-id`, built with `dtc -@`, `sha256: 3efe241a...`) | [V] [`tools/pack-matched-dtb.py`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/tools/pack-matched-dtb.py) |
| Command line (`CONFIG_CMDLINE_FORCE=y`) | `rootwait ro rdinit=/init console=ttyAMA0,115200 console=ttyMSM0,115200n8 console=tty0 clk_ignore_unused pd_ignore_unused loglevel=7 coral.rescue panic=10 panic_on_oops=1 softlockup_panic=1 hung_task_panic=1 hung_task_timeout_secs=30` | [V] [`tools/build-kernel.sh`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/tools/build-kernel.sh) |

*Note on root device discovery vs UFS LUN ordering:* Rather than trusting a
hardcoded `root=/dev/sda15` on the kernel command line,
[`initramfs/omarchy-userspace.sh`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/initramfs/omarchy-userspace.sh)
resolves the root partition dynamically via **`findfs LABEL=omarchy-root`** (with
`PARTLABEL=userdata` / `UUID=` recommended over `/dev/sda15`). On SM8150 UFS,
SCSI disk letters can reorder across reboots (`userdata` was observed shifting
from `/dev/sda15` to `/dev/sdb15` during display gate testing).

## 5. Storage guard, watchdog across `chroot`, `qcom-pon` latch, and security notes

1. **Read-only UFS block guard (`blockdev --setro`) [V]:**
   - In [`initramfs/omarchy-userspace.sh`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/initramfs/omarchy-userspace.sh),
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

2. **Staged read-only modem/EFS partition backup gate (`PARTNAME` dump) before the next boot:**
   - Before the initial Oct 12 bring-up, we backed up `boot_a/b`, `dtbo_a/b`,
     `vbmeta_a/b`, `persist`, and the partition table, but did not take raw
     `dd` images of `modemst1`, `modemst2`, `fsg`, `fsc`, `modem_a`, and
     `modem_b`. The development handset is currently powered off and unplugged.
   - Before the next boot that starts `mpss` on this handset, a read-only
     `PARTNAME` dump of `modemst1`, `modemst2`, `fsg`, `fsc`, `persist`,
     `modem_a`, and `modem_b` + `SHA256SUMS` (stored off-repository in private
     reference storage, never committed) is staged as a hard pre-radio gate:
     ```sh
     for want in modemst1 modemst2 fsg fsc persist modem_a modem_b; do
       for u in /sys/class/block/sd*/uevent; do
         if grep -qx "PARTNAME=$want" "$u"; then
           dev="/dev/$(basename "$(dirname "$u")")"
           [ "$(blockdev --getro "$dev")" = "1" ] || exit 1
           dd if="$dev" bs=4M status=none | sha256sum
         fi
       done
     done
     ```
     Note that this checksum baseline comes *after* the 12–22 October bring-up
     sessions rather than before the first boot.

3. **Hardware watchdog (`qcom-wdt`) across `chroot` into Arch [V]:**
   - [`initramfs/init`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/initramfs/init)
     starts BusyBox `watchdog -T 20 -t 5 /dev/watchdog0` (`17c10000.watchdog`
     built-in with `CONFIG_QCOM_WDT=y` and `CONFIG_WATCHDOG_NOWAYOUT=y`, 20 s
     hardware timeout, 5 s pet interval) in the initramfs root namespace.
   - Instead of `switch_root`, [`initramfs/omarchy-userspace.sh`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/initramfs/omarchy-userspace.sh)
     transitions into Arch via
     `exec chroot /newroot /usr/lib/systemd/systemd --unit=graphical.target`.
     Because `chroot` keeps the initramfs root alive, the BusyBox `watchdog`
     daemon continues running under PID 1 for the entire lifetime of the Arch
     session and pets `/dev/watchdog0` every 5 seconds.

4. **Kernel `qcom-pon` Fastboot recovery latch and early vs standalone `initramfs/init` health loop [V]:**
   - **No userspace code writes PMIC registers.** In
     [`kernel/patches/qcom-pon-recovery.patch`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/kernel/patches/qcom-pon-recovery.patch),
     `qcom_pon_probe()` in `drivers/power/reset/qcom-pon.c` checks
     `of_machine_is_compatible("google,coral")` and immediately writes `2`
     (bootloader/Fastboot) to `PON_SOFT_RB_SPARE` (`0x88f`) via the kernel's
     SPMI `regmap`, logging `"coral Fastboot recovery armed before userspace"`.
   - The driver registers a kernel reboot notifier (`coral_reboot_notify`) and
     a boolean driver sysfs attribute `coral_healthy` (initialized to `0`). Any
     kernel panic, `emergency_restart`, hardware watchdog bite, or reboot while
     `coral_healthy == 0` leaves `PON_SOFT_RB_SPARE` at `2` so `c2f2` ABL stops
     in Fastboot.
   - **Early tethered rescue initramfs vs 22 October standalone `initramfs/init`:**
     In the early tethered rescue initramfs (used during Oct 18–21 bring-up,
     still visible in `v0.1.0`), the background health loop checked
     `/sys/class/udc/*/state == configured` every 10 seconds after the 120-second
     lease and executed `/bin/reboot-bootloader` if USB was unplugged. In the
     22 October standalone build published in `v0.2.1`
     ([`initramfs/init`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/initramfs/init)),
     the post-lease check requires only `/proc/1/comm == systemd` and a live
     `/usr/bin/sshd` process (`check_control_ready` without requiring an active
     USB host), writes `1` to `/sys/bus/platform/drivers/qcom-pon/*/coral_healthy`,
     and stays up across unplugged battery boots.

5. **Development image physical-access warning (unauthenticated `ttyGS0` root shell & empty root password in RAM) [V]:**
   - [`initramfs/init`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/initramfs/init)
     spawns an unauthenticated root shell (`setsid /bin/sh </dev/ttyGS0 >/dev/ttyGS0 2>&1`)
     on the USB CDC ACM serial gadget (`ttyGS0`), and
     [`initramfs/omarchy-userspace.sh`](https://github.com/HemangKumawat/omarchy-mobile-coral/blob/v0.2.2/initramfs/omarchy-userspace.sh)
     sets an empty password for `root` in the RAM overlay copy of `/etc/shadow`
     (`root::...`). While network SSH (`sshd`) is restricted to key-only
     authentication (`PasswordAuthentication no`), **anyone with physical USB
     cable access to this development image has immediate root access.** Production
     packaging must disable the unauthenticated `ttyGS0` shell and lock the root
     account.

## 6. Evidence from the phone, kernel build provenance, and owner confirmation

**Owner confirmation:** `@HemangKumawat`, as the owner of the Pixel 4 XL
development handset, explicitly authorized and approved every flash performed
during this bring-up.

**Which kernel commit/series built each kernel cited below ([`PROVENANCE.md`][coral-provenance]):**
- **Installed `boot_a` kernel (`#30`, `Mon Oct 19 21:29:48 CEST 2026`):**
  Built from public commit `6963e3800a8e` + [`kernel/series/coral-30`](https://github.com/HemangKumawat/omarchy-mobile-coral/tree/v0.2.2/kernel/series/coral-30)
  (patches `0001`..`0007`, git tree `21eb1828b205f86d87333e77179e03a8f5b930b3`,
  proven byte-identical to the installed `boot_a` `Image` except byte 10
  `text_offset = 0x80000`), paired with the 12-entry DTB and modules built from
  `coral-30` + [`kernel/series/coral-fec40357`](https://github.com/HemangKumawat/omarchy-mobile-coral/tree/v0.2.2/kernel/series/coral-fec40357)
  (patches `0008`..`0011`, git tree `6d4115553ae5a9aec7b9e4ae23f77b2e4c4d7c4e`,
  proven byte-identical `dtb-12` at `sha256: 3efe241aa349ff260ef0312e1b0a3a611943f71b0939261729c42e3842c90058`).
- **Earlier bring-up kernels (`#3`, `#25`, `#27`):**
  - `#3` (`Sun Oct 18 00:34:15 CEST 2026`, first rescue kernel): built at
    `5a951e9017ef` (`coral-30` patches `0001`..`0002`) with local display/touch/PON
    working-tree changes later committed in `472bb39eac2a` (`0005`).
  - `#25` (`Mon Oct 19 06:07:50 CEST 2026`, RAM-booted SLPI/audio bring-up
    kernel): built from the working tree leading to `65adbcf4ac89`..`52f2c29b0a60`
    (`0001`..`0009`).
  - `#27` (`Mon Oct 19 12:31:53 CEST 2026`, RAM-booted five-camera bring-up
    kernel): built from the working tree leading to `d3dd05299ff8`..`fec403571c23`
    (`0001`..`0011`).

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
  (on the RAM-booted audio/SLPI kernel `#25`:
  `Linux coral 6.17.0-sm8150 #25 SMP PREEMPT Mon Oct 19 06:07:50 CEST 2026 aarch64 GNU/Linux`;
  and on the installed `boot_a` kernel `#30`:
  `Linux version 6.17.0-sm8150 (builder@localhost) (aarch64-linux-gnu-gcc (GCC) 16.1.0 20260409 (experimental), GNU ld (GNU Binutils) 2.47.50.20260409) #30 SMP PREEMPT Mon Oct 19 21:29:48 CEST 2026`).

- **Read-only state across all 79 UFS block nodes (`lsblk -o NAME,RO,RM,SIZE,TYPE,MOUNTPOINTS` / `/sys/class/block/sd*/ro`):**
  Every `sd*` whole-disk and partition node (`sda`..`sdf` and `sda1`..`sdf6`,
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

- **USB gadget state (`/sys/class/udc/*/state`, `ip -br addr show usb0`, `UDCARGS`):**
  ```
  /sys/class/udc/a600000.usb/state: configured
  usb0             UP             172.16.42.1/30 fe80::.../64
  idVendor=0x18d1 idProduct=0x4ee3 manufacturer="Google" product="Pixel 4 XL" serialnumber="<SERIAL>" functions=ncm.usb0+acm.gs0
  ```

- **Hardware watchdog and PON recovery state:**
  ```
  qcom-wdt 17c10000.watchdog: initialized (timeout=20 sec, nowayout=1)
  qcom-pon c440000.spmi:pmic@0:pon@800: coral Fastboot recovery armed before userspace
  /sys/bus/platform/drivers/qcom-pon/c440000.spmi:pmic@0:pon@800/coral_healthy: 1
  ```

## 7. Gates and rollback

A record of the gates this bring-up used, corrected for this unit. On this
development handset slot A carries the mainline image and `userdata` is `ext4`
(see §2), so there is no stock fallback slot: the way back from every gate is
Fastboot and a Google factory image, which wipes the Arch root. Slot B is
untested on this unit.

| Gate | Expect / pass | Stop condition | Rollback (this unit) |
| --- | --- | --- | --- |
| Stock capture and backups | The Google factory image for `coral` (`TP1A.221005.002.B2`) is downloaded and checksum-verified off the phone before any flash; the read-only modem/EFS/`persist` dump of §5 item 2, with `SHA256SUMS`, is taken before the next boot that starts `mpss` | Factory image missing or unverified; any partition unreadable or not `ro` | None needed (read-only). Note: on this unit the 12–22 October radio sessions ran before that dump |
| Direct ABL boot and USB NCM | `uname -r` reports `6.17.0-sm8150`; `ssh root@172.16.42.1` connects over `usb0`; `qcom-wdt` active | Hang, watchdog reset loop, or no USB enumeration within 60 s | Reach Fastboot (hold Power about 15 s so the `qcom-pon` latch or `qcom-wdt` resets into Fastboot, or Volume Down + Power), then flash the factory image. Slot B is untested |
| Read-only storage boundary | Every `/sys/class/block/sd*/ro` reads `1`; `/` is `overlay` over a read-only `/lower` (`LABEL=omarchy-root`) | Any physical partition reports `ro=0` in the default mode | Stop at once; reach Fastboot and flash the factory image. Slot B is untested |
| KMS display, GPU and touch | `msm_dpu` + `S6E3HC2` at `1440x3040@60Hz`; Adreno 640 (`FD640`) renders Hyprland; `fts` touch events with the flash-write path disabled | Blank panel, FIFO underrun storm, or touch SPI fault | Reach Fastboot and flash the factory image. Slot B is untested |
