# portkill
## This is a linux bash script to kill processes with specifical ports
## Bash 脚本，用来杀死开放指定端口的进程
portkill.sh 使用 `netstat -antp` 查找开放的端口，用 sed 和 awk 进行处理，ps 显示相关进程的信息。

## 用法
`./portkill.sh PORT [PORT] ...`
