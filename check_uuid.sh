#!/bin/bash

# 指定UUID文件路径和index.html路径
UUID_FILE=/root/variflight/UUID
INDEX_HTML=/usr/local/share/tar1090/html/index.html

# 检查UUID文件是否存在
if [ ! -f $UUID_FILE ]; then
    # 如果不存在，则执行get_ip.py生成UUID并重启
    python3 /root/variflight/create_uuid.py
    reboot
fi

# 读取UUID文件内容
UUID=$(cat $UUID_FILE)

# 检查index.html是否包含UUID
if grep -q $UUID $INDEX_HTML; then
    # 如果包含，则脚本结束
    exit 0
fi

# 替换index.html中的UUID内容
if [[ -f /usr/local/share/tar1090/html/index.html ]] ; then
if grep -q '<a hidden>你的UUID是：</a>' $INDEX_HTML; then
    # 如果存在<a hidden>你的UUID是：</a>，则替换为<a>你的UUID是：/root/get_message/UUID</a>
    sed -i 's#<a hidden>你的UUID是：</a>#<a>你的UUID是：'$UUID'</a>#' $INDEX_HTML
else
    # 否则，替换<a>你的UUID是：任意内容</a>为<a>你的UUID是：/root/get_message/UUID</a>
    sed -i 's#<a>你的UUID是：.*</a>#<a>你的UUID是：'$UUID'</a>#' $INDEX_HTML
fi
else
exit 1
fi