#!/bin/bash

# 如果不想每次运行脚本时都输入密码
# 可以在该位置设置密码
# 设置后sudo将不再请求密码
# 请注意该文件的权限, 否则他人将可以查看
# root用户或sudo组用户可以查看任意文件

password='';


# 用来判断是否提供了port参数
if [ "$1" = "" ]; then
	echo "Usage: $0  PORT [PORT] ..."
	exit 0;
fi


# ports_given数组用来存放port参数
# $@ 可获得运行脚本时所提供的所有参数
ports_given=($@);


# 用来判断是提供的参数是否有效
for port in ${ports_given[@]}; do
    if [[ "$port" =~ ^[0-9]{0,5}$ ]]; then
        if (( $port > 65535 || $port <= 0 )); then
            echo "Invalid port $port."
            exit 0;
        fi
    else
        echo "Invalid port $port.";
        exit 0;
    fi
done


# 程序的核心，用netstat -nap 列出本地端口
# 提取出 端口-PID 保存
if [ "$password" = '' ]; then
    ports_pids_pairs=($(sudo netstat -nap 2> /dev/null |\
	    sed -n '/^tcp/p' |\
	    awk -F " " '{print $4 "\t" $7}' |\
	    sed 's/^.*://; s@/.*$@@' |\
        sort -u));
else
    ports_pids_pairs=($(echo $password |sudo -S netstat -nap 2> /dev/null |\
	    sed -n '/^tcp/p' |\
	    awk -F " " '{print $4 "\t" $7}' |\
	    sed 's/^.*://; s@/.*$@@' |\
        sort -u));
fi

for ((i=0, j=0; i<${#ports_pids_pairs[@]}; i=i+2, j++)); do
	ports_on[$j]=${ports_pids_pairs[$i]};
done;

for ((i=1, j=0; i<=${#ports_pids_pairs[@]}; i=i+2, j++)); do
	pids_on[$j]=${ports_pids_pairs[$i]};
done;


# k, l用来做数组索引
# ports_to_kill 数组用来存放参数中的端口号中能被netstat查找到的
# pids_to_kill与ports_to_kill相对应

k=0;
l=0;
pids_to_kill=();
ports_to_kill=();
ports_not_found=();

for ((i=0; i<${#ports_given[@]}; i++)); do
	port_given=${ports_given[$i]};
	
	for ((j=0; j<${#ports_on[@]}; j++)); do
		port_on=${ports_on[$j]};
		
		if [ $port_given -eq $port_on ]; then
			pids_to_kill[$k]=${pids_on[$j]};
			ports_to_kill[$k]=${ports_on[$j]};
			k=$(( $k + 1 ));
			break;
		fi
	done

	if [ $j -eq ${#ports_on[@]} ]; then
		ports_not_found[$l]=${ports_given[$i]};
		l=$(( $l + 1 ));
	fi
done


# 如果没有找到相关进程则退出
if [ ${#pids_to_kill[@]} -eq 0 ]; then
    echo "No process found."
    exit 0;
fi


# 显示查找到的相关进程信息
echo "---------------------------------------";
if [ ${#ports_not_found[@]} -gt 0 ]; then
    echo "ports ${ports_not_found[@]} NOT FOUND!";
    echo "";
fi
echo "following process will be killed: ";
echo -e "PORT\t$(ps -o pid,user,time,args  2> /dev/null | sed -n '1p')";
for ((i=0; i<${#pids_to_kill[@]}; i++)); do
	echo -e "${ports_to_kill[$i]}\t $(ps -p ${pids_to_kill[$i]} -o pid,user,time,args | sed -n '2,$p')";
done
echo ""

# 请求用户用户确认是否杀死进程，如无需交互可自行修改
tries=0;
while ((tries<3)); do
	echo -n "Are you sure to kill these process? [yes or no] "
	read answer;
	case $answer in 'n' | 'N' | 'no' | 'No' | 'NO' | 'nO' )
		exit 0;
	esac
	case $answer in 'y' | 'yes' | 'Y' | 'YES' | 'Yes' )
		
        # 杀死进程
        for pid in ${pids_to_kill[@]}; do
			sudo kill -9 $pid;
		done;

		exit 0;
	esac
	tries=$(( $tries + 1 ));
done;
