#!/bin/bash
set -e

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script！"
    exit 1
fi

remove_packages() {
	while read line
	do
	echo "Removing ${line}"
	yum -y remove $line &> /dev/null
	if [ $? -eq 0 ];then
		echo "Removed ${line}"
	else
		echo "Fail to remove ${line}"
	fi
	done < include/software_to_remove.sh
	clear
	echo "Finish to remove software. Move on!"
}

install_docker_ce() {
	echo "Installing dependence:"
	yum -y install yum-utils device-mapper-persistent-date lvm2 &> /dev/null
	echo "Importing repo:"
	yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo &> /dev/null
	echo "Installing docker-ce:"
	yum -y install docker-ce &> /dev/null
	echo "Start && Enable docker-ce"
	systemctl start docker
	systemctl enable docker
	echo "Testing docker..."
	which "docker" > /dev/null
	if [ $? -eq 0 ];then
		docker run hello-world
	else
		echo "Command: docker not found!"
		install_docker_ce
	fi
}

start_firewalld() {
	systemctl start firewalld &> /dev/null
	if [ $? -eq 0 ];then
		systemctl enable firewalld &> /dev/null
		echo "firewalld 启动成功！"
	else
		echo "firewalld 的安装有问题。"
		exit 1
	fi
}

# Usage: add-port 22 tcp
# $1: port_number
# $2: protocol
add_port() {
	echo "正在添加端口 $2/$1"
	firewall-cmd --zone=public --add-port=$1/$2 --permanent &> /dev/null
	firewall-cmd --reload &> /dev/null
	if [ $? -eq 0 ];then
		echo "防火墙重启成功，端口$2/$1生效成功！"
	fi
}

install_fail2ban() {
	echo "正在添加epel-release库"
	yum -y install epel-release &> /dev/null
	if [ $? -eq 0 ];then
		echo "epel-release库添加成功！"
	fi
	echo "开始安装fail2ban"
	yum -y install fail2ban &> /dev/null
	if [ $? -eq 0 ];then
		echo "fail2ban安装成功！"
	fi
}

config_fial2ban() {
	echo "正在配置fail2ban"
	echo "#默认配置
[DEFAULT]
ignoreip = 127.0.0.1 127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
bantime  = 86400
findtime = 600
maxretry = 5
banaction = firewallcmd-ipset
action = %(action_mwl)s" > /etc/fail2ban/jail.local
	echo "Done"
}

add_sshd() {
	echo "正在添加sshd到fail2ban"
	echo "
[sshd]
enabled = true
filter = sshd
action = %(action_mwl)s
logpath = /var/log/secure" > /etc/fail2ban/jail.d/sshd.local
	echo "Done"
}

start_fail2ban() {
	echo "正在启动fail2ban"
	systemctl start fail2ban &> /dev/null
	if [ $? -eq 0 ];then
		echo "服务启动成功！当前运行状态如下："
	fi
	fail2ban-client status sshd
}

# Begin to install fail2ban
action=$1
[ -z $1 ] && action=install
case "${action}" in
    install)
		start_firewalld
		add_port "22" "tcp"
		install_fail2ban
		config_fial2ban
		add_sshd
		start_fail2ban
		;;
	docker)
		remove_packages
		install_docker_ce
		;;
	*)
		echo "Usage: $(basename $0) install | $(basename $0)"
		;;
esac

exit
