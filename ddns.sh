#!/bin/bash

#配置颜色变量
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
WHITE="\033[37m"
BLUE="\033[36m"
TE="\033[0m"


# 获取终端宽度
TERM_WIDTH=$(tput cols)

# 居中输出函数
print_centered_line() {
    local line_text="$1"
    local text_length=${#line_text}
    local spaces=$(( (TERM_WIDTH - text_length) / 2 ))

    # 如果字符数量不均匀，右边多加一个空格
    if (( (TERM_WIDTH - text_length) % 2 != 0 )); then
        echo -e "$(printf '%*s' $((spaces+1)))${line_text}$(printf '%*s' $spaces)"
    else
        echo -e "$(printf '%*s' $spaces)${line_text}$(printf '%*s' $spaces)"
    fi
}

full_line() {
    WIDTH=$((TERM_WIDTH - 3))
    fill=$(printf '^%.0s' $(seq 1 $WIDTH))  # 根据终端宽度生成填充字符

    printf "${GREEN}%s${TE}\n" "$fill"
}

# 输出心形框
full_heart() {
    local content1="$1"
    local content2="$2"
    local content3="$3"
    local content4="$4"
    local width=$((TERM_WIDTH / 4 - 10))
    local height=10

    for ((i=0; i<height; i++)); do
        line=""
        case $i in
            0) line+="   ***     ***   "; line+="   ***     ***   "; line+="   ***     ***   "; line+="   ***     ***   " ;;
            1) line+=" *     * *     * "; line+=" *     * *     * "; line+=" *     * *     * "; line+=" *     * *     * " ;;
            2) line+="*       *       *"; line+="*       *       *"; line+="*       *       *"; line+="*       *       *" ;;
            3) line+="${content1}" ;;
            4) line+="${content2}" ;;
            5) line+="${content3}" ;;
            6) line+="${content4}" ;;
            7) line+="  *           *  "; line+="  *           *  "; line+="  *           *  "; line+="  *           *  " ;;
            8) line+="     *     *     "; line+="     *     *     "; line+="     *     *     "; line+="     *     *     " ;;
            9) line+="        *        "; line+="        *        "; line+="        *        "; line+="        *        " ;;
        esac
        print_centered_line "$line"
    done
}

# 署名清空屏幕
Author_info() {
    clear
    # 使用心形框包裹内容
    local content1="${RED}         DDNS 一键脚本  ${TE}"
    local content2="${YELLOW}     特点：API Token即可，不需要API KEY ${TE}"
    local content3="${WHITE}               作者: 汐颜        ${TE}"
    local content4="${BLUE}           网站：https://xiyan.blog ${TE}"
    full_heart "$content1" "$content2" "$content3" "$content4"
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
        # curl -s -o /root/DDNS/ddns -d /root/DDNS/ https://ghp.ci/raw.githubusercontent.com/ChishioMoe/DDNS/refs/heads/main/ddns.sh && chmod +x /usr/bin/ddns
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

     # 检查是否启用 Telegram 通知功能
    read -p "$(echo -e "是否启用 Telegram 通知功能？(y/n)：${TE}") " ENABLE_TELEGRAM
    if [[ "$ENABLE_TELEGRAM" == "y" ]]; then
        read -p "$(echo -e "是否更新Telegram Bot Token和Chat ID？(y/n)：${TE}") " UPDATE_TELEGRAM
        if [[ "$UPDATE_TELEGRAM" == "y" ]]; then
            read -p "$(echo -e "为了方便记忆，请输入你的${RED}服务器备注：${TE}") " SERVER_NAME
            read -p "$(echo -e "请输入你的${RED}Telegram Bot Token：${TE}") " bot_token
            read -p "$(echo -e "请输入你的${RED}Telegram Chat ID：${TE}") " chat_id

            # 写入配置文件
            echo "SERVER_NAME=\"$SERVER_NAME\"" >> "$CONFIG_FILE"
            echo "BOT_TOKEN=\"$bot_token\"" >> "$CONFIG_FILE"
            echo "CHAT_ID=\"$chat_id\"" >> "$CONFIG_FILE"

            echo "Telegram Bot Token 和 Chat ID 更新成功！"
        else
            echo "使用现有的 Telegram 配置。"
        fi
    else
        # 如果不启用 Telegram，则删除配置文件中的相关配置
        sed -i '/BOT_TOKEN/d' "$CONFIG_FILE"
        sed -i '/CHAT_ID/d' "$CONFIG_FILE"
        echo "Telegram 通知功能未启用，相关配置已删除。"
    fi

    echo "配置文件设置成功！"
}

if [ ! -f "$CONFIG_FILE" ]; then
    set_ddnscfg
else
    read -p "$(echo -e "\033[1;4;47;31m 配置文件已存在, 是否更新？(y/n)：${TE}") " UPDATE_CONFIG
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
echo -e "当前API_TOKEN为: \033[4;33m$API_TOKEN\033[0m"
echo -e "当前域名为: \033[4;33m$DDNS_DOMAIN\033[0m"
echo "脚本运行中..."
# 加载配置文件
send_telegram_message() {
    local message="$1"
    if [[ -z "$BOT_TOKEN" || -z "$CHAT_ID" ]]; then
        echo "未配置 Telegram Bot Token 或 Chat ID，无法发送消息。"
        return
    fi
    local url="https://api.telegram.org/bot$BOT_TOKEN/sendMessage"

    curl -s -X POST "$url" -d "chat_id=$CHAT_ID&text=$message" &> /dev/null
   
}
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
  curl -s -k -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" \
    --data '{"type":"A","name":"'$DDNS_DOMAIN'","content":"'$NEW_IPv4'","ttl":1,"proxied":false}' &> /dev/null
    
  echo -e "\033[33mIP已更新为：\033[0m\033[1;4;47;31m $NEW_IPv4 \033[0m"
  send_telegram_message "服务器：$SERVER_NAME，IP 已更新为：$NEW_IPv4"
elif [ -n "$NEW_IPv6" ] ; then
  curl -s -k -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" \
    --data '{"type":"AAAA","name":"'$DDNS_DOMAIN'","content":"'$NEW_IPv6'","ttl":1,"proxied":false}' &> /dev/null
  echo -e "\033[33mIP已更新为：\033[0m\033[1;4;47;31m $NEW_IPv6 \033[0m"
  send_telegram_message "服务器：$SERVER_NAME，IP 已更新为：$NEW_IPv4"
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
    echo -e "${YELLOW}当前IP刷新间隔为：${TE}\033[1;4;47;31m $interval ${TE}"
    read -p "$(echo -e "\033[1;4;47;31m 是否要修改IP刷新间隔？(y/n)： ${TE}") " MODIFY_INTERVAL
    if [ "$MODIFY_INTERVAL" == "y" ]; then
        read -p "$(echo -e "\033[1;4;47;31m 请输入新的IP刷新间隔（min）： ${TE}") " TIME
        # 更新定时任务，先删除现有的，然后添加新的
        (crontab -l | grep -v "$DDNSIP_SCRIPT"; echo "*/$TIME * * * * /bin/bash $DDNSIP_SCRIPT") | crontab -
        existing_job=$(crontab -l | grep "$DDNSIP_SCRIPT")
        interval=$(echo "$existing_job" | sed -E 's|^\*/([0-9]+).*|\1|')
        interval="$interval 分钟"
        echo -e "\033[1;4;47;31m 定时任务已更新，脚本运行成功！当前IP刷新间隔为：$interval ${TE}"
    else
        echo -e "\033[1;4;47;31m 使用现有定时任务，脚本运行完毕！ ${TE}"
    fi
fi
