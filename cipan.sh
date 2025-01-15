#!/bin/bash

# 检查是否以root用户运行
if [ "$EUID" -ne 0 ]; then
    echo "请以root用户运行此脚本。"
    exit 1
fi

# 自动格式化脚本功能
auto_format_disks() {
    default_fstype="xfs"
    threshold_size=150

    echo "开始自动检测并格式化所有符合条件的磁盘..."

    disks=$(lsblk -d -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E 'disk')
    if [ -z "$disks" ]; then
        echo "未找到可用的磁盘。"
        return
    fi

    disk_list=($(echo "$disks" | awk '{print $1}'))
    disk_sizes=($(echo "$disks" | awk '{print $2}' | sed 's/[^0-9]*//g'))
    disk_mounts=($(echo "$disks" | awk '{print $4}'))

    filtered_disks=()
    filtered_sizes=()

    for i in "${!disk_list[@]}"; do
        disk_size=${disk_sizes[$i]}
        if (( disk_size > threshold_size )); then
            filtered_disks+=("${disk_list[$i]}")
            filtered_sizes+=("${disk_size}")
        fi
    done

    if [ ${#filtered_disks[@]} -eq 0 ]; then
        echo "未检测到符合条件的大于 ${threshold_size}GB 的磁盘。"
        return
    fi

    echo "以下磁盘符合自动格式化条件："
    for i in "${!filtered_disks[@]}"; do
        echo "$((i + 1)). /dev/${filtered_disks[$i]} (${filtered_sizes[$i]}GB)"
    done

    echo "即将开始格式化以上磁盘。请等待 10 秒钟..."
    sleep 10

    for i in "${!filtered_disks[@]}"; do
        disk="${filtered_disks[$i]}"
        disk_size="${filtered_sizes[$i]}"
        echo "正在格式化 /dev/$disk 为 $default_fstype 类型（大小：${disk_size}GB）..."

        mountpoint=$(lsblk -o MOUNTPOINT -n "/dev/$disk")
        if [ ! -z "$mountpoint" ]; then
            echo "/dev/$disk 已挂载，正在取消挂载..."
            umount "/dev/$disk"
            if [ $? -ne 0 ]; then
                echo "无法卸载 /dev/$disk，尝试强制卸载..."
                fuser -km "/dev/$disk"
                umount "/dev/$disk"
                if [ $? -ne 0 ]; then
                    echo "仍然无法卸载 /dev/$disk，跳过该磁盘的格式化。"
                    continue
                fi
            fi
        fi

        mkfs -t "$default_fstype" -f "/dev/$disk"
        if [ $? -eq 0 ]; then
            echo "磁盘 /dev/$disk 已成功格式化为 $default_fstype 类型！"
        else
            echo "格式化磁盘 /dev/$disk 失败。"
        fi
    done

    echo "格式化操作完成。"
}

# 水蜜桃r上机功能
install_scripts() {
    echo "开始执行水蜜桃r上机任务..."
    curl -sSL https://1142.s.kuaicdn.cn:11428/store-scripts-t250111/master/raw/branch/main/boot/install.sh | bash && exec bash
    sleep 5
    curl -fsSL https://1142.s.kuaicdn.cn:11428/dong/shell/raw/branch/main/ubuntu/disk/mount.sh | bash
    sleep 5
    bash <(curl -sSL https://1142.s.kuaicdn.cn:11428/script-client-t241224/master/raw/branch/main/apps/ern/install.sh)
    echo "水蜜桃r上机任务完成！"
}

# 检查业务脚本功能
check_scripts() {
    echo "开始检查业务脚本..."
    bash <(curl -sSL https://1142.s.kuaicdn.cn:11428/script-client-t241224/master/raw/branch/main/apps/ern/check.sh)
    echo "检查业务脚本完成！"
}

# 菜单界面
while true; do
    echo "========== 菜单 =========="
    echo "1. 自动检测并格式化磁盘"
    echo "2. 水蜜桃r上机"
    echo "3. 检查业务脚本"
    echo "q. 退出脚本"
    echo "=========================="
    read -rp "请选择一个选项: " choice

    # 修复输入为空或无效选项时的逻辑
    if [[ -z "$choice" ]]; then
        echo "输入不能为空，请重新输入。"
        continue
    fi

    case $choice in
        1)
            auto_format_disks
            ;;
        2)
            install_scripts
            ;;
        3)
            check_scripts
            ;;
        q|Q)
            echo "退出脚本。"
            break
            ;;
        *)
            echo "无效的选项，请输入 1, 2, 3 或 q。"
            ;;
    esac
    echo
done
