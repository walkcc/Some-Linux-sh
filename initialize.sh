 #!/usr/bin/env bash

# 脚本制作: walkcc
kernel_version="4.14.129-bbrplus"

echo -e "执行 yum update"
yum update 

echo -e "安装 wget"
yum install wget

echo -e "下载内核..."
wget https://github.com/cx9208/bbrplus/raw/master/centos7/x86_64/kernel-4.14.129-bbrplus.rpm

echo -e "安装内核..."
yum install -y kernel-${kernel_version}.rpm

# 检查内核是否安装成功
list="$(awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg)"
target="CentOS Linux (${kernel_version})"
result=$(echo $list | grep "${target}")
if [[ "$result" = "" ]]; then
	echo -e "内核安装失败"
	exit 1
fi

echo -e "切换内核..."
grub2-set-default 'CentOS Linux (${kernel_version}) 7 (Core)'
echo -e "启用模块..."

fileName="/etc/sysctl.conf"

cat>"${filename}"<<EOF
# max open files
fs.file-max = 51200
# max read buffer
net.core.rmem_max = 67108864
# max write buffer
net.core.wmem_max = 67108864
# default read buffer
net.core.rmem_default = 65536
# default write buffer
net.core.wmem_default = 65536
# max processor input queue
net.core.netdev_max_backlog = 4096
# max backlog
net.core.somaxconn = 4096

# resist SYN flood attacks
net.ipv4.tcp_syncookies = 1
# reuse timewait sockets when safe
net.ipv4.tcp_tw_reuse = 1
# turn off fast timewait sockets recycling
net.ipv4.tcp_tw_recycle = 0
# short FIN timeout
net.ipv4.tcp_fin_timeout = 30
# short keepalive time
net.ipv4.tcp_keepalive_time = 1200
# outbound port range
net.ipv4.ip_local_port_range = 10000 65000
# max SYN backlog
net.ipv4.tcp_max_syn_backlog = 4096
# max timewait sockets held by system simultaneously
net.ipv4.tcp_max_tw_buckets = 5000
# turn on TCP Fast Open on both client and server side
net.ipv4.tcp_fastopen = 3
# TCP receive buffer
net.ipv4.tcp_rmem = 4096 87380 67108864
# TCP write buffer
net.ipv4.tcp_wmem = 4096 65536 67108864
# turn on path MTU discovery
net.ipv4.tcp_mtu_probing = 1

# for high-latency network
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbrplus

# for low-latency network, use cubic instead
# net.ipv4.tcp_congestion_control = cubic
EOF

# 优化系统文件描述符
ulimit -SHn 51200

echo "* soft nofile 51200" >> /etc/security/limits.conf
echo "* hard nofile 51200" >> /etc/security/limits.conf
echo "ulimit -SHn 51200" >> /etc/profile

rm -f kernel-${kernel_version}.rpm

read -p "bbrplus安装完成，现在重启 ? [Y/n] :" yn
[ -z "${yn}" ] && yn="y"
if [[ $yn == [Yy] ]]; then
	echo -e "重启中..."
	reboot
fi
