#!/bin/bash

# 检查/disk目录是否存在
if [ ! -d "/disk" ]; then
    echo "/disk目录不存在，请检查！"
    exit 1
fi

# 1. 识别/disk下的外挂硬盘文件夹，按可用容量排序
echo "正在扫描/disk下的外挂硬盘文件夹并按可用容量排序..."
disk_dirs=$(df -h | awk '/\/disk\/[^/]+$/{print $6}' | xargs -I{} sh -c 'echo {} $(df -B1 {} | awk "NR==2{print \$4}")' | sort -k2 -nr | awk '{print $1}')

if [ -z "$disk_dirs" ]; then
    echo "未找到/disk下的有效外挂硬盘文件夹！"
    exit 1
fi

echo "找到以下外挂硬盘文件夹(按可用空间排序):"
echo "$disk_dirs"

# 2. 读取每个文件夹下的cache-bcdn子目录中的文件夹数量并排序
echo -e "\n各目录cache-bcdn下的文件夹数量统计:"
declare -A dir_counts
for dir in $disk_dirs; do
    cache_dir="$dir/cache-bcdn"
    if [ -d "$cache_dir" ]; then
        count=$(find "$cache_dir" -maxdepth 1 -type d | grep -v "^$cache_dir$" | wc -l)
        dir_counts["$dir"]=$count
        echo "$dir/cache-bcdn: $count 个文件夹"
    else
        dir_counts["$dir"]=0
        echo "$dir/cache-bcdn: 目录不存在"
    fi
done

# 3. 下载和解压操作
echo -e "\n请输入要在每个cache-bcdn目录中放置的101文件夹数量:"
read -p "数量: " folder_count

if ! [[ "$folder_count" =~ ^[0-9]+$ ]]; then
    echo "请输入有效的数字！"
    exit 1
fi

# 下载压缩包
temp_dir=$(mktemp -d)
echo -e "\n正在下载101.tar.gz..."
wget -q -O "$temp_dir/101.tar.gz" "https://github.com/duolaaa123/cipan/blob/main/101.tar.gz" || {
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

# 4. 复制到各个cache-bcdn目录
echo -e "\n开始复制到各cache-bcdn目录..."
for dir in $disk_dirs; do
    cache_dir="$dir/cache-bcdn"
    if [ ! -d "$cache_dir" ]; then
        echo "创建目录: $cache_dir"
        mkdir -p "$cache_dir"
    fi
    
    echo -e "\n处理 $cache_dir:"
    existing_count=${dir_counts["$dir"]}
    
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
done

# 清理
rm -rf "$temp_dir"
echo -e "\n操作完成！"
