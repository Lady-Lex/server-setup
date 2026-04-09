#!/bin/bash
# Ubuntu 虚拟机时间同步初始化脚本 (基于 Chrony)
# 适用前提: 已有软路由提供网络环境，直接使用系统默认 NTP 池

# 1. 确保以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "❌ 请使用 root 权限执行此脚本 (可以加 sudo)"
  exit 1
fi

echo "========== 开始配置时间与时区 =========="

# 2. 设置时区为上海
echo "[1/5] 正在设置时区为 Asia/Shanghai..."
timedatectl set-timezone Asia/Shanghai

# 3. 静默更新软件源并安装 Chrony
echo "[2/5] 检查并安装 chrony 服务..."
apt-get update -qq
apt-get install -y chrony > /dev/null 2>&1

# 4. 启用并启动服务 (注意 Ubuntu 下叫 chrony)
echo "[3/5] 正在启动 chrony 并配置开机自启..."
systemctl enable --now chrony > /dev/null 2>&1

# 5. 强制立即步进同步时间 (无视时间差)
echo "[4/5] 正在强制进行初始时间同步..."
chronyc makestep > /dev/null 2>&1

# 6. 将正确的时间写入虚拟机主板的硬件时钟
echo "[5/5] 将当前时间写入硬件时钟 (hwclock)..."
hwclock --systohc

echo "========== ✅ 配置完成 =========="

# 打印最终结果供直观检查
echo -e "\n⏱️ 当前系统时间:"
date
echo -e "\n📡 Chrony 同步状态:"
chronyc tracking | grep -E "Reference ID|Leap status"
