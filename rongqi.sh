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

# 2. 先统计各目录cache-bcdn下的文件夹数量
echo -e "\n正在统计各目录cache-bcdn下的文件夹数量..."
declare -A dir_counts
declare -A dir_map

i=1
for dir in $disk_dirs; do
    cache_dir="$dir/cache-bcdn"
    if [ -d "$cache_dir" ]; then
        count=$(find "$cache_dir" -maxdepth 1 -type d | grep -v "^$cache_dir$" | wc -l)
    else
        count="目录不存在"
    fi
    dir_counts[$i]="$count"
    dir_map[$i]="$dir"
    ((i++))
done

# 3. 显示可选的硬盘目录及文件夹数量统计
echo -e "\n可用的文件夹列表(按数字排序): [显示cache-bcdn目录中的文件夹数量]"
for ((j=1; j<i; j++)); do
    echo "$j) ${dir_map[$j]} - cache-bcdn文件夹数量: ${dir_counts[$j]}"
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

# 4. 下载和解压操作
echo -e "\n请输入要在该目录中放置的101文件夹数量:"
read -p "数量: " folder_count

if ! [[ "$folder_count" =~ ^[0-9]+$ ]]; then
    echo "请输入有效的数字！"
    exit 1
fi

# 下载压缩包
temp_dir=$(mktemp -d)
echo -e "\n正在下载101.tar.gz..."
if ! wget -q -O "$temp_dir/101.tar.gz" "https://gitproxy.click/https://github.com/duolaaa123/cipan/raw/main/101.tar.gz"; then
    echo "下载失败！请检查URL和网络连接。"
    rm -rf "$temp_dir"
    exit 1
fi

# 解压并验证内容
echo "正在解压并验证内容..."
if ! tar -xzf "$temp_dir/101.tar.gz" -C "$temp_dir"; then
    echo "解压失败！"
    rm -rf "$temp_dir"
    exit 1
fi

# 检查解压后的101目录是否存在
if [ ! -d "$temp_dir/101" ]; then
    echo "错误：压缩包中未找到101文件夹！解压内容如下："
    ls -l "$temp_dir"
    echo "请检查压缩包内容是否符合预期。"
    rm -rf "$temp_dir"
    exit 1
fi

# 5. 复制到选定的cache-bcdn目录
cache_dir="$selected_dir/cache-bcdn"
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
    if ! cp -r "$temp_dir/101" "$cache_dir/$new_name"; then
        echo "复制失败！请检查磁盘空间和权限。"
        rm -rf "$temp_dir"
        exit 1
    fi
done

# 清理
rm -rf "$temp_dir"
echo -e "\n操作成功完成！"
