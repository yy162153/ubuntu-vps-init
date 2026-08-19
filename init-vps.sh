#!/usr/bin/env bash
set -Eeuo pipefail

echo "=== Ubuntu VPS 初始化：root 私钥登录 + BBR ==="

if [[ ${EUID} -ne 0 ]]; then
    echo "错误：请先执行 sudo -i，再运行本脚本。" >&2
    exit 1
fi

AUTHORIZED_KEYS="/home/ubuntu/.ssh/authorized_keys"
ROOT_SSH_DIR="/root/.ssh"
ROOT_AUTHORIZED_KEYS="${ROOT_SSH_DIR}/authorized_keys"
SSHD_DROPIN="/etc/ssh/sshd_config.d/99-root-login.conf"
BBR_CONFIG="/etc/sysctl.d/99-bbr.conf"

if [[ ! -s "${AUTHORIZED_KEYS}" ]]; then
    echo "错误：找不到或内容为空：${AUTHORIZED_KEYS}" >&2
    exit 1
fi

echo "=== 1. 配置 root SSH 私钥登录 ==="
install -d -m 700 -o root -g root "${ROOT_SSH_DIR}"
install -m 600 -o root -g root "${AUTHORIZED_KEYS}" "${ROOT_AUTHORIZED_KEYS}"

SSHD_BACKUP=""
if [[ -f "${SSHD_DROPIN}" ]]; then
    SSHD_BACKUP="${SSHD_DROPIN}.bak.$(date +%Y%m%d%H%M%S)"
    cp -a "${SSHD_DROPIN}" "${SSHD_BACKUP}"
fi

cat >"${SSHD_DROPIN}" <<'CONF'
PermitRootLogin prohibit-password
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
CONF

if ! sshd -t; then
    echo "错误：SSH 配置检查失败，正在恢复原配置。" >&2
    if [[ -n "${SSHD_BACKUP}" ]]; then
        cp -a "${SSHD_BACKUP}" "${SSHD_DROPIN}"
    else
        rm -f "${SSHD_DROPIN}"
    fi
    exit 1
fi

systemctl restart ssh

echo "=== 2. 启用 BBR ==="
modprobe tcp_bbr

cat >"${BBR_CONFIG}" <<'CONF'
net.ipv4.tcp_congestion_control=bbr
net.core.default_qdisc=fq
CONF

sysctl --system

echo
echo "=== 3. 验证结果 ==="
echo -n "拥塞控制算法："
sysctl -n net.ipv4.tcp_congestion_control
echo -n "默认队列算法："
sysctl -n net.core.default_qdisc
echo "BBR 模块："
lsmod | grep -w tcp_bbr || echo "未在 lsmod 输出中找到 tcp_bbr"

echo
echo "======================================"
echo "初始化完成。"
echo "请保持当前 SSH 窗口不要关闭。"
echo "另开一个窗口，用 root 和原 ubuntu 用户相同的私钥测试登录。"
echo "确认 root 可以登录后，再关闭当前窗口。"
echo "======================================"
