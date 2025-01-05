
#!/bin/bash

# 检查是否以root用户运行
if [ "$EUID" -ne 0 ]; then
    echo "请以root用户运行此脚本。"
    exit 1
fi

# 设置默认分区类型
default_fstype="xfs"

# 设置大小阈值（单位：GB）
threshold_size=150

echo "开始自动检测并格式化所有符合条件的磁盘..."

# 列出所有磁盘（包括挂载和未挂载的磁盘）
disks=$(lsblk -d -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E 'disk')
if [ -z "$disks" ]; then
    echo "未找到可用的磁盘。"
    exit 1
fi

# 提取磁盘信息
disk_list=($(echo "$disks" | awk '{print $1}'))
disk_sizes=($(echo "$disks" | awk '{print $2}' | sed 's/[^0-9]*//g'))  # 只保留数字，去掉单位（如G）
disk_mounts=($(echo "$disks" | awk '{print $4}'))

# 过滤出大于阈值的磁盘（包括挂载的磁盘）
filtered_disks=()
filtered_sizes=()

for i in "${!disk_list[@]}"; do
    # 获取数字部分并进行大小比较
    disk_size=${disk_sizes[$i]}
    if (( disk_size > threshold_size )); then
        filtered_disks+=("${disk_list[$i]}")
        filtered_sizes+=("${disk_size}")
    fi
done

if [ ${#filtered_disks[@]} -eq 0 ]; then
    echo "未检测到符合条件的大于 ${threshold_size}GB 的磁盘。"
    exit 0
fi

echo "以下磁盘符合自动格式化条件："
for i in "${!filtered_disks[@]}"; do
    echo "$((i + 1)). /dev/${filtered_disks[$i]} (${filtered_sizes[$i]}GB)"
done

echo "即将开始格式化以上磁盘。请等待 10 秒钟..."

# 等待 10 秒钟，用户可以选择是否继续
sleep 10

# 自动格式化符合条件的磁盘（包括挂载的磁盘）
for i in "${!filtered_disks[@]}"; do
    disk="${filtered_disks[$i]}"
    disk_size="${filtered_sizes[$i]}"
    echo "正在格式化 /dev/$disk 为 $default_fstype 类型（大小：${disk_size}GB）..."

    # 检查磁盘是否已挂载
    mountpoint=$(lsblk -o MOUNTPOINT -n "/dev/$disk")
    if [ ! -z "$mountpoint" ]; then
        echo "/dev/$disk 已挂载，正在取消挂载..."
        umount "/dev/$disk"
        if [ $? -ne 0 ]; then
            echo "无法卸载 /dev/$disk，尝试强制卸载..."
            fuser -km "/dev/$disk"  # 强制停止所有占用该磁盘的进程
            umount "/dev/$disk"     # 再次尝试卸载
            if [ $? -ne 0 ]; then
                echo "仍然无法卸载 /dev/$disk，跳过该磁盘的格式化。"
                continue
            fi
        fi
    fi

    # 执行格式化，使用 -f 强制覆盖
    mkfs -t "$default_fstype" -f "/dev/$disk"
    
    if [ $? -eq 0 ]; then
        echo "磁盘 /dev/$disk 已成功格式化为 $default_fstype 类型！"
    else
        echo "格式化磁盘 /dev/$disk 失败。"
    fi
done

# 显示格式化结果
echo "格式化操作完成。"
