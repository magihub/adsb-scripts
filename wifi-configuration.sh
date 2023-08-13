#!/bin/bash

# 获取WiFi名称和密码
read -p "请输入WiFi名称： " ssid
read -p "请输入WiFi密码： " password

# 创建WiFi配置文件
cat <<EOF > /etc/wpa_supplicant/wpa_supplicant.conf
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="$ssid"
    psk="$password"
}
EOF

# 重新启动WiFi服务
wpa_cli -i wlan0 reconfigure

echo "WiFi连接已配置完成！"