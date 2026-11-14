# 未接入 CI 的本地工作文件

本目录保留本地工作区里存在、但当前无法被 CI 使用（或不应注入子模块）的文件。

## kernel-6.18/config-6.18

这是 OpenWrt **构建配置**（`CONFIG_TARGET_*`、`CONFIG_PACKAGE_*`），不是内核配置片段。
`target/linux/<target>/config-<ver>` 需要的是内核 Kconfig 片段（如 `CONFIG_ARM64=y`）。

真正的 6.18 支持还缺：

- `include/kernel-6.18`（`LINUX_VERSION-6.18` + `LINUX_KERNEL_HASH`）
- `target/linux/generic/{pending,backport,hack}-6.18`

因此 `.github/workflows/build-openwrt-6.18.yml` 只保留 `workflow_dispatch`，并在预检处直接报错说明缺什么。

## pcie-uboot/

这两个补丁针对 U-Boot 源树（使用 `common.h`、`dm.h`、`udevice`，目标文件 `drivers/pcie/pcie-sunxi-plat.c`），
却被放在内核补丁目录 `patches-6.6/` 与 `patches-6.18/` 下。内核树没有该路径，注入内核补丁目录会导致编译失败，
所以不接入 CI；`uboot-allwinner` 包本身也只安装预编译固件（`files/<variant>/boot0_sdcard.bin`、`boot_package.fex`）。

若要启用：把补丁放进 U-Boot 源码的补丁目录，并确认所用 BSP 中确实存在 `drivers/pcie/pcie-sunxi-plat.c`。

## 已接入

- `ci/overlay-6.18/target/linux/allwinner/patches-6.18/`：0001 与 0003-cedrus 是有效的内核补丁，
  待 6.18 内核支持就绪后由 6.18 工作流复制进子模块。
- `ci/patches/dts-skip-uboot-pcie-training.patch`：DTS 的 2 行改动，两个工作流都会应用。
