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
REPO_BRANCH=$(grep '"repo_branch"' project.json | cut -d '"' -f 4)

if [ -z "$PROJECT_NAME" ]; then
  echo "❌ 错误: 无法从 project.json 中解析 project_name"
  exit 1
fi

# 检查 repo_url 是否为 HTTPS
if [[ "$REPO_URL" =~ ^https:// ]]; then
  echo "✅ repo_url 有效: $REPO_URL"
else
  echo "⚠️  repo_url 为空或非 HTTPS ($REPO_URL)。将构建【不含代码】的纯环境镜像。"
  # 清空变量以确保 Dockerfile 逻辑正确跳过
  REPO_URL=""
fi

# 3. 定义镜像名称和时间戳
IMAGE_BASE="wen911119/${PROJECT_NAME}"
TIMESTAMP=$(date +%Y%m%d%H%M%S)

echo "🚀 开始构建镜像: ${IMAGE_BASE}"
echo "🏷️  Tags: latest, ${TIMESTAMP}"
echo "📂 上下文: $(pwd)"

# 4. 执行多架构构建并推送
BUILD_CMD="docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --progress=tty \
  --build-arg REPO_URL=\"$REPO_URL\" \
  --build-arg REPO_BRANCH=\"$REPO_BRANCH\" \
  -t \"${IMAGE_BASE}:latest\" \
  -t \"${IMAGE_BASE}:${TIMESTAMP}\""

# 检查是否存在 .git_token 文件且内容有效
GIT_TOKEN_FILE=".git_token"
USE_SECRET=false

if [ -f "$GIT_TOKEN_FILE" ]; then
  # 读取文件内容并去除空白字符
  TOKEN_CONTENT=$(cat "$GIT_TOKEN_FILE" | tr -d '[:space:]')
  
  if [ -z "$TOKEN_CONTENT" ]; then
    : # 内容为空，静默忽略
  elif [ "$TOKEN_CONTENT" = "REPLACE_WITH_YOUR_GITHUB_TOKEN_HERE" ]; then
    : # 内容为占位符，静默忽略
  else
    echo "🔐 发现有效 .git_token 文件，将使用密钥构建..."
    USE_SECRET=true
  fi
fi

if [ "$USE_SECRET" = true ]; then
  BUILD_CMD="$BUILD_CMD --secret id=git_token,src=.git_token"
fi

# 追加 push 参数并执行
BUILD_CMD="$BUILD_CMD --push ."

# 执行构建
if eval $BUILD_CMD; then
  echo "✅ 构建并推送成功!"
else
  EXIT_CODE=$?
  echo "❌ 构建失败 (Exit Code: $EXIT_CODE)"
  exit $EXIT_CODE
fi
