# ServerStartup
线上服务器需要进行一些基本的安全设置（如通过fail2ban+firewalld来进行ssh的防爆破）以及一些基础软件的安装，通过这个脚本可以方便的进行一键安装。

## 使用方法
下载到本地后，首先赋予脚本执行权限：
```shell
chmod +x ./CentOS7_startup.sh
```
如果要安装fail2ban：
```shell
./CentOS7_startup.sh fail2ban
```
如果要安装docker-ce：
```shell
./CentOS7_startup.sh docker
# 有阿里云的docker加速码，可以作为第二个参数传递
# 加速码的申请地址
./CentOS7_startup.sh docker xxxxxxxx
```
如果需要同时安装fail2ban和docker-ce：
```
./CentOS7_startup.sh all
```

## 后续
目前这个脚本支持CentOS7，在腾讯云主机上的CentOS7.5测试通过。后续打算逐步添加一些软件的安装，并做一些整合。
