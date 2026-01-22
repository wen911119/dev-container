# Frontend Dev Container 配置说明

本文档详细说明了该 Dev Container 环境中预装的工具、配置及其版本信息。

## 🛠 核心环境

| 组件 | 版本/类型 | 说明 |
| :--- | :--- | :--- |
| **OS** | Debian Bullseye Slim | 轻量级基础镜像 |
| **Shell** | Zsh | 默认 Shell，已集成插件与美化 |
| **Node.js** | LTS (Latest) | 通过 NVM 安装，始终保持最新的长期支持版本 |
| **包管理器** | npm, yarn, pnpm | 通过 Node.js Corepack 启用 |

## 🚀 终端体验增强 (Shell & Terminal)

终端环境经过深度定制，提供现代化的开发体验：

### 1. 外观与提示符 (Prompt)
- **Starship**: 已安装并初始化。提供极速、高颜值、信息丰富的命令行提示符（显示 Git 状态、Node 版本等）。
- **颜色支持**:
  - 强制启用 `xterm-256color`。
  - 自定义 `LS_COLORS`，优化文件夹显示颜色（青色），解决默认深蓝色看不清的问题。

### 2. Zsh 插件
- **zsh-autosuggestions**: 根据历史记录提供灰色的命令自动建议（按 `→` 键补全）。
- **zsh-syntax-highlighting**: 命令行语法高亮（命令正确显示绿色，错误显示红色）。
- **自动补全**: 启用了 `compinit`，支持 Git 等命令的 Tab 补全。

### 3. 实用别名 (Aliases)

**文件操作:**
- `ls`: 自动开启颜色
- `ll`: 等同于 `ls -lh`
- `la`: 等同于 `ls -lha`
- `grep`: 自动开启颜色高亮

**Git 快捷指令:**
- `g`: `git`
- `gs`: `git status`
- `ga`: `git add`
- `gaa`: `git add --all`
- `gc`: `git commit`
- `gcm`: `git commit -m`
- `gp`: `git push`
- `gl`: `git pull`
- `gco`: `git checkout`

**导航与工具:**
- `..`: `cd ..`
- `...`: `cd ../..`
- **History**: 记录 10000 条历史，支持多终端共享历史，自动去重。

## 📦 已安装的系统包
- `curl`: 用于下载资源
- `git`: 版本控制
- `zsh`: Shell 环境
- `libatomic1`: 某些 Node.js 依赖项可能需要

## 💡 使用建议

1. **宿主机开启ssh-agent (必须)**:
   运行 ssh-add -l。
   如果显示 "The agent has no identities"，运行 ssh-add ~/.ssh/id_rsa (或者您的私钥路径) 添加它。（Mac）

2. **字体配置 (推荐)**:
   为了让 Starship 提示符显示正确的图标（如 Git 分支图标），建议在**宿主机**（您的 Mac/Windows）上安装 **Nerd Font** 字体（推荐 `MesloLGS NF` 或 `JetBrainsMono Nerd Font`），并在 VS Code 终端设置中配置该字体。

3. **Node 版本管理**:
   环境内置了 `nvm`。如果需要切换 Node 版本，可以直接使用：
   ```bash
   nvm install <version>
   nvm use <version>
   ```

   
