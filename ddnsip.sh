

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[0;33m"
WHITE="\033[0;37m"
BLUE="\033[0;36m"
TE="\033[0m"
 



clear
echo -e "${GREEN}######################################
#            ${RED}DDNS一键脚本            ${GREEN}#
#${YELLOW} 特点：API Token即可，不需要API KEY ${GREEN}#
#             作者: ${WHITE}汐颜             ${GREEN}#
#         ${BLUE}https://xiyan.blog         ${GREEN}#
######################################${TE}"
echo



#!/bin/sh
# 简单的使用Clodflare API来实现DDNS的脚本
NEW_IPv4=$(curl -s http://ipv4.icanhazip.com)
NEW_IPv6=$(curl -s http://ipv6.icanhazip.com)
CURRENT_IPv4=$(cat $(dirname "$0")/current_ipv4.txt)
CURRENT_IPv6=$(cat $(dirname "$0")/current_ipv6.txt)
CURRENT_TIME=$(date +"%F %T")

# 填入DDNS域名
read -p "$(echo -e "请输入已经在cloudflare中准备好的${RED}完整域名：${TE}") " DDNS

# 保留一级域名
DDNS_TLD=$(echo "$DDNS" | sed 's/.*\.\([^.]*\.[^.]*\)$/\1/')

read -p "$(echo -e "请输入API Token(API令牌）：") " API_TOKEN
# API_TOKEN在Clouflare个人资料页面上创建
# RECORD_ID获取应执行以下代码：


ZONE_ID=$(
    curl -X GET "https://api.cloudflare.com/client/v4/zones?name=$DDNS_TLD" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" | jq '.result[] | .id'
)

RECORD_ID=$(
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$DDNS" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" | jq '.result[] | .id'
)



echo -e "\033[1;4;47;31m $(curl -X GET "https://api.cloudflare.com/client/v4/zones/f6d2d20e8b222f0d900062db7e8f7c58/dns_records?name=hinetlamhosting.xiliqing.top" \
-H "Authorization: Bearer QhDrh8pFgvUI9hav_5LnYTEreZAEXewjrPsStuBv" \
-H "Content-Type: application/json") \033[0m"
echo
    ZONE_ID="f6d2d20e8b222f0d900062db7e8f7c58"
    API_TOKEN="QhDrh8pFgvUI9hav_5LnYTEreZAEXewjrPsStuBv"
    curl -X GET "https://api.cloudflare.com/client/v4/zones/f6d2d20e8b222f0d900062db7e8f7c58/dns_records?name=hinetlamhosting.xiliqing.top" \
        -H "Authorization: Bearer QhDrh8pFgvUI9hav_5LnYTEreZAEXewjrPsStuBv" \
        -H "Content-Type: application/json" | jq '.result[] | .id'



if [ -n "$NEW_IPv4" ] ; then
  curl -k -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" \
    --data '{"type":"A","name":"'$DDNS'","content":"'$NEW_IPv4'","ttl":1,"proxied":false}' > /dev/null
  echo "$NEW_IPv4" > $(dirname "$0")/current_ipv4.txt
  echo "[$CURRENT_TIME] IPv4 address changed to $NEW_IPv4" >> $(dirname "$0")/crontab_log.txt
  echo -e "\033[1;4;47;31m IP已更新为：$NEW_IPv4 \033[0m"
elif [ -n "$NEW_IPv6" ] ; then
  curl -k -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" \
    --data '{"type":"AAAA","name":"'$DDNS'","content":"'$NEW_IPv6'","ttl":1,"proxied":false}' > /dev/null
  echo "$NEW_IPv6" > $(dirname "$0")/current_ipv6.txt
  echo "[$CURRENT_TIME] IPv6 address changed to $NEW_IPv6" >> $(dirname "$0")/crontab_log.txt
  echo -e "\033[1;4;47;31m IP已更新为：$NEW_IPv6 \033[0m"
else
  if [ -z "$NEW_IPv4" ] ; then
    echo "[$CURRENT_TIME] Failed to get IPv4 address" >> $(dirname "$0")/crontab_log.txt
    exit 1
  fi
  if [ -z "$NEW_IPv6" ]; then
    echo "[$CURRENT_TIME] Failed to get IPv6 address" >> $(dirname "$0")/crontab_log.txt
    exit 1
  fi
fi