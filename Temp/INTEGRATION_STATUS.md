# A7Z OpenWrt Integration Status

## Current state

The repository has three separate build paths:

- OpenWrt 24.10 with Linux 6.6 is the established CI baseline; A7Z produced a successful artifact in run `44216787167`.
- OpenWrt 24.10 with Linux 6.18 is experimental. A7A/A7Z configuration succeeds, but the previous firmware run failed while compiling mac80211 backports 6.12.44 against Linux 6.18 APIs (`netns_local`, timer and socket symbols). The workflow now substitutes OpenWrt 25.12's mac80211 6.18.55 package and compatibility patches; this change is not yet verified by CI. Separately, the earlier `kmod-nf-flow` missing `nf_tables.ko` package dependency has been fixed by adding `kmod-nft-core`.
- OpenWrt 25.12 has no native A7Z target. A parent-repository overlay adds the A7Z profile, DTS/BSP integration, vendor boot image layout and U-Boot package to `sunxi/cortexa53`, and selects Linux 6.18. Its first CI attempts reached defconfig but failed on recursive virtual-package provider dependencies. The overlay now backports a self-provider filter with a regression test; additional config-key and kernel metadata path corrections are awaiting CI.

No 25.12 or Linux 6.18 image is considered successful until the workflow's firmware verification step passes and a non-placeholder artifact is present.

## Integrated pieces

1. The active 24.10 source contains the A7Z profile, Allwinner BSP overlay, A7Z/SoC DTS files, vendor image helper, extlinux configuration and prebuilt U-Boot files.
2. The 6.18 kernel config selects known Sun60IW2 BSP Kconfig symbols. It no longer contains the earlier invalid OpenWrt package selector `CONFIG_KMOD_CEDAR_VPU`; Cedar VPU availability is still unverified.
3. `scripts/apply-openwrt-25.12-overlay.sh` prepares the pinned 25.12 source without modifying the upstream submodule commit and applies parent-repo patches for device image generation, the DTS registration, virtual dependency handling and the `nf-flow` module dependency.
4. The independent workflows build OpenWrt 24.10/Linux 6.6, OpenWrt 24.10/Linux 6.18 (A7A/A7Z), and OpenWrt 25.12/Linux 6.18 (A7Z), with build logs and artifacts uploaded for diagnosis. The 6.18 workflow temporarily replaces the 24.10 mac80211 package with pinned 25.12 package source to use matching backports 6.18.55.

## Remaining verification

1. Complete the current Linux 6.18 A7A and A7Z builds and verify the firmware artifact check.
2. Rerun 25.12 after the provider filter, correct device config symbol (`radxa_cubie_a7z`) and `target/linux/generic/kernel-6.18` metadata are included; verify defconfig and image packaging.
3. Boot the resulting A7Z image on hardware and test storage, networking, USB, PCIe, GPIO and LED.
4. The DTS property `skip-uboot-pcie-training` has no known active U-Boot consumer in this repository; the prebuilt U-Boot's behavior remains unknown.
5. Do not treat the Cedar VPU config or driver as enabled/working without a matching Kconfig/package definition and runtime evidence.
