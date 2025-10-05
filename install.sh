#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Fatal error: ${plain} Please run this script with root privilege \n " && exit 1

# Check OS and set release variable
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "Failed to check the system OS, please contact the author!" >&2
    exit 1
fi
echo "The OS release is: $release"

arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    armv6* | armv6) echo 'armv6' ;;
    armv5* | armv5) echo 'armv5' ;;
    s390x) echo 's390x' ;;
    *) echo -e "${green}Unsupported CPU architecture! ${plain}" && rm -f install.sh && exit 1 ;;
    esac
}

echo "Arch: $(arch)"

install_base() {
    case "${release}" in
    ubuntu | debian | armbian)
        apt-get update && apt-get install -y -q wget curl tar tzdata
        ;;
    centos | rhel | almalinux | rocky | ol)
        yum -y update && yum install -y -q wget curl tar tzdata
        ;;
    fedora | amzn | virtuozzo)
        dnf -y update && dnf install -y -q wget curl tar tzdata
        ;;
    arch | manjaro | parch)
        pacman -Syu && pacman -Syu --noconfirm wget curl tar tzdata
        ;;
    opensuse-tumbleweed)
        zypper refresh && zypper -q install -y wget curl tar timezone
        ;;
    alpine)
        apk update && apk add wget curl tar tzdata
        ;;
    *)
        apt-get update && apt-get install -y -q wget curl tar tzdata
        ;;
    esac
}

gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
    echo "$random_string"
}

config_after_install() {
    local existing_hasDefaultCredential=$(/usr/local/YOUNGSCOOLPLAY-UI/YOUNGSCOOLPLAY-UI setting -show true | grep -Eo 'hasDefaultCredential: .+' | awk '{print $2}')
    local existing_webBasePath=$(/usr/local/YOUNGSCOOLPLAY-UI/YOUNGSCOOLPLAY-UI setting -show true | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(/usr/local/YOUNGSCOOLPLAY-UI/YOUNGSCOOLPLAY-UI setting -show true | grep -Eo 'port: .+' | awk '{print $2}')
    local URL_lists=(
        "https://api4.ipify.org"
		"https://ipv4.icanhazip.com"
		"https://v4.api.ipinfo.io/ip"
		"https://ipv4.myexternalip.com/raw"
		"https://4.ident.me"
		"https://check-host.net/ip"
    )
    local server_ip=""
    for ip_address in "${URL_lists[@]}"; do
        server_ip=$(curl -s --max-time 3 "${ip_address}" 2>/dev/null | tr -d '[:space:]')
        if [[ -n "${server_ip}" ]]; then
            break
        fi
    done

    if [[ ${#existing_webBasePath} -lt 4 ]]; then
        if [[ "$existing_hasDefaultCredential" == "true" ]]; then
            local config_webBasePath=$(gen_random_string 18)
            local config_username=$(gen_random_string 10)
            local config_password=$(gen_random_string 10)

            read -rp "Would you like to customize the Panel Port settings? (If not, a random port will be applied) [y/n]: " config_confirm
            if [[ "${config_confirm}" == "y" || "${config_confirm}" == "Y" ]]; then
                read -rp "Please set up the panel port: " config_port
                echo -e "${yellow}Your Panel Port is: ${config_port}${plain}"
            else
                local config_port=$(shuf -i 1024-62000 -n 1)
                echo -e "${yellow}Generated random port: ${config_port}${plain}"
            fi

            /usr/local/YOUNGSCOOLPLAY-UI/YOUNGSCOOLPLAY-UI setting -username "${config_username}" -password "${config_password}" -port "${config_port}" -webBasePath "${config_webBasePath}"
            echo -e "This is a fresh installation, generating random login info for security concerns:"
            echo -e "###############################################"
            echo -e "${green}Username: ${config_username}${plain}"
            echo -e "${green}Password: ${config_password}${plain}"
            echo -e "${green}Port: ${config_port}${plain}"
            echo -e "${green}WebBasePath: ${config_webBasePath}${plain}"
            echo -e "${green}Access URL: http://${server_ip}:${config_port}/${config_webBasePath}${plain}"
            echo -e "###############################################"
        else
            local config_webBasePath=$(gen_random_string 18)
            echo -e "${yellow}WebBasePath is missing or too short. Generating a new one...${plain}"
            /usr/local/YOUNGSCOOLPLAY-UI/YOUNGSCOOLPLAY-UI setting -webBasePath "${config_webBasePath}"
            echo -e "${green}New WebBasePath: ${config_webBasePath}${plain}"
            echo -e "${green}Access URL: http://${server_ip}:${existing_port}/${config_webBasePath}${plain}"
        fi
    else
        if [[ "$existing_hasDefaultCredential" == "true" ]]; then
            local config_username=$(gen_random_string 10)
            local config_password=$(gen_random_string 10)

            echo -e "${yellow}Default credentials detected. Security update required...${plain}"
            /usr/local/YOUNGSCOOLPLAY-UI/YOUNGSCOOLPLAY-UI setting -username "${config_username}" -password "${config_password}"
            echo -e "Generated new random login credentials:"
            echo -e "###############################################"
            echo -e "${green}Username: ${config_username}${plain}"
            echo -e "${green}Password: ${config_password}${plain}"
            echo -e "###############################################"
        else
            echo -e "${green}Username, Password, and WebBasePath are properly set. Exiting...${plain}"
        fi
    fi

    /usr/local/YOUNGSCOOLPLAY-UI/YOUNGSCOOLPLAY-UI migrate
}

install_YOUNGSCOOLPLAY-UI() {
    cd /usr/local/

    # Download resources
    if [ $# == 0 ]; then
        tag_version=$(curl -Ls "https://api.github.com/repos/MHSanaei/3YOUNGSCOOLPLAY-UI/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$tag_version" ]]; then
            echo -e "${red}Failed to fetch YOUNGSCOOLPLAY-UI version, it may be due to GitHub API restrictions, please try it later${plain}"
            exit 1
        fi
        echo -e "Got YOUNGSCOOLPLAY-UI latest version: ${tag_version}, beginning the installation..."
        wget -N -O /usr/local/YOUNGSCOOLPLAY-UI-linux-$(arch).tar.gz https://github.com/MHSanaei/3YOUNGSCOOLPLAY-UI/releases/download/${tag_version}/YOUNGSCOOLPLAY-UI-linux-$(arch).tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Downloading YOUNGSCOOLPLAY-UI failed, please be sure that your server can access GitHub ${plain}"
            exit 1
        fi
    else
        tag_version=$1
        tag_version_numeric=${tag_version#v}
        min_version="2.3.5"

        if [[ "$(printf '%s\n' "$min_version" "$tag_version_numeric" | sort -V | head -n1)" != "$min_version" ]]; then
            echo -e "${red}Please use a newer version (at least v2.3.5). Exiting installation.${plain}"
            exit 1
        fi

        url="https://github.com/MHSanaei/3YOUNGSCOOLPLAY-UI/releases/download/${tag_version}/YOUNGSCOOLPLAY-UI-linux-$(arch).tar.gz"
        echo -e "Beginning to install YOUNGSCOOLPLAY-UI $1"
        wget -N -O /usr/local/YOUNGSCOOLPLAY-UI-linux-$(arch).tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Download YOUNGSCOOLPLAY-UI $1 failed, please check if the version exists ${plain}"
            exit 1
        fi
    fi
    wget -O /usr/bin/YOUNGSCOOLPLAY-UI-temp https://raw.githubusercontent.com/MHSanaei/3YOUNGSCOOLPLAY-UI/main/YOUNGSCOOLPLAY-UI.sh

    # Stop YOUNGSCOOLPLAY-UI service and remove old resources
    if [[ -e /usr/local/YOUNGSCOOLPLAY-UI/ ]]; then
        if [[ $release == "alpine" ]]; then
            rc-service YOUNGSCOOLPLAY-UI stop
        else
            systemctl stop YOUNGSCOOLPLAY-UI
        fi
        rm /usr/local/YOUNGSCOOLPLAY-UI/ -rf
    fi

    # Extract resources and set permissions
    tar zxvf YOUNGSCOOLPLAY-UI-linux-$(arch).tar.gz
    rm YOUNGSCOOLPLAY-UI-linux-$(arch).tar.gz -f
    
    cd YOUNGSCOOLPLAY-UI
    chmod +x YOUNGSCOOLPLAY-UI
    chmod +x YOUNGSCOOLPLAY-UI.sh

    # Check the system's architecture and rename the file accordingly
    if [[ $(arch) == "armv5" || $(arch) == "armv6" || $(arch) == "armv7" ]]; then
        mv bin/xray-linux-$(arch) bin/xray-linux-arm
        chmod +x bin/xray-linux-arm
    fi
    chmod +x YOUNGSCOOLPLAY-UI bin/xray-linux-$(arch)

    # Update YOUNGSCOOLPLAY-UI cli and se set permission
    mv -f /usr/bin/YOUNGSCOOLPLAY-UI-temp /usr/bin/YOUNGSCOOLPLAY-UI
    chmod +x /usr/bin/YOUNGSCOOLPLAY-UI
    config_after_install

    if [[ $release == "alpine" ]]; then
        wget -O /etc/init.d/YOUNGSCOOLPLAY-UI https://raw.githubusercontent.com/MHSanaei/3YOUNGSCOOLPLAY-UI/main/YOUNGSCOOLPLAY-UI.rc
        chmod +x /etc/init.d/YOUNGSCOOLPLAY-UI
        rc-update add YOUNGSCOOLPLAY-UI
        rc-service YOUNGSCOOLPLAY-UI start
    else
        cp -f YOUNGSCOOLPLAY-UI.service /etc/systemd/system/
        systemctl daemon-reload
        systemctl enable YOUNGSCOOLPLAY-UI
        systemctl start YOUNGSCOOLPLAY-UI
    fi

    echo -e "${green}YOUNGSCOOLPLAY-UI ${tag_version}${plain} installation finished, it is running now..."
    echo -e ""
    echo -e "┌───────────────────────────────────────────────────────�?�? ${blue}YOUNGSCOOLPLAY-UI control menu usages (subcommands):${plain}              �?�?                                                      �?�? ${blue}YOUNGSCOOLPLAY-UI${plain}              - Admin Management Script          �?�? ${blue}YOUNGSCOOLPLAY-UI start${plain}        - Start                            �?�? ${blue}YOUNGSCOOLPLAY-UI stop${plain}         - Stop                             �?�? ${blue}YOUNGSCOOLPLAY-UI restart${plain}      - Restart                          �?�? ${blue}YOUNGSCOOLPLAY-UI status${plain}       - Current Status                   �?�? ${blue}YOUNGSCOOLPLAY-UI settings${plain}     - Current Settings                 �?�? ${blue}YOUNGSCOOLPLAY-UI enable${plain}       - Enable Autostart on OS Startup   �?�? ${blue}YOUNGSCOOLPLAY-UI disable${plain}      - Disable Autostart on OS Startup  �?�? ${blue}YOUNGSCOOLPLAY-UI log${plain}          - Check logs                       �?�? ${blue}YOUNGSCOOLPLAY-UI banlog${plain}       - Check Fail2ban ban logs          �?�? ${blue}YOUNGSCOOLPLAY-UI update${plain}       - Update                           �?�? ${blue}YOUNGSCOOLPLAY-UI legacy${plain}       - legacy version                   �?�? ${blue}YOUNGSCOOLPLAY-UI install${plain}      - Install                          �?�? ${blue}YOUNGSCOOLPLAY-UI uninstall${plain}    - Uninstall                        �?└───────────────────────────────────────────────────────�?
}

echo -e "${green}Running...${plain}"
install_base
install_YOUNGSCOOLPLAY-UI $1
