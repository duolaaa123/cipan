#!/bin/bash

# 检查/disk目录是否存在
if [ ! -d "/disk" ]; then
    echo "/disk目录不存在，请检查！"
    exit 1
fi

# 1. 识别/disk下的所有文件夹，并按数字顺序排序
echo "正在扫描/disk下的所有文件夹..."
disk_dirs=$(ls -1 /disk | sort -n | awk '{print "/disk/"$1}')

if [ -z "$disk_dirs" ]; then
    echo "未找到/disk下的文件夹！"
    exit 1
fi

# 显示可选的硬盘目录（按数字排序）
echo -e "\n可用的文件夹列表(按数字排序):"
i=1
declare -A dir_map
for dir in $disk_dirs; do
    echo "$i) $dir"
    dir_map[$i]=$dir
    ((i++))
done

max_choice=$((i-1))

echo -e "\n请输入要操作的数字编号(1-$max_choice):"
read -p "选择: " choice

if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt $max_choice ]; then
    echo "无效选择！"
    exit 1
fi

selected_dir=${dir_map[$choice]}
echo "已选择: $selected_dir"

# 2. 检查cache-bcdn子目录
cache_dir="$selected_dir/cache-bcdn"
if [ -d "$cache_dir" ]; then
    count=$(find "$cache_dir" -maxdepth 1 -type d | grep -v "^$cache_dir$" | wc -l)
    echo "$cache_dir: 已有 $count 个文件夹"
else
    echo "$cache_dir: 目录不存在，将创建"
fi

# 3. 下载和解压操作
echo -e "\n请输入要在该目录中放置的101文件夹数量:"
read -p "数量: " folder_count

if ! [[ "$folder_count" =~ ^[0-9]+$ ]]; then
    echo "请输入有效的数字！"
    exit 1
fi

# 下载压缩包
temp_dir=$(mktemp -d)
echo -e "\n正在下载101.tar.gz..."
wget -q -O "$temp_dir/101.tar.gz" "https://gitproxy.click/https://github.com/duolaaa123/cipan/raw/main/101.tar.gz" || {
    echo "下载失败！请检查URL和网络连接。"
    rm -rf "$temp_dir"
    exit 1
}

# 解压
echo "正在解压..."
tar -xzf "$temp_dir/101.tar.gz" -C "$temp_dir" || {
    echo "解压失败！"
    rm -rf "$temp_dir"
    exit 1
}

if [ ! -d "$temp_dir/101" ]; then
    echo "压缩包中未找到101文件夹！"
    rm -rf "$temp_dir"
    exit 1
fi

# 4. 复制到选定的cache-bcdn目录
echo -e "\n开始复制到 $cache_dir..."
if [ ! -d "$cache_dir" ]; then
    echo "创建目录: $cache_dir"
    mkdir -p "$cache_dir"
fi

for ((i=1; i<=folder_count; i++)); do
    new_name="101"
    if [ -d "$cache_dir/$new_name" ]; then
        # 查找可用的编号
        num=102
        while [ -d "$cache_dir/$new_name" ]; do
            new_name="$num"
            ((num++))
        done
    fi
    
    echo "复制为 $new_name"
    cp -r "$temp_dir/101" "$cache_dir/$new_name"
done

# 清理
rm -rf "$temp_dir"
echo -e "\n操作完成！"
