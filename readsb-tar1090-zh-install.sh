#!/bin/bash

if [ "$(id -u)" != "0" ]; then
    echo -e "\033[33m"
    echo "This script must be ran using sudo or as root."
    echo -e "\033[37m"
    exit 1
fi

set -e
trap 'echo "[错误] 第 $LINENO 行命令在执行 $BASH_COMMAND 时出现错误"' ERR
renice 10 $$

if [ -f /boot/piaware-config.txt ]; then
    echo --------
    echo "如果您正在使用piaware镜像像，则此设置脚本会打乱配置。"
    echo --------
    echo "正在退出"
    exit 1
fi

repository="https://ghproxy.com/https://github.com/HLLF-FAN/readsb.git"

# blacklist kernel driver as on ancient systems
if grep -E 'wheezy|jessie' /etc/os-release -qs; then
    echo -e 'blacklist rtl2832\nblacklist dvb_usb_rtl28xxu\n' > /etc/modprobe.d/blacklist-rtl-sdr.conf
    rmmod rtl2832 &>/dev/null || true
    rmmod dvb_usb_rtl28xxu &>/dev/null || true
fi

ipath=/usr/local/share/adsb/readsb-install
mkdir -p $ipath

if grep -E 'wheezy|jessie' /etc/os-release -qs; then
    # make sure the rtl-sdr rules are present on ancient systems
    wget -O /tmp/rtl-sdr.rules https://ghproxy.com/https://github.com/HLLF-FAN/ADSB-scripts/blob/main/osmocom-rtl-sdr.rules
    cp /tmp/rtl-sdr.rules /etc/udev/rules.d/
fi

function aptInstall() {
    if ! apt install -y --no-install-recommends --no-install-suggests "$@" &>/dev/null; then
        apt update
        if ! apt install -y --no-install-recommends --no-install-suggests "$@"; then
            apt clean -y || true
            apt --fix-broken install -y || true
            apt install --no-install-recommends --no-install-suggests -y $packages
        fi
    fi
}

if command -v apt &>/dev/null; then
    packages=(git gcc make libusb-1.0-0-dev librtlsdr-dev librtlsdr0 ncurses-dev ncurses-bin zlib1g-dev zlib1g)
    if ! grep -E 'wheezy|jessie' /etc/os-release -qs; then
        packages+=(libzstd-dev libzstd1)
    fi
    if ! command -v nginx &>/dev/null; then
        packages+=(lighttpd)
    fi
    aptInstall "${packages[@]}"
fi

udevadm control --reload-rules || true

function getGIT() {
    # getGIT $REPO $BRANCH $TARGET-DIR
    if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]]; then
        echo "getGIT wrong usage, check your script or tell the author!" 1>&2
        return 1
    fi
    if ! cd "$3" &>/dev/null || ! git fetch --depth 2 origin "$2" || ! git reset --hard FETCH_HEAD; then
        if ! rm -rf "$3" || ! git clone --depth 2 --single-branch --branch "$2" "$1" "$3"; then
            return 1
        fi
    fi
    return 0
}
BRANCH="stale"
if grep -E 'wheezy|jessie' /etc/os-release -qs; then
    BRANCH="jessie"
fi
if ! getGIT "$repository" "$BRANCH" "$ipath/git"
then
    echo "无法克隆此仓库！"
    exit 1
fi

rm -rf "$ipath"/readsb*.deb
cd "$ipath/git"

make clean
THREADS=$(( $(grep -c ^processor /proc/cpuinfo) - 1 ))
THREADS=$(( THREADS > 0 ? THREADS : 1 ))
CFLAGS="-O2 -march=native"

# disable unaligned access for arm 32bit ...
if uname -m | grep -qs -e arm -e aarch64 && gcc -mno-unaligned-access hello.c -o /dev/null &>/dev/null; then
    CFLAGS+=" -mno-unaligned-access"
fi

if [[ $1 == "sanitize" ]]; then
    CFLAGS+="-fsanitize=address -static-libasan"
    if ! make "-j${THREADS}" AIRCRAFT_HASH_BITS=16 RTLSDR=yes OPTIMIZE="$CFLAGS"; then
        if grep -qs /etc/os-release 'bullseye'; then apt install -y libasan6;
        elif grep -qs /etc/os-release 'buster'; then apt install -y libasan5;
        fi
        make "-j${THREADS}" AIRCRAFT_HASH_BITS=16 RTLSDR=yes OPTIMIZE="$CFLAGS"
    fi
else
    make "-j${THREADS}" AIRCRAFT_HASH_BITS=16 RTLSDR=yes OPTIMIZE="$CFLAGS" "$@"
fi

cp -f debian/readsb.service /lib/systemd/system/readsb.service

rm -f /usr/bin/readsb /usr/bin/viewadsb
cp -f readsb /usr/bin/readsb
cp -f viewadsb /usr/bin/viewadsb

cp -n debian/readsb.default /etc/default/readsb

if ! id -u readsb &>/dev/null
then
    adduser --system --home $ipath --no-create-home --quiet readsb || adduser --system --home-dir $ipath --no-create-home readsb
    adduser readsb plugdev || true # USB access
    adduser readsb dialout || true # serial access
fi

apt remove -y dump1090-fa &>/dev/null || true
systemctl disable --now dump1090-mutability &>/dev/null || true
systemctl disable --now dump1090 &>/dev/null || true

rm -f /etc/lighttpd/conf-enabled/89-dump1090.conf

# configure rbfeeder to use readsb

if [[ -f /etc/rbfeeder.ini ]]; then
    systemctl stop rb-feeder &>/dev/null || true
    cp -n /etc/rbfeeder.ini /usr/local/share/adsb || true
    sed -i -e '/network_mode/d' -e '/\[network\]/d' -e '/mode=/d' -e '/external_port/d' -e '/external_host/d' /etc/rbfeeder.ini
    sed -i -e 's/\[client\]/\0\nnetwork_mode=true/' /etc/rbfeeder.ini
    cat >>/etc/rbfeeder.ini <<"EOF"
[network]
mode=beast
external_port=30005
external_host=127.0.0.1
EOF
    pkill -9 rbfeeder || true
    systemctl restart rbfeeder &>/dev/null || true
fi

# configure fr24feed to use readsb

if [ -f /etc/fr24feed.ini ]
then
    systemctl stop fr24feed &>/dev/null || true
    chmod a+rw /etc/fr24feed.ini || true
    apt-get install -y dos2unix &>/dev/null && dos2unix /etc/fr24feed.ini &>/dev/null || true
    cp -n /etc/fr24feed.ini /usr/local/share/adsb || true

    if ! grep -e 'host=' /etc/fr24feed.ini &>/dev/null; then echo 'host=' >> /etc/fr24feed.ini; fi
    if ! grep -e 'receiver=' /etc/fr24feed.ini &>/dev/null; then echo 'receiver=' >> /etc/fr24feed.ini; fi

    sed -i -e 's/receiver=.*/receiver="beast-tcp"/' -e 's/host=.*/host="127.0.0.1:30005"/' \
        -e 's/mlat=.*/mlat="no"/' -e 's/bs=.*/bs="no"/' -e 's/raw=.*/raw="no"/' /etc/fr24feed.ini

    systemctl restart fr24feed &>/dev/null || true
fi

systemctl enable readsb
systemctl restart readsb || true

# script to change gain

mkdir -p /usr/local/bin
cat >/usr/local/bin/readsb-gain <<"EOF"
#!/bin/bash
validre='^(-10|[0-9]+([.][0-9]+)?)$'
gain=$(echo $1 | tr -cd '[:digit:].-')
if ! [[ $gain =~ $validre ]] ; then echo "Error, invalid gain!"; exit 1; fi
if ! grep gain /etc/default/readsb &>/dev/null; then sudo sed -i -e 's/RECEIVER_OPTIONS="/RECEIVER_OPTIONS="--gain 49.6 /' /etc/default/readsb; fi
sudo sed -i -E -e "s/--gain .?[0-9]*.?[0-9]* /--gain $gain /" /etc/default/readsb
sudo systemctl restart readsb
EOF
chmod a+x /usr/local/bin/readsb-gain


# set-location
cat >/usr/local/bin/readsb-set-location <<"EOF"
#!/bin/bash

lat=$(echo $1 | tr -cd '[:digit:].-')
lon=$(echo $2 | tr -cd '[:digit:].-')

if ! awk "BEGIN{ exit ($lat > 90) }" || ! awk "BEGIN{ exit ($lat < -90) }"; then
    echo
    echo "无效的纬度: $lat"
    echo "纬度必须在 -90 和 90 之间"
    echo
    echo "纬度的示例格式: 51.528308"
    echo
    echo "用法:"
    echo "readsb-set-location 51.52830 -0.38178"
    echo
    exit 1
fi
if ! awk "BEGIN{ exit ($lon > 180) }" || ! awk "BEGIN{ exit ($lon < -180) }"; then
    echo
    echo "无效的经度: $lon"
    echo "经度必须在 -180 和 180 之间"
    echo
    echo "经度的示例格式: -0.38178"
    echo
    echo "用法:"
    echo "readsb-set-location 51.52830 -0.38178"
    echo
    exit 1
fi

echo
echo "已设置纬度: $lat"
echo "已设置经度: $lon"
echo
if ! grep -e '--lon' /etc/default/readsb &>/dev/null; then sed -i -e 's/DECODER_OPTIONS="/DECODER_OPTIONS="--lon -0.38178 /' /etc/default/readsb; fi
if ! grep -e '--lat' /etc/default/readsb &>/dev/null; then sed -i -e 's/DECODER_OPTIONS="/DECODER_OPTIONS="--lat 51.52830 /' /etc/default/readsb; fi
sed -i -E -e "s/--lat .?[0-9]*.?[0-9]* /--lat $lat /" /etc/default/readsb
sed -i -E -e "s/--lon .?[0-9]*.?[0-9]* /--lon $lon /" /etc/default/readsb
systemctl restart readsb
EOF
chmod a+x /usr/local/bin/readsb-set-location

# 提示用户输入经纬度
read -p "请输入纬度: " lat
read -p "请输入经度: " lon

# 验证纬度和经度的有效性
if ! awk "BEGIN{ exit ($lat > 90) }" || ! awk "BEGIN{ exit ($lat < -90) }"; then
    echo "无效的纬度: $lat"
    exit 1
fi
if ! awk "BEGIN{ exit ($lon > 180) }" || ! awk "BEGIN{ exit ($lon < -180) }"; then
    echo "无效的经度: $lon"
    exit 1
fi

# 保存经纬度到文件
echo "$lat $lon" > /usr/local/bin/readsb-set-location

echo "经纬度已保存"

echo --------------
cd "$ipath"

wget -O tar1090-install.sh https://ghproxy.com/https://github.com/HLLF-FAN/tar1090-zh/raw/master/install.sh
bash tar1090-install.sh /run/readsb

rm -rf /etc/motd
wget -P /etc https://ghproxy.com/https://github.com/HLLF-FAN/ADSB-scripts/blob/main/motd

echo
echo "             readsb+tar1090 已经安装完成！但是目前 readsb 服务未运行！"
echo "                       因此需要重启设备以启动 readsb 服务"
echo "                 tar1090的Web页面为 http://$(ip route get 1.2.3.4 | grep -m1 -o -P 'src \K[0-9,.]*')/tar1090"
echo "                     Web界面将显示错误，直至 readsb 正常运行"
echo
echo 
echo "                               ！！！注意！！！ "        
echo "                             请不要尝试将数据传给"
echo "          Flightradar24、Flightaware、ADS-B exchange等境外飞机跟踪网站"
echo "                 这种行为严重违反《中华人民共和国无线电管理条例》"
echo
