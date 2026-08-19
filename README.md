# Ubuntu VPS 初始化脚本

用于 Oracle Cloud 等 Ubuntu 新机的首次初始化：

- 将 `ubuntu` 用户的 SSH 公钥复制给 `root`，启用 root 私钥登录并禁用 SSH 密码登录
- 启用 BBR，设置 `tcp_congestion_control=bbr` 和 `default_qdisc=fq`

## 第一步：初始化服务器

首次使用 `ubuntu` 用户和云服务商提供的私钥登录服务器，然后切换到 root：

```bash
sudo -i
```

执行初始化脚本：

```bash
bash <(curl -fsSL https://github.com/yy162153/ubuntu-vps-init/raw/main/init-vps.sh)
```

脚本完成后不要立即关闭当前 SSH 窗口。请另开一个窗口，使用 `root` 用户和原来登录 `ubuntu` 的同一把私钥测试连接；确认成功后再关闭旧窗口。

## 第二步：安装甬哥 Sing-box

项目地址：[yonggekkk/sing-box-yg](https://github.com/yonggekkk/sing-box-yg)

使用 root 用户执行：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sb.sh)
```

## 初始化脚本执行的操作

1. 将 `/home/ubuntu/.ssh/authorized_keys` 复制到 `/root/.ssh/authorized_keys`
2. 写入 `/etc/ssh/sshd_config.d/99-root-login.conf`：

   ```text
   PermitRootLogin prohibit-password
   PubkeyAuthentication yes
   PasswordAuthentication no
   KbdInteractiveAuthentication no
   ```

3. 运行 `sshd -t` 检查配置，通过后重启 SSH
4. 加载 `tcp_bbr` 模块
5. 写入 `/etc/sysctl.d/99-bbr.conf`：

   ```text
   net.ipv4.tcp_congestion_control=bbr
   net.core.default_qdisc=fq
   ```

6. 执行 `sysctl --system` 并输出 BBR 验证结果
