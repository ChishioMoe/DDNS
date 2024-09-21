#!/bin/bash

#配置颜色变量
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[0;33m"
WHITE="\033[0;37m"
BLUE="\033[0;36m"
TE="\033[0m"
 

# 署名清空屏幕
Author_info(){
clear
echo -e "     ${GREEN}######################################
     #            ${RED}DDNS一键脚本            ${GREEN}#
     #${YELLOW} 特点：API Token即可，不需要API KEY ${GREEN}#
     #             作者: ${WHITE}汐颜             ${GREEN}#
     #         ${BLUE}https://xiyan.blog         ${GREEN}#
     ######################################${TE}"
echo
}
Author_info
# 检查是否为root用户
check_root(){
    if [[ $(whoami) != "root" ]]; then
        echo -e "请以root身份执行该脚本！"
        exit 1
    fi
}
check_root
# 检查是否已经安装 curl，如果没有安装，则安装 curl
check_curl() {
    if ! command -v curl &>/dev/null; then
        echo -e "未检测到 curl，正在安装 curl..."
        apt update
        apt install -y curl
        if [ $? -ne 0 ]; then
            echo -e "安装 curl 失败，请手动安装后重新运行脚本。"
            exit 1
        else
            echo -e "curl 安装成功！"
        fi
    else
        echo -e "脚本运行环境检测完毕！"
    fi
}
check_curl
# 开始安装DDNS
install_ddns(){
    # 如果主要脚本不存在，则强制下载主要脚本到指定目标上，并授予执行权限
    if [ ! -f "/root/DDNS/ddns" ]; then
        echo "开始下载脚本..."
        # curl -o /root/DDNS/ddns -d /root/DDNS/ https://ghp.ci/raw.githubusercontent.com/ChishioMoe/DDNS/refs/heads/main/ddns.sh && chmod +x /usr/bin/ddns
    fi
    
}
install_ddns
# 获取API_TOKEN和DDNS_DOMAIN，并保存在配置文件/root/ddnscfg.sh里
CONFIG_FILE="/etc/ddnscfg.sh"
set_ddnscfg() {
    # 获取用户输入的参数
    # 输入DDNS域名
    read -p "$(echo -e "请输入已经在cloudflare中准备好的${RED}完整域名：${TE}") " DDNS_DOMAIN
    # 输入API_TOKEN
    read -p "$(echo -e "请输入${RED}API Token(API令牌）：${TE}") " API_TOKEN
    # 创建配置文件
    touch /etc/ddnscfg.sh
    # 写入配置文件
    echo '#!/bin/bash' > "$CONFIG_FILE"
    echo "API_TOKEN=\"$API_TOKEN\"" >> "$CONFIG_FILE"
    echo "DDNS_DOMAIN=\"$DDNS_DOMAIN\"" >> "$CONFIG_FILE"

    echo "配置文件设置成功！"
}
if [ ! -f "$CONFIG_FILE" ]; then
    set_ddnscfg
else
    echo "配置文件已存在。是否要更新？(y/n)："
    read UPDATE_CONFIG
    if [ "$UPDATE_CONFIG" == "y" ]; then
        set_ddnscfg
    else
        echo "使用现有配置文件"
    fi
fi

# 检查 ddnsip.sh 脚本是否存在，创建ip更新脚本
CRON_DIR="/etc/cron.d"
DDNSIP_SCRIPT="$CRON_DIR/ddnsip.sh"
# 检查 /etc/cron.d 目录是否存在，如果不存在则创建它
if [ ! -d "$CRON_DIR" ]; then
    mkdir -p "$CRON_DIR"
fi
if [ ! -f "$DDNSIP_SCRIPT" ]; then
 # 创建 ddnsip.sh 文件并写入内容
  cat << 'EOF' > "$DDNSIP_SCRIPT"
#!/bin/bash
source /etc/ddnscfg.sh
echo "API_TOKEN: $API_TOKEN"
echo "DDNS_DOMAIN: $DDNS_DOMAIN"
# 加载配置文件
# 获取当前公网IP
NEW_IPv4=$(curl -s http://ipv4.icanhazip.com)
NEW_IPv6=$(curl -s http://ipv6.icanhazip.com)
# 保留一级域名
DDNS_TLD=$(echo "$DDNS_DOMAIN" | sed 's/.*\.\([^.]*\.[^.]*\)$/\1/')

ZONE_ID=$(
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DDNS_TLD" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" | jq -r '.result[] | .id'
)

RECORD_ID=$(
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$DDNS_DOMAIN" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" | jq -r '.result[] | .id'
)


if [ -n "$NEW_IPv4" ] ; then
  curl -k -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" \
    --data '{"type":"A","name":"'$DDNS_DOMAIN'","content":"'$NEW_IPv4'","ttl":1,"proxied":false}' > /dev/null
  echo -e "\033[1;4;47;31m IP已更新为：$NEW_IPv4 \033[0m"
elif [ -n "$NEW_IPv6" ] ; then
  curl -k -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" \
    --data '{"type":"AAAA","name":"'$DDNS_DOMAIN'","content":"'$NEW_IPv6'","ttl":1,"proxied":false}' > /dev/null
  echo -e "\033[1;4;47;31m IP已更新为：$NEW_IPv6 \033[0m"
else
  if [ -z "$NEW_IPv4" ] ; then
    echo " Failed to get IPv4 address" 
    exit 1
  fi
  if [ -z "$NEW_IPv6" ]; then
    echo " Failed to get IPv6 address" 
    exit 1
  fi
fi
EOF
# 赋予执行权限
chmod +x "$DDNSIP_SCRIPT"
fi
/bin/bash $DDNSIP_SCRIPT

existing_job=$(crontab -l | grep "$DDNSIP_SCRIPT")
if [ -z "$existing_job" ]; then
    read -p "$(echo -e "\033[1;4;47;31m 请输入IP刷新间隔（min）： \033[0m") " TIME
    # 创建定时任务
    (crontab -l ; echo "*/$TIME * * * * /bin/bash $DDNSIP_SCRIPT") | crontab -
    echo -e "\033[1;4;47;31m 定时任务已创建，脚本运行成功！ \033[0m"
else
    echo "当前定时任务为：$existing_job"
    read -p "$(echo -e "\033[1;4;47;31m 是否要修改更新间隔？(y/n)： \033[0m") " MODIFY_INTERVAL
    if [ "$MODIFY_INTERVAL" == "y" ]; then
        read -p "$(echo -e "\033[1;4;47;31m 请输入新的IP刷新间隔（min）： \033[0m") " TIME
        # 更新定时任务
        (crontab -l | grep -v "$DDNSIP_SCRIPT"; echo "*/$TIME * * * * /bin/bash $DDNSIP_SCRIPT") | crontab -
        echo -e "\033[1;4;47;31m 定时任务已更新，脚本运行成功！ \033[0m"
    else
        echo -e "\033[1;4;47;31m 使用现有定时任务，脚本运行成功！ \033[0m"
    fi
fi
# 创建定时任务
existing_job=$(crontab -l | grep "$DDNSIP_SCRIPT")
if [ -z "$existing_job" ]; then
    read -p "$(echo -e "\033[1;4;47;31m 请输入IP刷新间隔（min）： \033[0m") " TIME
    # 创建定时任务
    (crontab -l; echo "*/$TIME * * * * /bin/bash $DDNSIP_SCRIPT") | crontab -
    echo -e "\033[1;4;47;31m 定时任务已创建，脚本运行成功！ \033[0m"
else
    interval=$(echo "$existing_job" | sed -E 's|^\*/([0-9]+).*|\1|')
    interval="$interval 分钟"
    echo -e "\033[1;4;47;31m 当前IP刷新间隔为：$interval \033[0m"
    read -p "$(echo -e "\033[1;4;47;31m 是否要修改IP刷新间隔？(y/n)： \033[0m") " MODIFY_INTERVAL
    if [ "$MODIFY_INTERVAL" == "y" ]; then
        read -p "$(echo -e "\033[1;4;47;31m 请输入新的IP刷新间隔（min）： \033[0m") " TIME
        # 更新定时任务，先删除现有的，然后添加新的
        (crontab -l | grep -v "$DDNSIP_SCRIPT"; echo "*/$TIME * * * * /bin/bash $DDNSIP_SCRIPT") | crontab -
        existing_job=$(crontab -l | grep "$DDNSIP_SCRIPT")
        interval=$(echo "$existing_job" | sed -E 's|^\*/([0-9]+).*|\1|')
        interval="$interval 分钟"
        echo -e "\033[1;4;47;31m 定时任务已更新，脚本运行成功！当前IP刷新间隔为：$interval \033[0m"
    else
        echo -e "\033[1;4;47;31m 使用现有定时任务，脚本运行完毕！ \033[0m"
    fi
fi
