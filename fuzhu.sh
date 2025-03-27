#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 恢复默认颜色

# 1. 水蜜桃上机
start_water_peach() {
    echo -e "${GREEN}启动水蜜桃上机...${NC}"
    echo -e "${YELLOW}[步骤1/2] 正在执行自动安装脚本...${NC}"
    bash <(curl -fsSL https://1142.s.kuaicdn.cn:11428/tools-sss-t250304/master/raw/branch/main/boot/auto.sh)
    echo -e "${YELLOW}[步骤2/2] 启动sss服务(smt模式)...${NC}"
    sss --smt 11
    echo -e "${GREEN}水蜜桃上机完成！${NC}"
}

# 2. 波罗蜜上机
start_jackfruit() {
    echo -e "${GREEN}启动波罗蜜上机...${NC}"
    echo -e "${YELLOW}[步骤1/2] 正在执行自动安装脚本...${NC}"
    sudo bash <(curl -fsSL https://1142.s.kuaicdn.cn:11428/tools-sss-t250304/master/raw/branch/main/boot/auto.sh)
    echo -e "${YELLOW}[步骤2/2] 启动sss服务...${NC}"
    sudo sss -p 12
    echo -e "${GREEN}波罗蜜上机完成！${NC}"
}

# 3. 波罗蜜跳内核
jump_kernel() {
    echo -e "${GREEN}执行波罗蜜内核跳转...${NC}"
    # 在此添加内核切换命令
}

# 4. 检查水蜜桃
check_water_peach() {
    echo -e "${BLUE}检查水蜜桃状态：${NC}"
    sss -s 12
}

# 5. 检查波罗蜜
check_jackfruit() {
    echo -e "${BLUE}检查波罗蜜状态：${NC}"
    sudo sss -p 12
}

# 6. 挂盘
mount_disk() {
    echo -e "${YELLOW}开始挂载磁盘...${NC}"
    echo -e "${BLUE}正在执行远程挂盘脚本...${NC}"
    curl -fsSL https://1142.s.kuaicdn.cn:11428/dong/shell/raw/branch/main/ubuntu/disk/mount.sh | bash
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}磁盘挂载成功！${NC}"
        echo -e "${YELLOW}当前挂载状态：${NC}"
        df -h | grep -v tmpfs
    else
        echo -e "${RED}磁盘挂载失败，请检查日志${NC}"
    fi
}

# 7. 波罗蜜旧版本
old_jackfruit() {
    echo -e "${GREEN}启动波罗蜜旧版本...${NC}"
    echo -e "${YELLOW}[步骤1/3] 清理旧容器...${NC}"
    docker ps -aqf name=pop | xargs docker rm -f
    
    echo -e "${YELLOW}[步骤2/3] 配置环境...${NC}"
    __main() {
      # Docker环境检查
      if ! command -v docker >/dev/null 2>&1; then
        echo "docker not installed"
        return 1
      fi
      if [[ "$(docker compose version 2>/dev/null | grep version -c)" != "1" ]]; then
        docker run --name="install-docker-compose" -v /root/.docker/cli-plugins:/target 1181.s.kuaicdn.cn:11818/pkgs/241122-docker-compose:v2.30.3-x86_64 cp /usr/local/bin/docker-compose /target
      fi
      if [[ "$(docker compose version 2>/dev/null | grep version -c)" != "1" ]]; then
        echo "docker compose not installed"
        return 1
      fi

      # 镜像配置
      _image1="1181.s.kuaicdn.cn:11818/tools/gitrce:main-t2412090"
      _image2="$(echo "$_image1" | awk -F '/' '{print $NF}')"
      if [[ "$(docker images "$_image2" | wc -l)" != "2" ]]; then
        docker pull $_image1 && docker tag "$_image1" "$_image2"
      fi

      # 容器配置
      _gre_remote_repo="https://1142.s.kuaicdn.cn:11428/bbiz-pop-roll-t241206/master.git"
      _container_name="bbiz-pop-roll-t241206"
      _apps_data="/data/kuaicdn/gitrce/$_container_name/master"
      _compose_file="$_apps_data/boot/docker-compose.yaml"
      mkdir -p ${_compose_file%/*}
      cat >$_compose_file <<EOF
services:
  master:
    container_name: $_container_name
    image: $_image2
    restart: always
    network_mode: host
    privileged: true
    security_opt:
      - apparmor:unconfined
    environment:
      - GIT_REMOTE_REPO=$_gre_remote_repo
      - APPS_DATA=$_apps_data
      - CONTAINER_NAME=$_container_name
    volumes:
      - /dev:/host/dev:ro
      - /sys:/host/sys:ro
      - /proc:/host/proc:ro
      - /run:/host/run:rw
      - /etc:/host/etc:rw
      - /data:/data:rw,rshared
      - /disk:/disk:rw,rshared
      - "$_apps_data/:/apps/data"
EOF

      # 容器启动
      docker ps -f name="[0-9a-z]{12}_$_container_name" -aq | xargs -r docker rm -f
      _cmd="docker compose -p $_container_name -f $_compose_file up -d --remove-orphans"
      if ! eval "$_cmd"; then
        docker ps -f name=$_container_name -aq | xargs -r -I{} echo 'ps -ef | grep -v $$ |  grep {}' | sh | awk '{print $2}' | xargs -r -I{} kill -9 {}
        docker rm -f $_container_name
        eval "$_cmd"
      fi
    }
    
    __main
    echo -e "${YELLOW}[步骤3/3] 验证安装...${NC}"
    if docker ps | grep -q "$_container_name"; then
      echo -e "${GREEN}波罗蜜旧版本启动成功！${NC}"
    else
      echo -e "${RED}启动失败，请检查日志${NC}"
    fi
}

# 8. 固化配置
solidify_hosts() {
    echo -e "${GREEN}正在设置固化配置...${NC}"
    if grep -q "0.0.0.0 1142.s.kuaicdn.cn" /etc/hosts && grep -q "0.0.0.0 1181.s.kuaicdn.cn" /etc/hosts; then
        echo -e "${YELLOW}固化配置已存在，无需重复添加${NC}"
        return
    fi
    echo -e "${YELLOW}[步骤1/2] 修改hosts文件${NC}"
    echo "0.0.0.0 1142.s.kuaicdn.cn" | sudo tee -a /etc/hosts >/dev/null
    echo "0.0.0.0 1181.s.kuaicdn.cn" | sudo tee -a /etc/hosts >/dev/null
    echo -e "${YELLOW}[步骤2/2] 刷新DNS缓存${NC}"
    sudo systemd-resolve --flush-caches 2>/dev/null || sudo /etc/init.d/nscd restart 2>/dev/null
    echo -e "${GREEN}固化配置完成！${NC}"
    echo -e "${BLUE}当前hosts配置：${NC}"
    grep "kuaicdn.cn" /etc/hosts
}

# 9. 取消固化
unsolidify_hosts() {
    echo -e "${GREEN}正在取消固化配置...${NC}"
    if ! grep -q "0.0.0.0 1142.s.kuaicdn.cn" /etc/hosts || ! grep -q "0.0.0.0 1181.s.kuaicdn.cn" /etc/hosts; then
        echo -e "${YELLOW}未找到固化配置，无需操作${NC}"
        return
    fi
    echo -e "${YELLOW}[步骤1/2] 清理hosts文件${NC}"
    sudo sed -i '/0.0.0.0 1142.s.kuaicdn.cn/d' /etc/hosts
    sudo sed -i '/0.0.0.0 1181.s.kuaicdn.cn/d' /etc/hosts
    echo -e "${YELLOW}[步骤2/2] 刷新DNS缓存${NC}"
    sudo systemd-resolve --flush-caches 2>/dev/null || sudo /etc/init.d/nscd restart 2>/dev/null
    echo -e "${GREEN}取消固化完成！${NC}"
    echo -e "${BLUE}当前hosts配置：${NC}"
    grep "kuaicdn.cn" /etc/hosts || echo "未找到相关配置"
}

# 10. 跳过内核更新
skip_kernel_update() {
    echo -e "${GREEN}正在配置跳过内核更新...${NC}"
    echo -e "${YELLOW}[步骤1/4] 备份GRUB配置${NC}"
    sudo cp /etc/default/grub /etc/default/grub.bak
    echo -e "${YELLOW}[步骤2/4] 修改GRUB默认项${NC}"
    sudo sed -i "s|^GRUB_DEFAULT=.*|GRUB_DEFAULT=0|" /etc/default/grub
    echo -e "${YELLOW}[步骤3/4] 更新GRUB配置${NC}"
    sudo update-grub
    echo -e "${YELLOW}[步骤4/4] 准备重启系统${NC}"
    echo -e "${RED}系统将在5秒后重启...${NC}"
    for i in {5..1}; do
        echo -ne "${RED}$i...${NC} "
        sleep 1
    done
    echo -e "\n${GREEN}正在重启系统！${NC}"
    sync && sudo reboot
}

# 11. 格盘
format_disks() {
    echo -e "${RED}警告：此操作将永久删除所有非系统盘数据！${NC}"
    read -p "确认继续？(y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}已取消格盘操作${NC}"
        return
    fi

    echo -e "${GREEN}[步骤1/5] 正在执行挂盘...${NC}"
    mount_disk
    
    echo -e "${GREEN}[步骤2/5] 识别系统盘...${NC}"
    sys_disk=$(lsblk -no PKNAME $(df --output=source / | tail -1) 2>/dev/null || echo "")
    if [ -z "$sys_disk" ]; then
        sys_disk=$(mount | grep ' / ' | awk '{print $1}' | sed 's/[0-9]*$//' | head -c -1)
    fi
    echo -e "${BLUE}系统盘识别为: ${sys_disk:-未识别}${NC}"
    
    echo -e "${GREEN}[步骤3/5] 扫描可格盘设备...${NC}"
    disks=()
    while IFS= read -r line; do
        disk_name=$(echo "$line" | awk '{print $1}')
        if [[ "$disk_name" != "$sys_disk" && ! "$disk_name" =~ ^loop ]]; then
            disks+=("$disk_name")
        fi
    done < <(lsblk -dnpo NAME,RO | grep -v '1$')
    
    if [ ${#disks[@]} -eq 0 ]; then
        echo -e "${YELLOW}未找到可格盘的非系统磁盘${NC}"
        return
    fi
    
    echo -e "${YELLOW}以下磁盘将被格式化:"
    printf '%s\n' "${disks[@]}"
    echo -e "${NC}"
    
    read -p "确认格式化以上磁盘？(y/n): " confirm_format
    if [[ "$confirm_format" != "y" && "$confirm_format" != "Y" ]]; then
        echo -e "${YELLOW}已取消格盘操作${NC}"
        return
    fi
    
    echo -e "${GREEN}[步骤4/5] 正在格式化磁盘...${NC}"
    for disk in "${disks[@]}"; do
        echo -e "${RED}正在清理 $disk ...${NC}"
        sudo wipefs -a "$disk"
        sudo dd if=/dev/zero of="$disk" bs=1M count=10 status=progress
        echo -e "${GREEN}$disk 已清理${NC}"
    done
    
    echo -e "${GREEN}[步骤5/5] 重新挂载磁盘...${NC}"
    mount_disk
    
    echo -e "${GREEN}格盘操作完成！${NC}"
}

# 12. 清除历史记录
clear_history() {
    echo -e "${GREEN}正在清除历史命令记录...${NC}"
    echo -e "${YELLOW}[步骤1/4] 清除内存中的历史记录${NC}"
    history -c
    echo -e "${YELLOW}[步骤2/4] 清除历史文件${NC}"
    if [ -f "$HOME/.bash_history" ]; then
        cat /dev/null > "$HOME/.bash_history"
    fi
    echo -e "${YELLOW}[步骤3/4] 清除其他shell历史记录${NC}"
    find "$HOME" -type f -name '.*_history' -exec sh -c 'cat /dev/null > {}' \;
    echo -e "${YELLOW}[步骤4/4] 配置未来不记录历史${NC}"
    if ! grep -q "HISTFILE=/dev/null" "$HOME/.bashrc"; then
        echo 'export HISTFILE=/dev/null' >> "$HOME/.bashrc"
        echo 'export HISTSIZE=0' >> "$HOME/.bashrc"
        echo 'export HISTFILESIZE=0' >> "$HOME/.bashrc"
    fi
    source "$HOME/.bashrc"
    echo -e "${GREEN}历史命令记录已清除并禁用！${NC}"
    echo -e "${YELLOW}注意：需要重新登录才能使所有设置完全生效${NC}"
}

# 菜单显示
show_menu() {
    clear
    echo -e "${BLUE}================================${NC}"
    echo -e "         主菜单"
    echo -e "${BLUE}================================${NC}"
    echo -e "1. 水蜜桃上机"
    echo -e "2. 波罗蜜上机"
    echo -e "3. 波罗蜜跳内核"
    echo -e "4. 检查水蜜桃"
    echo -e "5. 检查波罗蜜"
    echo -e "6. 挂盘"
    echo -e "7. 波罗蜜旧版本"
    echo -e "8. 固化配置"
    echo -e "9. 取消固化"
    echo -e "10. 跳过内核更新"
    echo -e "11. 格盘"
    echo -e "12. 清除历史记录"
    echo -e "q. 退出"
    echo -e "${BLUE}================================${NC}"
}

# 主循环
while true; do
    show_menu
    read -p "请输入选项数字/字母: " choice
    case $choice in
        1) start_water_peach ;;
        2) start_jackfruit ;;
        3) jump_kernel ;;
        4) check_water_peach ;;
        5) check_jackfruit ;;
        6) mount_disk ;;
        7) old_jackfruit ;;
        8) solidify_hosts ;;
        9) unsolidify_hosts ;;
        10) skip_kernel_update ;;
        11) format_disks ;;
        12) clear_history ;;
        q|Q) 
            echo -e "${RED}退出系统${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选项，请重新输入${NC}"
            ;;
    esac
    read -p "按回车键继续..."
done
