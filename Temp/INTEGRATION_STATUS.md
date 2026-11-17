# Linux 6.18 → Radxa A7Z 集成状态报告

## 当前状态

这是 OpenWrt 24.10 `openwrt-sunxi-aiot` 上的实验性 Linux 6.18 集成，不是 OpenWrt 25.12 原生 A7Z target。仓库已保留内核版本目录、Allwinner 配置和 8 个 6.18 补丁，但尚无可复核的补丁应用、完整构建或硬件启动证据。

## 已准备

1. `include/kernel-6.18` 与 `target/linux/generic/config-6.18` 已存在。
2. `target/linux/generic/pending-6.18` 与 `target/linux/allwinner/config-6.18` 已存在。
3. `target/linux/allwinner/patches-6.18/` 保留 8 个补丁；其中部分补丁依赖 `files/bsp` overlay，需以 CI 的实际补丁应用结果为准。
4. `.github/workflows/build-openwrt-6.18.yml` 会对 A7Z/A7A 选择常用 LuCI、SSH、网络诊断、USB/存储、NVMe/PCI、USB Ethernet、Wi-Fi 和命令行工具，并上传构建日志和产物。
5. `build.sh` 支持 `KERNEL_PATCHVER=6.18 ./build.sh`，通过 make 命令行变量选择内核，不修改 tracked Makefile。

## 未完成验证

1. 6.18 补丁是否能在当前源码和 overlay 顺序下完整应用。
2. OpenWrt 24.10 + Linux 6.18 + A7Z/A7A 的完整 CI 构建。
3. A7Z 硬件启动、网络、USB、存储、PCIe、GPIO/LED 等功能。
4. `config-6.18` 中的 `CONFIG_KMOD_CEDAR_VPU` 尚未找到对应 Kconfig/package 定义，不能视为已启用的 VPU 驱动。
5. A7Z DTS 的 `skip-uboot-pcie-training` 在仓库内没有 U-Boot consumer，预置 U-Boot 是否支持该私有属性仍未知。
6. OpenWrt 25.12 的 `sunxi` target 是旧的 ARM 目标，没有 A733/A7Z DTS 或 AIoT subtarget；OpenWrt 25.12 原生 A7Z 移植尚未开始。

## 下一步

先推送变更并观察两个 GitHub Actions workflow 的实际运行结果；失败时保留 build.log，按补丁应用、内核配置、工具链和镜像打包阶段分别定位。
