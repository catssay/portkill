# portkill
## 介绍 Intro

This is a bash script, aimed to kill processes with specific port open. The script depends on `netstat` `sed` `awk` `ps` and `sudo` commands.
Bash 脚本，用来杀死开放指定端口的进程。portkill.sh 使用 `netstat -antp` 查找开放的端口，用 sed 和 awk 进行处理，ps 显示相关进程的信息，使用需要root权限。

## 用法 Usage

`./portkill.sh PORT [PORT] ...`
使用时`sudo`会请求密码，可在脚本中设置密码，以后将不用输入。
