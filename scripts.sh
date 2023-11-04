#!/bin/bash

echo "ADSB小工具"

while true; do
    echo "请选择一个选项："
    echo
    echo "666. 安装 readsb + tar1090 （中文版）+ 飞常准variflight 数据上传程序        "
    echo
    echo "基础与前端服务"
    echo "1. 安装 readsb + tar1090 （中文版）           2. 更新 readsb+tar1090 （中文版）        3. 卸载 readsb+tar1090 （中文版）"
    echo "4. 仅安装 readsb                             5. 仅更新 readsb                         6. 仅卸载 readsb"
    echo "7. 仅安装 tar1090 （中文版）                  8. 仅更新 tar1090 （中文版）              9. 仅卸载 tar1090 （中文版）"
    echo
    echo "数据上传服务"
    echo "10. 安装飞常准variflight 数据上传程序"
    echo "11. 修复飞常准variflight 数据上传程序(会重新生成UUID)"
    echo "12. 卸载飞常准variflight 数据上传程序"
    echo
    echo "其他工具"
    echo "13. 自定义 UUID    14. 重新生成 UUID    15.更新tar1090页面UUID    16. WiFi连接配置    17. 退出脚本"
    echo

    read choice

    case $choice in
    1)
        echo "安装 readsb + tar1090 （中文版）"
        bash -c "$(wget -nv -O - https://ghproxy.com/https://github.com/HLLF-FAN/ADSB-scripts/raw/main/readsb-tar1090-zh-install.sh)"
        exit
        ;;
    2)
        echo "正在更新 readsb + tar1090 （中文版）"
        if [[ -f /usr/local/share/tar1090/uninstall.sh ]] ; then
        bash /usr/local/share/tar1090/uninstall.sh
        else
        bash -c "$(wget -nv -O - https://ghproxy.com/https://github.com/HLLF-FAN/tar1090-zh/raw/master/uninstall.sh)"
        fi
        systemctl disable --now readsb
        bash -c "$(wget -nv -O - https://ghproxy.com/https://github.com/HLLF-FAN/ADSB-scripts/raw/main/readsb-tar1090-zh-install.sh)"
        if [[ -f /root/variflight/UUID ]] ; then
        sed -i -e "/你的UUID是/s/.*/<a>你的UUID是：$(cat \/root\/variflight\/UUID)<\/a>/" /usr/local/share/tar1090/html/index.html
        fi
        exit
        ;;
    3)
        echo "正在卸载 readsb + tar1090 "
        if [[ -f /usr/local/share/tar1090/uninstall.sh ]] ; then
        bash /usr/local/share/tar1090/uninstall.sh
        else
        bash -c "$(wget -nv -O - https://ghproxy.com/https://github.com/HLLF-FAN/tar1090-zh/raw/master/uninstall.sh)"
        fi
        systemctl disable --now readsb
        exit
        ;;
    4)
        echo "正在仅安装 readsb "
        systemctl disable --now readsb
        bash -c "$(wget -O - https://ghproxy.com/https://github.com/HLLF-FAN/ADSB-scripts/raw/main/readsb-install.sh)"
        exit
        ;;
    5)
        echo "正在仅更新 readsb "
        systemctl disable --now readsb
        bash -c "$(wget -O - https://ghproxy.com/https://github.com/HLLF-FAN/ADSB-scripts/raw/main/readsb-install.sh)"
        exit
        ;;
    6)
        echo "正在仅卸载 readsb "
        systemctl disable --now readsb
        exit
        ;;
    7)
        echo "正在仅安装 tar1090 （中文版）"
        bash -c "$(wget -nv -O - https://ghproxy.com/https://github.com/HLLF-FAN/tar1090-zh/raw/master/install.sh)"
        exit
        ;;
    8)
        echo "正在仅更新 tar1090 （中文版）"
        if [[ -f /usr/local/share/tar1090/uninstall.sh ]] ; then
        bash /usr/local/share/tar1090/uninstall.sh
        else
        bash -c "$(wget -nv -O - https://ghproxy.com/https://github.com/HLLF-FAN/tar1090-zh/raw/master/uninstall.sh)"
        fi
        bash -c "$(wget -nv -O - https://ghproxy.com/https://github.com/HLLF-FAN/tar1090-zh/raw/master/install.sh)"
        if [[ -f /root/variflight/UUID ]] ; then
        sed -i -e "/你的UUID是/s/.*/<a>你的UUID是：$(cat \/root\/variflight\/UUID)<\/a>/" /usr/local/share/tar1090/html/index.html
        fi
        exit
        ;;
    9)
        echo "正在仅卸载 tar1090 "
        if [[ -f /usr/local/share/tar1090/uninstall.sh ]] ; then
        bash /usr/local/share/tar1090/uninstall.sh
        else
        bash -c "$(wget -nv -O - https://ghproxy.com/https://github.com/HLLF-FAN/tar1090-zh/raw/master/uninstall.sh)"
        fi
        exit
        ;;
    10)
        echo "正在安装飞常准variflight 数据上传程序"
        if [[ -f /run/dump1090-fa/aircraft.json ]] ; then
        :
        elif [[ -f /run/readsb/aircraft.json ]]; then
        :
        elif [[ -f /run/adsbexchange-feed/aircraft.json ]]; then
        :
        elif [[ -f /run/dump1090/aircraft.json ]]; then
        :
        elif [[ -f /run/dump1090-mutability/aircraft.json ]]; then
        :
        elif [[ -f /run/skyaware978/aircraft.json ]]; then
        :
        else
        echo "-----------------------------------"
        echo "[错误]: 在您的设备上无法找到aircraft.json！"
        echo "您可能需要先安装解码器，推荐使用readsb"
        echo "readsb安装可执行第4项"
        echo "如果您刚完成解码器的安装，建议重启设备后再次尝试！"
        echo "安装时请确保SDR设备已经正确连接在设备上！"
        echo "-----------------------------------"
        exit 1
        fi
        bash -c "$(wget -O - https://ghproxy.com/https://github.com/HLLF-FAN/Varilightadsb-upload/raw/main/setup.sh)"
        exit
        ;;
    11)
        echo "正在修复飞常准variflight 数据上传程序(会重新生成UUID)"
        if [[ -f /run/dump1090-fa/aircraft.json ]] ; then
        :
        elif [[ -f /run/readsb/aircraft.json ]]; then
        :
        elif [[ -f /run/adsbexchange-feed/aircraft.json ]]; then
        :
        elif [[ -f /run/dump1090/aircraft.json ]]; then
        :
        elif [[ -f /run/dump1090-mutability/aircraft.json ]]; then
        :
        elif [[ -f /run/skyaware978/aircraft.json ]]; then
        :
        else
        echo "-----------------------------------"
        echo "[错误]: 在您的设备上无法找到aircraft.json！"
        echo "您可能需要先安装解码器，推荐使用readsb"
        echo "readsb安装可执行第4项"
        echo "如果您刚完成解码器的安装，建议重启设备后再次尝试！"
        echo "安装时请确保SDR设备已经正确连接在设备上！"
        echo "-----------------------------------"
        exit 1
        fi
    
        bash -c "$(wget -O - https://ghproxy.com/https://github.com/HLLF-FAN/Varilightadsb-upload/raw/main/setup.sh)"
        exit
        ;;
    12)
        echo "正在卸载飞常准variflight 数据上传程序"
        rm -r /root/get_message
        rm -r /etc/profile.d/uuid.sh
        crontab -l | grep -v "/root/get_message/send_message.sh >/dev/null 2>&1" | crontab -
        if grep -q "UUID" /usr/local/share/tar1090/html/index.html; then
        sed -i -e '/你的UUID是/s/.*/<a hidden>你的UUID是：<\/a>/' /usr/local/share/tar1090/html/index.html
        fi
        exit
        ;;
    13)
       while true; do
            echo "自定义 UUID"
            echo "请输入想要自定义的 16 位 UUID:"
            read input
            if [ ${#input} -eq 16 ]; then
                echo "请确认 $input 为你所自定义的 UUID"
                echo "1. 确认"
                echo "2. 重新输入"
                read -p "是否确认？ [1/2]: " confirm

                if [ "$confirm" == "1" ]; then
                    echo "$input" > /root/get_message/UUID
                    echo "已自定义 UUID 为：$(cat /root/get_message/UUID)"
                    if grep -q "UUID" /usr/local/share/tar1090/html/index.html; then
                    sed -i -e "/你的UUID是/s/.*/<a>你的UUID是：$(cat \/root\/get_message\/UUID)<\/a>/" /usr/local/share/tar1090/html/index.html
                    fi
                    exit
                elif [ "$confirm" == "2" ]; then
                    echo "重新输入 UUID..."
                else
                    echo "无效的选择，请重新输入。"
                fi
            else
                echo "输入的 UUID 长度不正确，请输入 16 位长度的 UUID。"
            fi
        done
        ;;
    14)
        echo "正在重新生成 UUID"
        rm -r /root/get_message/UUID
        python3 /root/get_message/create_uuid.py
        echo "重新生成 UUID 完成"
        echo "UUID为:"$(cat /root/get_message/UUID)
        if grep -q "UUID" /usr/local/share/tar1090/html/index.html; then
        sed -i -e "/你的UUID是/s/.*/<a>你的UUID是：$(cat \/root\/get_message\/UUID)<\/a>/" /usr/local/share/tar1090/html/index.html
        fi
        exit
        ;;
    15)
        echo "正在更新tar1090页面UUID"
        if [[ -f /root/get_message/UUID ]] ; then
        sed -i -e "/你的UUID是/s/.*/<a>你的UUID是：$(cat \/root\/get_message\/UUID)<\/a>/" /usr/local/share/tar1090/html/index.html
        echo "tar1090页面UUID更新完成"
        else 
        echo "UUID文件不存在，请重新生成！（可执行第14项）"
        fi
        exit
        ;;
    16)
        echo "进入WiFi连接配置"
        sleep 2
        bash -c "$(wget -O - https://ghproxy.com/https://github.com/HLLF-FAN/ADSB-scripts/raw/main/wifi-configuration.sh)"
        exit
        ;;
    666)
        echo "安装 readsb + tar1090 （中文版）+ 飞常准variflight 数据上传程序"
        bash -c "$(wget -O - https://ghproxy.com/https://github.com/HLLF-FAN/ADSB-scripts/raw/main/readsb-tar1090-zh-install.sh)"
        sleep 2
        echo "正在安装飞常准variflight 数据上传程序"
        if [[ -f /run/dump1090-fa/aircraft.json ]] ; then
        :
        elif [[ -f /run/readsb/aircraft.json ]]; then
        :
        elif [[ -f /run/adsbexchange-feed/aircraft.json ]]; then
        :
        elif [[ -f /run/dump1090/aircraft.json ]]; then
        :
        elif [[ -f /run/dump1090-mutability/aircraft.json ]]; then
        :
        elif [[ -f /run/skyaware978/aircraft.json ]]; then
        :
        else
        echo "-----------------------------------"
        echo "[错误]: 在您的设备上无法找到aircraft.json！"
        echo "您可能需要先安装解码器，推荐使用readsb"
        echo "readsb安装可执行第4项"
        echo "如果您刚完成解码器的安装，建议重启设备后再次尝试！"
        echo "安装时请确保SDR设备已经正确连接在设备上！"
        echo "-----------------------------------"
        exit 1
        fi
        bash -c "$(wget -O - https://ghproxy.com/https://github.com/HLLF-FAN/Varilightadsb-upload/raw/main/setup.sh)"
        exit
        ;; 
    17)
        echo "正在退出"
        exit
        ;;
    *)
        echo "无效的选择"
        ;;
    esac
done
