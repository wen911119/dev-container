#!/bin/bash

# 1. 进入脚本所在目录 (确保在 fe 目录下执行)
cd "$(dirname "$0")"

# --- 环境检查开始 ---
echo "🔍 正在检查构建环境..."

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
  echo "❌ 错误: 未找到 docker 命令。"
  echo "👉 请先安装 Docker Desktop。"
  echo "🔗 参考指引: https://github.com/wen911119/dev-container?tab=readme-ov-file#2-%E5%85%88%E5%86%B3%E6%9D%A1%E4%BB%B6"
  exit 1
fi

# 检查 buildx 是否可用
if ! docker buildx version &> /dev/null; then
  echo "❌ 错误: 您的 Docker 版本不支持 buildx。"
  echo "👉 请升级 Docker Desktop 到最新版本。"
  exit 1
fi

# 检查当前构建器驱动是否为 docker-container
# docker buildx inspect 默认检查当前使用的构建器
CURRENT_DRIVER=$(docker buildx inspect | grep "Driver:" | awk '{print $2}')

if [ "$CURRENT_DRIVER" != "docker-container" ]; then
  echo "❌ 错误: 当前构建器驱动为 '$CURRENT_DRIVER'，不支持多架构构建 (linux/amd64,linux/arm64)。"
  echo "⚠️  必须使用 'docker-container' 驱动。"
  echo ""
  echo "👉 请按照文档完成一次性环境设置："
  echo "   https://github.com/wen911119/dev-container?tab=readme-ov-file#3-%E4%B8%80%E6%AC%A1%E6%80%A7%E7%8E%AF%E5%A2%83%E8%AE%BE%E7%BD%AE"
  echo ""
  echo "   或者运行以下命令快速修复："
  echo "   docker buildx create --name mybuilder --driver docker-container --use"
  echo "   docker buildx inspect --bootstrap"
  exit 1
fi

echo "✅ 环境检查通过 (Driver: $CURRENT_DRIVER)"
# --- 环境检查结束 ---

# 2. 从 project.json 读取 project_name
# 使用 grep 和 cut 提取值，无需依赖 jq
PROJECT_NAME=$(grep '"project_name"' project.json | cut -d '"' -f 4)
REPO_URL=$(grep '"repo_url"' project.json | cut -d '"' -f 4)

if [ -z "$PROJECT_NAME" ]; then
  echo "❌ 错误: 无法从 project.json 中解析 project_name"
  exit 1
fi

# 检查 repo_url 是否为 HTTPS
if [[ ! "$REPO_URL" =~ ^https:// ]]; then
  echo "❌ 错误: repo_url 必须是 HTTPS 格式 (以 https:// 开头)。"
  echo "   当前值: $REPO_URL"
  echo "   原因: Docker 构建过程中无法处理 SSH 密钥认证，只能 Clone 公开仓库。"
  exit 1
fi

# 3. 定义镜像名称和时间戳
IMAGE_BASE="wen911119/${PROJECT_NAME}"
TIMESTAMP=$(date +%Y%m%d%H%M%S)

echo "🚀 开始构建镜像: ${IMAGE_BASE}"
echo "🏷️  Tags: latest, ${TIMESTAMP}"
echo "📂 上下文: $(pwd)"

# 4. 执行多架构构建并推送
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --progress=tty \
  -t "${IMAGE_BASE}:latest" \
  -t "${IMAGE_BASE}:${TIMESTAMP}" \
  --push .

if [ $? -eq 0 ]; then
  echo "✅ 构建并推送成功!"
else
  echo "❌ 构建失败"
  exit 1
fi
