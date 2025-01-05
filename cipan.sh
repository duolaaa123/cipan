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

while true; do
    echo "正在检测所有磁盘（排除小于 ${threshold_size}GB 的磁盘）..."

    # 列出所有磁盘
    disks=$(lsblk -d -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E 'disk')
    if [ -z "$disks" ]; then
        echo "未找到可用的磁盘。"
        exit 1
    fi

    # 提取磁盘信息
    disk_list=($(echo "$disks" | awk '{print $1}'))
    disk_sizes=($(echo "$disks" | awk '{print $2}' | sed 's/G//'))
    disk_mounts=($(echo "$disks" | awk '{print $4}'))

    # 过滤出大于阈值且未挂载为系统盘的磁盘
    filtered_disks=()
    filtered_sizes=()

    for i in "${!disk_list[@]}"; do
        if (( ${disk_sizes[$i]} > threshold_size )) && [[ -z "${disk_mounts[$i]}" || "${disk_mounts[$i]}" == " " ]]; then
            filtered_disks+=("${disk_list[$i]}")
            filtered_sizes+=("${disk_sizes[$i]}")
        fi
    done

    if [ ${#filtered_disks[@]} -eq 0 ]; then
        echo "未检测到符合条件的大于 ${threshold_size}GB 的非系统盘。"
        exit 0
    fi

    echo "以下是可用的磁盘："
    for i in "${!filtered_disks[@]}"; do
        echo "$((i + 1)). ${filtered_disks[$i]} (${filtered_sizes[$i]}G)"
    done

    # 自动格式化符合条件的磁盘
    for i in "${!filtered_disks[@]}"; do
        echo "发现符合条件的磁盘：/dev/${filtered_disks[$i]} (${filtered_sizes[$i]}G)"
        # 自动格式化磁盘，无需用户确认
        echo "正在格式化 /dev/${filtered_disks[$i]} 为 $default_fstype 类型..."
        umount "/dev/${filtered_disks[$i]}" 2>/dev/null
        mkfs -t "$default_fstype" "/dev/${filtered_disks[$i]}"

        if [ $? -eq 0 ]; then
            echo "磁盘 /dev/${filtered_disks[$i]} 已成功格式化为 $default_fstype 类型！"
        else
            echo "格式化磁盘 /dev/${filtered_disks[$i]} 失败。"
        fi
    done

    # 手动选择其他磁盘
    read -p "请输入要格式化的磁盘序号（1-${#filtered_disks[@]}，或按 'q' 退出）： " disk_num

    # 检查是否退出
    if [[ "$disk_num" == "q" ]]; then
        echo "退出脚本。"
        break
    fi

    # 验证输入
    if ! [[ "$disk_num" =~ ^[0-9]+$ ]] || [ "$disk_num" -lt 1 ] || [ "$disk_num" -gt "${#filtered_disks[@]}" ]; then
        echo "无效的输入，请重新选择。"
        continue
    fi

    # 获取选择的磁盘名称
    disk=${filtered_disks[$((disk_num - 1))]}

    # 确认用户输入
    read -p "确定要格式化 /dev/$disk 吗？所有数据将会丢失！(y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "操作已取消。"
        continue
    fi

    # 提示用户选择分区类型
    read -p "请输入分区类型（如 xfs、ext4、ntfs 等，默认为 $default_fstype）： " fstype
    fstype=${fstype:-$default_fstype}

    # 执行格式化
    echo "正在格式化 /dev/$disk 为 $fstype 类型..."
    umount "/dev/$disk" 2>/dev/null
    mkfs -t "$fstype" "/dev/$disk"

    if [ $? -eq 0 ]; then
        echo "磁盘 /dev/$disk 已成功格式化为 $fstype 类型！"
    else
        echo "格式化磁盘 /dev/$disk 失败。"
    fi

    # 显示结果
    lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT | grep "$disk"
    echo "操作完成。"
    echo
done
