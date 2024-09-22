# 介绍
## 无需API KEY
- **仅需根据脚本提示输入`API令牌`和`域名`，便可全程自动化运行！！**<br>
- 支持自定义IP刷新时间
# 一键脚本:

```
bash <(wget -qO- https://raw.githubusercontent.com/ChishioMoe/DDNS/refs/heads/main/ddns.sh)
```
# 国内加速：

```
bash <(wget -qO- https://ghp.ci/raw.githubusercontent.com/ChishioMoe/DDNS/refs/heads/main/ddns.sh)
```
## API令牌获取方法
- 进入网站[CloudFlare](https://dash.cloudflare.com)，点击右上角个人资料
- 进入左栏API令牌，点击右侧新建
- 选择创建DNS模板，在权限中添加区域-区域-读取（Zone-Zone-Read）即可
