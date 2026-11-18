# A7Z OpenWrt Integration Status

## Current state

The repository has three separate build paths:

- OpenWrt 24.10 with Linux 6.6 is the established CI baseline; A7Z produced a successful artifact in run `44216787167`.
- OpenWrt 24.10 with Linux 6.18 is experimental. A7A/A7Z configuration succeeds, and the previous mac80211 6.12.44 failures are addressed by substituting OpenWrt 25.12's mac80211 6.18.55 package. The current blocker was the sunxi BSP shim: `patches-6.18/0000-add-sunxi-bsp.patch` was untracked, so CI never applied it and DTC could not find `dt-bindings/power/sun60iw2-power.h`. It is now committed in `openwrt-sunxi-aiot` (`e2f599ea`) and additionally rewrites `dtc_cpp_flags` to use the `addprefix -I` form over `DTC_INCLUDE`, so the extra `bsp/include` directory is not passed to the compiler as a source file. Separately, the earlier `kmod-nf-flow` missing `nf_tables.ko` package dependency has been fixed by adding `kmod-nft-core`.
- OpenWrt 25.12 has no native A7Z target. A parent-repository overlay adds the A7Z profile, DTS/BSP integration, vendor boot image layout and U-Boot package to `sunxi/cortexa53`, and selects Linux 6.18. Defconfig and feeds now pass; the most recent failure (run `44280942808`) was `pending-6.18/487-mtd-spinand-Add-support-for-Etron-EM73D044VCx.patch` failing to patch `drivers/mtd/nand/spi/Makefile`. Cause: the 25.12 tree only ships `backport-6.12`/`hack-6.12`, and the overlay copied only `pending-6.18`, so `436-v7.3-mtd-spinand-add-support-for-HeYangTek-HYF1GQ4UDACAE.patch` never ran and the `heyangtek.o` line expected by 487 was absent. The overlay now also copies `backport-6.18` (238 patches) and `hack-6.18` (69 patches), asserts all three patch directories are non-empty, and no longer overwrites the tracked 6.18 BSP shim with the 6.6 version. Replaying 434 -> 436 -> 487 against pristine v6.18.60 sources applies with zero fuzz.

No 25.12 or Linux 6.18 image is considered successful until the workflow's firmware verification step passes and a non-placeholder artifact is present.

## Integrated pieces

1. The active 24.10 source contains the A7Z profile, Allwinner BSP overlay, A7Z/SoC DTS files, vendor image helper, extlinux configuration and prebuilt U-Boot files.
2. The 6.18 kernel config selects known Sun60IW2 BSP Kconfig symbols. It no longer contains the earlier invalid OpenWrt package selector `CONFIG_KMOD_CEDAR_VPU`; Cedar VPU availability is still unverified.
3. `scripts/apply-openwrt-25.12-overlay.sh` prepares the pinned 25.12 source without modifying the upstream submodule commit, copies the AIoT fork's `backport-6.18`, `hack-6.18` and `pending-6.18` patch sets plus `config-6.18`/`kernel-6.18` metadata into it, and applies parent-repo patches for device image generation, the DTS registration, virtual dependency handling and the `nf-flow` module dependency.
4. The independent workflows build OpenWrt 24.10/Linux 6.6, OpenWrt 24.10/Linux 6.18 (A7A/A7Z), and OpenWrt 25.12/Linux 6.18 (A7Z), with build logs and artifacts uploaded for diagnosis. The 6.18 workflow temporarily replaces the 24.10 mac80211 package with pinned 25.12 package source to use matching backports 6.18.55.

## Remaining verification

1. Rerun the Linux 6.18 A7A/A7Z workflow now that the BSP shim is tracked (`openwrt-sunxi-aiot` `e2f599ea`) and carries the `addprefix` fix; confirm the DTS files compile and the firmware artifact check passes.
2. Rerun 25.12 with the `backport-6.18`/`hack-6.18` overlay copy; verify that 487 applies, that the kernel tree builds, and that the SD-card image passes the size plus `gzip -t` check.
3. Boot the resulting A7Z image on hardware and test storage, networking, USB, PCIe, GPIO and LED.
4. The DTS property `skip-uboot-pcie-training` has no known active U-Boot consumer in this repository; the prebuilt U-Boot's behavior remains unknown.
5. Do not treat the Cedar VPU config or driver as enabled/working without a matching Kconfig/package definition and runtime evidence.
