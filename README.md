# Multi-Architecture Docker Image Build Guide

本指南旨在提供一个清晰、可复现的流程，指导您如何使用 `docker buildx` 构建能够同时在 `ARM64`（例如 Apple M-series 芯片的 Mac）和 `x86_64/AMD64`（例如标准的 Windows/Linux PC）两种主流 CPU 架构上运行的 Docker 镜像。

## 1. 引言

随着苹果 M 系列芯片（ARM64）的普及，开发者经常面临一个挑战：在自己的 ARM64 架构电脑上构建的 Docker 镜像，无法在传统的 x86_64/AMD64 服务器或同事的电脑上运行，反之亦然。这导致了协作和部署的困难。

`docker buildx` 是 Docker CLI 的一个扩展，它引入了利用 Moby BuildKit 引擎的强大功能。通过 `buildx`，我们可以轻松地在单一命令下，构建出包含多个不同架构平台支持的“胖镜像”（Fat Image）。当用户在不同架构的机器上拉取这个镜像时，Docker 会自动选择与其平台匹配的正确版本来运行。

## 2. 先决条件

在开始之前，请确保您已准备好以下环境：

*   **Docker Desktop**：在您的 Windows、macOS 或 Linux 电脑上安装最新版本的 Docker Desktop。它已经内置了 `docker buildx`。
*   **镜像仓库账户**：您需要一个可以推送和存储镜像的仓库账户，例如 Docker Hub、阿里云 ACR、Harbor 等。本指南将以 Docker Hub 为例。

## 3. 一次性环境设置

为了启用 `buildx` 的多平台构建能力，我们需要创建一个使用 `docker-container` 驱动的特殊构建器（Builder）。这个设置在您的电脑上**只需执行一次**。

**第一步：清理可能存在的旧构建器（推荐）**

为了避免命名冲突，建议先执行此命令。如果构建器不存在，它会报错，可以安全地忽略。

```bash
docker buildx rm mybuilder
```

**第二步：创建并切换到新的构建器**

这是最核心的步骤。我们将创建一个名为 `mybuilder` 的新构建器，它使用 `docker-container` 驱动，并立即切换到它 (`--use`)。

```bash
docker buildx create --name mybuilder --driver docker-container --use
```

**第三步：准备（引导）新构建器**

创建完成后，需要引导（bootstrap）它来确保构建环境已准备就绪。

```bash
docker buildx inspect --bootstrap
```

**第四步：验证设置**

运行以下命令来查看您所有的构建器列表：

```bash
docker buildx ls
```

您应该能看到类似下面的输出。请务必确认：
1.  列表中存在 `mybuilder`。
2.  `mybuilder` 的 `DRIVER` 是 `docker-container`。
3.  `mybuilder` 的名字旁边有一个星号 (`*`)，表示它当前正处于激活状态。

```
NAME/NODE       DRIVER/ENDPOINT             STATUS   PLATFORMS
mybuilder *     docker-container
  mybuilder0    unix:///var/run/docker.sock running  linux/arm64, linux/amd64, linux/riscv64, linux/ppc64le, linux/s390x, linux/386, linux/arm/v7, linux/arm/v6
default         docker
  default       default                     running  linux/arm64, linux/amd64, linux/riscv64, linux/ppc64le, linux/s390x, linux/386, linux/arm/v7, linux/arm/v6
```

## 4. 通用构建与推送命令

完成一次性环境设置后，您就可以在任何时候使用下面这条通用命令来构建并推送您的多架构镜像了。

#### **macOS/Linux (bash/zsh)**

在 `bash` 或 `zsh` 等 shell 中，您可以使用 `date` 命令来创建一个格式化的时间戳变量。

```bash
# 1. 创建一个 YYYYMMDDHHMMSS 格式的时间戳变量
TIMESTAMP=$(date +%Y%m%d%H%M%S)

# 2. 在构建命令中使用该变量
# --progress=tty 显示详细的构建和推送进度（包含进度条）
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --progress=tty \
  -t wen911119/fe-dev-container:latest \
  -t wen911119/fe-dev-container:${TIMESTAMP} \
  --push .

# 3. 本地构建arm 版本用于测试（需要本机是arm芯片）
docker buildx build \
  --platform linux/arm64 \
  -t wen911119/fe-dev-container-debug:${TIMESTAMP} \
  --load .
```

#### **Windows (PowerShell)**

在 Windows 的 PowerShell 中，您可以使用 `Get-Date` 命令来达到同样的效果。

```powershell
# 1. 创建一个 yyyyMMddHHmmss 格式的时间戳变量
$TIMESTAMP = Get-Date -Format "yyyyMMddHHmmss"

# 2. 在构建命令中使用该变量
# --progress=tty 显示详细的构建和推送进度（包含进度条）
docker buildx build `
  --platform linux/amd64,linux/arm64 `
  --progress=tty `
  -t wen911119/fe-dev-container:latest `
  -t wen911119/fe-dev-container:$TIMESTAMP `
  --push .

# 3. 本地构建 amd64 版本用于测试（需要本机是x86_64芯片）
docker buildx build `
  --platform linux/amd64 `
  -t wen911119/fe-dev-container-debug:$TIMESTAMP `
  --load .
```

通过这种方式，您的每一次构建都会自动获得一个独一无二、带有时间印记的标签，极大地提升了您镜像版本的管理水平。

## 5. 平台特定说明

`docker buildx` 利用 QEMU 模拟器来实现在一种 CPU 架构上构建另一种架构的镜像。这意味着：

*   当您在 **ARM64** 架构的电脑（如 M3 Pro Mac）上执行构建时：
    *   `linux/arm64` 镜像是**原生构建**的，速度很快。
    *   `linux/amd64` 镜像是通过 **QEMU 模拟**构建的，速度会显著变慢。

*   当您在 **x86_64/AMD64** 架构的电脑（如 Windows/Linux PC）上执行构建时：
    *   `linux/amd64` 镜像是**原生构建**的，速度很快。
    *   `linux/arm64` 镜像是通过 **QEMU 模拟**构建的，速度会显著变慢。

无论在哪种平台上构建，最终产出的镜像是完全一致的。

## 6. 使用方法

多架构镜像的最大优势在于其使用的透明性。无论用户使用的是 ARM64 还是 x86_64 的机器，他们都使用完全相同的命令来拉取和运行镜像：

```bash
# 拉取镜像（Docker 会自动选择匹配当前平台的版本）
docker pull your-dockerhub-username/your-image-name:tag

# 运行镜像
docker run -it your-dockerhub-username/your-image-name:tag
```

## 7. 故障排查

**错误: `Multi-platform build is not supported for the docker driver`**

这是最常见的错误。它明确地告诉您，当前的 `buildx` 构建器（通常是 `default` 或 `desktop-linux`）使用的是不支持多平台构建的 `docker` 驱动。

**解决方案**：
这个问题的唯一解法就是严格遵循本文档 **“3. 一次性环境设置”** 一节的指导，创建一个使用 `docker-container` 驱动的新构建器，并确保已切换到该构建器。

