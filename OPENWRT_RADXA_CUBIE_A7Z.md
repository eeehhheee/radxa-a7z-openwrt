# Radxa Cubie A7Z 适配 OpenWrt 基本流程

本文针对工作区中的两个仓库：`openwrt-sunxi-aiot`（分支 `openwrt-24.10`）和 `allwinner-bsp`（分支 `cubie-aiot-v1.4.6`）。截至本文编写时，OpenWrt 仓库已包含 Cubie A7Z 的设备树、镜像设备定义和专用启动固件文件。因此建议先复现并验证现有支持，再按实际硬件问题迭代，不要先把另一版本 BSP 的内核或 U-Boot 源码直接覆盖进来。

## 1. 了解已有的板级支持

先检查以下位置：

- `openwrt-sunxi-aiot/target/linux/allwinner/image/aiot.mk`：A7Z 镜像设备定义，指定设备树、内核镜像类型、附加软件包和镜像流水线。
- `openwrt-sunxi-aiot/target/linux/allwinner/files/arch/arm64/boot/dts/allwinner/sun60i-a733-cubie-a7z.dts`：A7Z 板级设备树，描述供电、GPIO、存储、USB、PCIe、显示、散热等硬件。
- `openwrt-sunxi-aiot/target/linux/allwinner/patches-6.6/0002-add-more-devices.patch`：把 A7Z/A7A DTB 注册到内核构建。
- `openwrt-sunxi-aiot/package/boot/uboot-allwinner/Makefile`：定义 A7Z U-Boot/启动固件包。
- `openwrt-sunxi-aiot/package/boot/uboot-allwinner/files/radxa-cubie-a7z/`：包含 SD、SPI NOR、UFS 等启动固件及安装脚本，需按实际启动介质选择和核对。

检查当前版本与工作区状态：

```sh
cd /path/to/radxa_a7z_openwrt/openwrt-sunxi-aiot
git status --short
git branch --show-current
git log -1 --oneline

cd ../allwinner-bsp
git status --short
git branch --show-current
git log -1 --oneline
```

开始修改前先查看 `git status`，保留已有本地改动。核实这两个分支的内核、设备树、启动固件确实配套；BSP 不同版本的 DTS、私有驱动和固件格式不能默认互换。

## 2. 准备构建环境

在 OpenWrt 根目录按项目文档安装宿主机构建依赖。建议使用 Linux 构建机，准备足够的磁盘空间和内存；首次构建会下载源码并生成工具链、内核和镜像。

```sh
cd /path/to/radxa_a7z_openwrt/openwrt-sunxi-aiot
./scripts/feeds update -a
./scripts/feeds install -a
```

如果仓库带有针对 feeds 的本地补丁或锁定版本要求，应先检查项目说明并遵照其要求，不要无条件更新到不兼容的最新版。首次构建前保存配置，后续复现时可使用 `./scripts/diffconfig.sh` 记录配置差异。

## 3. 选择目标并编译

通过菜单配置选择 Allwinner AIoT 目标与 A7Z 设备：

```sh
make menuconfig
```

以仓库实际菜单项为准，选择 `Allwinner Aiot`/`aiot` 子目标，并确认 `Radxa Cubie-A7Z` 设备及所需软件包已选中。不要仅凭其他 Allwinner 板子的配置文件推断 A7Z 的配置。

先编译专用启动固件包，再编译完整固件：

```sh
make package/boot/uboot-allwinner/compile V=s
make -j"$(nproc)" V=s
```

如果目标包选择方式或构建目标在该 OpenWrt 分支中不同，以 `make menuconfig` 和该分支构建系统为准。发生错误时保留完整日志，先判断失败阶段：feeds/依赖、补丁应用、工具链、内核/DTS、启动包或镜像打包。

编译后检查 `bin/targets/` 下的产物：确认目标子目录正确，镜像名称对应 A7Z，检查镜像元数据和打包日志，并确认启动包确实选用了 `radxa-cubie-a7z` 文件。不要只因编译成功就认定镜像可启动。

## 4. 安全地首次启动

1. 确认板子的硬件版本、启动介质及对应安装脚本；检查 `package/boot/uboot-allwinner/files/radxa-cubie-a7z/` 中的 `setup.sh`/`setup.ps1`，阅读其写入目标和分区操作。
2. 备份现有系统、分区表和启动固件，并准备已验证的恢复介质与操作步骤。
3. 优先从可恢复的 SD 卡测试。写盘前用 `lsblk`、`blkid` 等核实设备节点；设备名必须由操作者现场确认，避免把镜像写到主机磁盘。
4. 使用串口控制台记录从 BootROM/SPL、U-Boot 到 Linux 的完整日志。确认 U-Boot 找到内核和正确 DTB，Linux 能识别存储并挂载根文件系统。
5. 只有在确认对应启动介质、恢复方案和刷写步骤后，才考虑更新板载 eMMC、SPI NOR 或 UFS 中的启动内容。

不同介质的 `boot0`、`boot_package.fex` 和分区布局并不相同；不可把 SD 卡流程直接套用到 SPI NOR/UFS/eMMC。

## 5. 验证硬件功能

先验证最小可用链路，再逐项验证板载功能：

- 启动稳定性：冷启动、重启、断电后恢复、根文件系统读写。
- 网络：有线网卡、Wi-Fi/蓝牙、SSH 与网络配置持久化。
- 连接与存储：USB host/device/Type-C、SD/eMMC/UFS、PCIe。
- 板级功能：GPIO/LED、按键、温度与风扇、显示/HDMI/DP、音频及电源管理。

常用诊断命令：

```sh
dmesg
ip link
ip address
lsblk
lsusb
cat /proc/cmdline
cat /proc/device-tree/model
```

根据日志判断问题属于 DTS 描述、内核驱动/配置、固件、根文件系统配置还是用户空间服务。修改后重新构建并验证对应功能，同时检查是否影响启动和其它设备。

## 6. 迭代移植时的修改顺序

如果现有镜像不能启动或硬件功能缺失，按以下顺序定位和修改：

1. **启动固件与介质**：确认 BootROM 启动路径、SPL/DDR 初始化、U-Boot 配置和镜像布局一致。
2. **设备树**：核对 `compatible`、供电 regulator、GPIO 极性、pinctrl、总线地址、中断、时钟、存储和板级外设连线。以 A7Z 原理图/硬件资料及配套 BSP 为依据，不能照搬 A7A 或相近 SoC 板卡的引脚配置。
3. **内核驱动与配置**：确认相关驱动在当前 `KERNEL_PATCHVER`（此仓库为 6.6）中存在且被启用；若依赖 BSP 私有驱动，按该仓库已有的补丁/文件集成，并记录补丁来源和版本。
4. **OpenWrt 目标与镜像**：确认 DTB 被内核构建、设备出现在 `aiot.mk`、必要驱动/固件包进入镜像，升级镜像元数据正确。
5. **启动后用户空间**：补齐网络、无线、存储挂载、LED/按键等默认配置；确保功能在重启后仍生效。

每次聚焦一个问题，保留串口日志、配置差异和复现步骤。不要将整份 BSP 源码无差别复制进 OpenWrt；只集成确有需要且与目标内核版本匹配的组件。

## 7. 发布前检查

- 从干净配置或记录的配置可重复构建，记下源码提交、分支、配置和构建命令。
- 对照镜像分区/容量限制，确认刷写说明不会误伤其他介质。
- 验证冷启动、重启、网络连接、存储读写和 sysupgrade；升级前后配置行为符合预期。
- 说明尚未验证的硬件功能、已知限制、恢复方法和串口参数。
- 发布镜像时提供校验和、对应设备/介质说明及明确的风险提示。

## 当前仓库基线

- OpenWrt：`openwrt-sunxi-aiot`，`openwrt-24.10` 分支。
- BSP：`allwinner-bsp`，`cubie-aiot-v1.4.6` 分支。
- OpenWrt 目标内核版本：6.6（见 `target/linux/allwinner/Makefile`）。
- A7Z 设备定义和 DTS 已存在；U-Boot 包使用预置启动固件文件。该事实只表示仓库有相应构建配置，不代表本文已验证成功编译、启动或每个外设均可用。
