#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================
#	System Required: CentOS 7/8,Debian/ubuntu,oraclelinux
#	Description: BBR+BBRplus+Lotserver
#	Version: 2025.12.1
#	Author: 千影,cx9208,YLX
#	更新内容及反馈:  https://blog.ylx.me/archives/783.html
#=================================================

# RED='\033[0;31m'
# GREEN='\033[0;32m'
# YELLOW='\033[0;33m'
# SKYBLUE='\033[0;36m'
# PLAIN='\033[0m'

sh_ver="2025.12.1"
github="raw.githubusercontent.com/97668589/BBR-NetSpeed/master"

imgurl=""
headurl=""

Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

if [ -f "/etc/sysctl.d/bbr.conf" ]; then
  rm -rf /etc/sysctl.d/bbr.conf
fi

#检查连接
checkurl() {
  url=$(curl --max-time 5 --retry 3 --retry-delay 2 --connect-timeout 2 -s --head $1 | head -n 1)
  # echo ${url}
  if [[ ${url} == *200* || ${url} == *302* || ${url} == *308* ]]; then
    echo "下载地址检查OK，继续！"
  else
    echo "下载地址检查出错，退出！"
    exit 1
  fi
}

#cn使用fastgit.org的github加速
check_cn() {
  geoip=$(wget --user-agent="Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36" --no-check-certificate -qO- https://api.ip.sb/geoip -T 10 | grep "\"country_code\":\"CN\"")
  if [[ "$geoip" != "" ]]; then
    # echo "下面使用fastgit.org的加速服务"
    # echo ${1//github.com/download.fastgit.org}
	echo https://endpoint.fastgit.org/$1
  else
    echo $1
  fi
}

#安装BBR内核
installbbr() {
  kernel_version="5.9.6"
  bit=$(uname -m)
  rm -rf bbr
  mkdir bbr && cd bbr || exit

  if [[ "${release}" == "centos" ]]; then
    if [[ ${version} == "7" ]]; then
      if [[ ${bit} == "x86_64" ]]; then
        echo -e "如果下载地址出错，可能当前正在更新，超过半天还是出错请反馈，大陆自行解决污染问题"
        #github_ver=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}' | awk -F '[_]' '{print $3}')
        github_tag=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep 'Centos_Kernel' | grep '_latest_bbr_' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
        github_ver=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}')
        echo -e "获取的版本号为:${github_ver}"
        kernel_version=$github_ver
        detele_kernel_head
        headurl=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}')
        imgurl=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep -v 'headers' | grep -v 'devel' | awk -F '"' '{print $4}')
        #headurl=https://github.com/97668589/kernel/releases/download/$github_tag/kernel-headers-${github_ver}-1.x86_64.rpm
        #imgurl=https://github.com/97668589/kernel/releases/download/$github_tag/kernel-${github_ver}-1.x86_64.rpm

        headurl=$(check_cn $headurl)
        imgurl=$(check_cn $imgurl)
        echo -e "正在检查headers下载连接...."
        checkurl $headurl
        echo -e "正在检查内核下载连接...."
        checkurl $imgurl
        wget -N -O kernel-headers-c7.rpm $headurl
        wget -N -O kernel-c7.rpm $imgurl
        yum install -y kernel-c7.rpm
        yum install -y kernel-headers-c7.rpm
      else
        echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
      fi
    fi

  elif [[ "${release}" == "ubuntu" || "${release}" == "debian" ]]; then
    if [[ ${bit} == "x86_64" ]]; then
      echo -e "如果下载地址出错，可能当前正在更新，超过半天还是出错请反馈，大陆自行解决污染问题"
      github_tag=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep 'Ubuntu_Kernel' | grep '_latest_bbr_' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
      github_ver=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'deb' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}' | awk -F '[_]' '{print $1}')
      echo -e "获取的版本号为:${github_ver}"
      kernel_version=$github_ver
      detele_kernel_head
      headurl=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'deb' | grep 'headers' | awk -F '"' '{print $4}')
      imgurl=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'deb' | grep -v 'headers' | grep -v 'devel' | awk -F '"' '{print $4}')
      #headurl=https://github.com/97668589/kernel/releases/download/$github_tag/linux-headers-${github_ver}_${github_ver}-1_amd64.deb
      #imgurl=https://github.com/97668589/kernel/releases/download/$github_tag/linux-image-${github_ver}_${github_ver}-1_amd64.deb

      headurl=$(check_cn $headurl)
      imgurl=$(check_cn $imgurl)
      echo -e "正在检查headers下载连接...."
      checkurl $headurl
      echo -e "正在检查内核下载连接...."
      checkurl $imgurl
      wget -N -O linux-headers-d10.deb $headurl
      wget -N -O linux-image-d10.deb $imgurl
      dpkg -i linux-image-d10.deb
      dpkg -i linux-headers-d10.deb
    elif [[ ${bit} == "aarch64" ]]; then
      echo -e "如果下载地址出错，可能当前正在更新，超过半天还是出错请反馈，大陆自行解决污染问题"
      github_tag=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep 'Ubuntu_Kernel' | grep '_arm64_' | grep '_bbr_' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
      github_ver=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'deb' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}' | awk -F '[_]' '{print $1}')
      echo -e "获取的版本号为:${github_ver}"
      kernel_version=$github_ver
      detele_kernel_head
      headurl=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'deb' | grep 'headers' | awk -F '"' '{print $4}')
      imgurl=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'deb' | grep -v 'headers' | grep -v 'devel' | awk -F '"' '{print $4}')
      #headurl=https://github.com/97668589/kernel/releases/download/$github_tag/linux-headers-${github_ver}_${github_ver}-1_amd64.deb
      #imgurl=https://github.com/97668589/kernel/releases/download/$github_tag/linux-image-${github_ver}_${github_ver}-1_amd64.deb
      
      headurl=$(check_cn $headurl)
      imgurl=$(check_cn $imgurl)
	  echo -e "正在检查headers下载连接...."
      checkurl $headurl
      echo -e "正在检查内核下载连接...."
      checkurl $imgurl
      wget -N -O linux-headers-d10.deb $headurl
      wget -N -O linux-image-d10.deb $imgurl
      dpkg -i linux-image-d10.deb
      dpkg -i linux-headers-d10.deb
    else
      echo -e "${Error} 不支持x86_64及arm64/aarch64以外的系统 !" && exit 1
    fi
  fi

  cd .. && rm -rf bbr

  BBR_grub
  echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
  check_kernel
}

#安装BBRplus内核 4.14.129
installbbrplus() {
  kernel_version="4.14.160-bbrplus"
  bit=$(uname -m)
  rm -rf bbrplus
  mkdir bbrplus && cd bbrplus || exit
  if [[ "${release}" == "centos" ]]; then
    if [[ ${version} == "7" ]]; then
      if [[ ${bit} == "x86_64" ]]; then
        kernel_version="4.14.129_bbrplus"
        detele_kernel_head
        headurl=https://github.com/cx9208/Linux-NetSpeed/raw/master/bbrplus/centos/7/kernel-headers-4.14.129-bbrplus.rpm
        imgurl=https://github.com/cx9208/Linux-NetSpeed/raw/master/bbrplus/centos/7/kernel-4.14.129-bbrplus.rpm

        headurl=$(check_cn $headurl)
        imgurl=$(check_cn $imgurl)
        echo -e "正在检查headers下载连接...."
        checkurl $headurl
        echo -e "正在检查内核下载连接...."
        checkurl $imgurl
        wget -N -O kernel-headers-c7.rpm $headurl
        wget -N -O kernel-c7.rpm $imgurl
        yum install -y kernel-c7.rpm
        yum install -y kernel-headers-c7.rpm
      else
        echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
      fi
    fi

  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    if [[ ${bit} == "x86_64" ]]; then
      kernel_version="4.14.129-bbrplus"
      detele_kernel_head
      headurl=https://github.com/cx9208/Linux-NetSpeed/raw/master/bbrplus/debian-ubuntu/x64/linux-headers-4.14.129-bbrplus.deb
      imgurl=https://github.com/cx9208/Linux-NetSpeed/raw/master/bbrplus/debian-ubuntu/x64/linux-image-4.14.129-bbrplus.deb

      headurl=$(check_cn $headurl)
      imgurl=$(check_cn $imgurl)
      echo -e "正在检查headers下载连接...."
      checkurl $headurl
      echo -e "正在检查内核下载连接...."
      checkurl $imgurl
      wget -N -O linux-headers.deb $headurl
      wget -N -O linux-image.deb $imgurl

      dpkg -i linux-image.deb
      dpkg -i linux-headers.deb
    else
      echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
    fi
  fi

  cd .. && rm -rf bbrplus
  BBR_grub
  echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
  check_kernel
}

#安装Lotserver内核
installlot() {
  bit=$(uname -m)
  if [[ ${bit} != "x86_64" ]]; then
    echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
  fi
  if [[ ${bit} == "x86_64" ]]; then
    bit='x64'
  fi
  if [[ ${bit} == "i386" ]]; then
    bit='x32'
  fi
  if [[ "${release}" == "centos" ]]; then
    rpm --import http://${github}/lotserver/${release}/RPM-GPG-KEY-elrepo.org
    yum remove -y kernel-firmware
    yum install -y http://${github}/lotserver/${release}/${version}/${bit}/kernel-firmware-${kernel_version}.rpm
    yum install -y http://${github}/lotserver/${release}/${version}/${bit}/kernel-${kernel_version}.rpm
    yum remove -y kernel-headers
    yum install -y http://${github}/lotserver/${release}/${version}/${bit}/kernel-headers-${kernel_version}.rpm
    yum install -y http://${github}/lotserver/${release}/${version}/${bit}/kernel-devel-${kernel_version}.rpm
  fi

  if [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    deb_issue="$(cat /etc/issue)"
    deb_relese="$(echo $deb_issue | grep -io 'Ubuntu\|Debian' | sed -r 's/(.*)/\L\1/')"
    os_ver="$(dpkg --print-architecture)"
    [ -n "$os_ver" ] || exit 1
    if [ "$deb_relese" == 'ubuntu' ]; then
      deb_ver="$(echo $deb_issue | grep -o '[0-9]*\.[0-9]*' | head -n1)"
      if [ "$deb_ver" == "14.04" ]; then
        kernel_version="3.16.0-77-generic" && item="3.16.0-77-generic" && ver='trusty'
      elif [ "$deb_ver" == "16.04" ]; then
        kernel_version="4.8.0-36-generic" && item="4.8.0-36-generic" && ver='xenial'
      elif [ "$deb_ver" == "18.04" ]; then
        kernel_version="4.15.0-30-generic" && item="4.15.0-30-generic" && ver='bionic'
      else
        exit 1
      fi
      url='archive.ubuntu.com'
      urls='security.ubuntu.com'
    elif [ "$deb_relese" == 'debian' ]; then
      deb_ver="$(echo $deb_issue | grep -o '[0-9]*' | head -n1)"
      if [ "$deb_ver" == "7" ]; then
        kernel_version="3.2.0-4-${os_ver}" && item="3.2.0-4-${os_ver}" && ver='wheezy' && url='archive.debian.org' && urls='archive.debian.org'
      elif [ "$deb_ver" == "8" ]; then
        kernel_version="3.16.0-4-${os_ver}" && item="3.16.0-4-${os_ver}" && ver='jessie' && url='archive.debian.org' && urls='deb.debian.org'
      elif [ "$deb_ver" == "9" ]; then
        kernel_version="4.9.0-4-${os_ver}" && item="4.9.0-4-${os_ver}" && ver='stretch' && url='deb.debian.org' && urls='deb.debian.org'
      else
        exit 1
      fi
    fi
    [ -n "$item" ] && [ -n "$urls" ] && [ -n "$url" ] && [ -n "$ver" ] || exit 1
    if [ "$deb_relese" == 'ubuntu' ]; then
      echo "deb http://${url}/${deb_relese} ${ver} main restricted universe multiverse" >/etc/apt/sources.list
      echo "deb http://${url}/${deb_relese} ${ver}-updates main restricted universe multiverse" >>/etc/apt/sources.list
      echo "deb http://${url}/${deb_relese} ${ver}-backports main restricted universe multiverse" >>/etc/apt/sources.list
      echo "deb http://${urls}/${deb_relese} ${ver}-security main restricted universe multiverse" >>/etc/apt/sources.list

      apt-get update || apt-get --allow-releaseinfo-change update
      apt-get install --no-install-recommends -y linux-image-${item}
    elif [ "$deb_relese" == 'debian' ]; then
      echo "deb http://${url}/${deb_relese} ${ver} main" >/etc/apt/sources.list
      echo "deb-src http://${url}/${deb_relese} ${ver} main" >>/etc/apt/sources.list
      echo "deb http://${urls}/${deb_relese}-security ${ver}/updates main" >>/etc/apt/sources.list
      echo "deb-src http://${urls}/${deb_relese}-security ${ver}/updates main" >>/etc/apt/sources.list

      if [ "$deb_ver" == "8" ]; then
        dpkg -l | grep -q 'linux-base' || {
          wget --no-check-certificate -qO '/tmp/linux-base_3.5_all.deb' 'http://snapshot.debian.org/archive/debian/20120304T220938Z/pool/main/l/linux-base/linux-base_3.5_all.deb'
          dpkg -i '/tmp/linux-base_3.5_all.deb'
        }
        wget --no-check-certificate -qO '/tmp/linux-image-3.16.0-4-amd64_3.16.43-2+deb8u5_amd64.deb' 'http://snapshot.debian.org/archive/debian/20171008T163152Z/pool/main/l/linux/linux-image-3.16.0-4-amd64_3.16.43-2+deb8u5_amd64.deb'
        dpkg -i '/tmp/linux-image-3.16.0-4-amd64_3.16.43-2+deb8u5_amd64.deb'

        if [ $? -ne 0 ]; then
          exit 1
        fi
      elif [ "$deb_ver" == "9" ]; then
        dpkg -l | grep -q 'linux-base' || {
          wget --no-check-certificate -qO '/tmp/linux-base_4.5_all.deb' 'http://snapshot.debian.org/archive/debian/20160917T042239Z/pool/main/l/linux-base/linux-base_4.5_all.deb'
          dpkg -i '/tmp/linux-base_4.5_all.deb'
        }
        wget --no-check-certificate -qO '/tmp/linux-image-4.9.0-4-amd64_4.9.65-3+deb9u1_amd64.deb' 'http://snapshot.debian.org/archive/debian/20171224T175424Z/pool/main/l/linux/linux-image-4.9.0-4-amd64_4.9.65-3+deb9u1_amd64.deb'
        dpkg -i '/tmp/linux-image-4.9.0-4-amd64_4.9.65-3+deb9u1_amd64.deb'
        ##备选
        #https://sys.if.ci/download/linux-image-4.9.0-4-amd64_4.9.65-3+deb9u1_amd64.deb
        #http://mirror.cs.uchicago.edu/debian-security/pool/updates/main/l/linux/linux-image-4.9.0-4-amd64_4.9.65-3+deb9u1_amd64.deb
        #https://debian.sipwise.com/debian-security/pool/main/l/linux/linux-image-4.9.0-4-amd64_4.9.65-3+deb9u1_amd64.deb
        #http://srv24.dsidata.sk/security.debian.org/pool/updates/main/l/linux/linux-image-4.9.0-4-amd64_4.9.65-3+deb9u1_amd64.deb
        #https://pubmirror.plutex.de/debian-security/pool/updates/main/l/linux/linux-image-4.9.0-4-amd64_4.9.65-3+deb9u1_amd64.deb
        #https://packages.mendix.com/debian/pool/main/l/linux/linux-image-4.9.0-4-amd64_4.9.65-3_amd64.deb
        #http://snapshot.debian.org/archive/debian/20171224T175424Z/pool/main/l/linux/linux-image-4.9.0-4-amd64_4.9.65-3+deb9u1_amd64.deb
        #http://snapshot.debian.org/archive/debian/20171231T180144Z/pool/main/l/linux/linux-image-4.9.0-4-amd64_4.9.65-3_amd64.deb
        if [ $? -ne 0 ]; then
          exit 1
        fi
      else
        exit 1
      fi
    fi
    apt-get autoremove -y
    [ -d '/var/lib/apt/lists' ] && find /var/lib/apt/lists -type f -delete
  fi

  BBR_grub
  echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
  check_kernel
}

#安装xanmod内核  from xanmod.org
installxanmod() {
  kernel_version="5.5.1-xanmod1"
  bit=$(uname -m)
  if [[ ${bit} != "x86_64" ]]; then
    echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
  fi
  rm -rf xanmod
  mkdir xanmod && cd xanmod || exit
  if [[ "${release}" == "centos" ]]; then
    if [[ ${version} == "7" ]]; then
      if [[ ${bit} == "x86_64" ]]; then
        echo -e "如果下载地址出错，可能当前正在更新，超过半天还是出错请反馈，大陆自行解决污染问题"
        github_tag=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep 'Centos_Kernel' | grep '_lts_latest_' | grep 'xanmod' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
        github_ver=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}')
        echo -e "获取的版本号为:${github_ver}"
        kernel_version=$github_ver
        detele_kernel_head
        headurl=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}')
        imgurl=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep -v 'headers' | grep -v 'devel' | awk -F '"' '{print $4}')

        headurl=$(check_cn $headurl)
        imgurl=$(check_cn $imgurl)
        echo -e "正在检查headers下载连接...."
        checkurl $headurl
        echo -e "正在检查内核下载连接...."
        checkurl $imgurl
        wget -N -O kernel-headers-c7.rpm $headurl
        wget -N -O kernel-c7.rpm $imgurl
        yum install -y kernel-c7.rpm
        yum install -y kernel-headers-c7.rpm
      else
        echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
      fi
    elif [[ ${version} == "8" ]]; then
      echo -e "如果下载地址出错，可能当前正在更新，超过半天还是出错请反馈，大陆自行解决污染问题"
      github_tag=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep 'Centos_Kernel' | grep '_lts_C8_latest_' | grep 'xanmod' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
      github_ver=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}')
      echo -e "获取的版本号为:${github_ver}"
      kernel_version=$github_ver
      detele_kernel_head
      headurl=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}')
      imgurl=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep -v 'headers' | grep -v 'devel' | awk -F '"' '{print $4}')

      headurl=$(check_cn $headurl)
      imgurl=$(check_cn $imgurl)
      echo -e "正在检查headers下载连接...."
      checkurl $headurl
      echo -e "正在检查内核下载连接...."
      checkurl $imgurl
      wget -N -O kernel-headers-c8.rpm $headurl
      wget -N -O kernel-c8.rpm $imgurl
      yum install -y kernel-c8.rpm
      yum install -y kernel-headers-c8.rpm
    fi

  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then

    if [[ ${bit} == "x86_64" ]]; then
      # kernel_version="5.11.4-xanmod"
      # xanmod_ver_b=$(rm -rf /tmp/url.tmp && curl -o /tmp/url.tmp 'https://dl.xanmod.org/dl/changelog/?C=N;O=D' && grep folder.gif /tmp/url.tmp | head -n 1 | awk -F "[/]" '{print $5}' | awk -F "[>]" '{print $2}')
      # xanmod_ver_s=$(rm -rf /tmp/url.tmp && curl -o /tmp/url.tmp 'https://dl.xanmod.org/changelog/${xanmod_ver_b}/?C=M;O=D' && grep $xanmod_ver_b /tmp/url.tmp | head -n 3 | awk -F "[-]" '{print $2}')
      sourceforge_xanmod_lts_ver=$(curl -s https://sourceforge.net/projects/xanmod/files/releases/lts/ | grep 'class="folder ">' | head -n 1 | awk -F '"' '{print $2}')
      sourceforge_xanmod_lts_file_img=$(curl -s https://sourceforge.net/projects/xanmod/files/releases/lts/${sourceforge_xanmod_lts_ver}/ | grep 'linux-image' | head -n 1 | awk -F '"' '{print $2}')
      sourceforge_xanmod_lts_file_head=$(curl -s https://sourceforge.net/projects/xanmod/files/releases/lts/${sourceforge_xanmod_lts_ver}/ | grep 'linux-headers' | head -n 1 | awk -F '"' '{print $2}')
      # sourceforge_xanmod_stable_ver=$(curl -s https://sourceforge.net/projects/xanmod/files/releases/stable/ | grep 'class="folder ">' | head -n 1 | awk -F '"' '{print $2}')
      # sourceforge_xanmod_stable_file_img=$(curl -s https://sourceforge.net/projects/xanmod/files/releases/stable/${sourceforge_xanmod_stable_ver}/ | grep 'linux-image' | head -n 1 | awk -F '"' '{print $2}')
      # sourceforge_xanmod_stable_file_head=$(curl -s https://sourceforge.net/projects/xanmod/files/releases/stable/${sourceforge_xanmod_stable_ver}/ | grep 'linux-headers' | head -n 1 | awk -F '"' '{print $2}')
      # sourceforge_xanmod_cacule_ver=$(curl -s https://sourceforge.net/projects/xanmod/files/releases/cacule/ | grep 'class="folder ">' | head -n 1 | awk -F '"' '{print $2}')
      # sourceforge_xanmod_cacule_file_img=$(curl -s https://sourceforge.net/projects/xanmod/files/releases/cacule/${sourceforge_xanmod_cacule_ver}/ | grep 'linux-image' | head -n 1 | awk -F '"' '{print $2}')
      # sourceforge_xanmod_cacule_file_head=$(curl -s https://sourceforge.net/projects/xanmod/files/releases/cacule/${sourceforge_xanmod_cacule_ver}/ | grep 'linux-headers' | head -n 1 | awk -F '"' '{print $2}')
      echo -e "获取的xanmod lts版本号为:${sourceforge_xanmod_lts_ver}"
      # kernel_version=$sourceforge_xanmod_stable_ver
      # detele_kernel_head
      # headurl=https://sourceforge.net/projects/xanmod/files/releases/stable/${sourceforge_xanmod_stable_ver}/${sourceforge_xanmod_stable_file_head}/download
      # imgurl=https://sourceforge.net/projects/xanmod/files/releases/stable/${sourceforge_xanmod_stable_ver}/${sourceforge_xanmod_stable_file_img}/download
      kernel_version=$sourceforge_xanmod_lts_ver
      detele_kernel_head
      #headurl=https://sourceforge.net/projects/xanmod/files/releases/cacule/${sourceforge_xanmod_cacule_ver}/${sourceforge_xanmod_cacule_file_head}/download
      #imgurl=https://sourceforge.net/projects/xanmod/files/releases/cacule/${sourceforge_xanmod_cacule_ver}/${sourceforge_xanmod_cacule_file_img}/download
      headurl=https://sourceforge.net/projects/xanmod/files/releases/lts/${sourceforge_xanmod_lts_ver}/${sourceforge_xanmod_lts_file_head}/download
      imgurl=https://sourceforge.net/projects/xanmod/files/releases/lts/${sourceforge_xanmod_lts_ver}/${sourceforge_xanmod_lts_file_img}/download

      echo -e "正在检查headers下载连接...."
      checkurl $headurl
      echo -e "正在检查内核下载连接...."
      checkurl $imgurl
      wget -N -O linux-headers-d10.deb $headurl
      wget -N -O linux-image-d10.deb $imgurl
      dpkg -i linux-image-d10.deb
      dpkg -i linux-headers-d10.deb
    else
      echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
    fi
  fi

  cd .. && rm -rf xanmod
  BBR_grub
  echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
  check_kernel
}

#安装bbr2内核 集成到xanmod内核了
#安装bbrplus 新内核
#2021.3.15 开始由https://github.com/UJX6N/bbrplus-5.16 替换bbrplusnew
#2021.4.12 地址更新为https://github.com/97668589/kernel/releases
#2021.9.2 再次改为https://github.com/UJX6N/bbrplus-6.6
#2022.2.26 改为https://github.com/UJX6N/bbrplus-6.6

installbbrplusnew() {
  github_ver_plus=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.6/releases | grep /bbrplus-6.6/releases/tag/ | head -1 | awk -F "[/]" '{print $8}' | awk -F "[\"]" '{print $1}')
  github_ver_plus_num=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.6/releases | grep /bbrplus-6.6/releases/tag/ | head -1 | awk -F "[/]" '{print $8}' | awk -F "[\"]" '{print $1}' | awk -F "[-]" '{print $1}')
  echo -e "获取的UJX6N的bbrplus-6.6版本号为:${github_ver_plus}"
  echo -e "如果下载地址出错，可能当前正在更新，超过半天还是出错请反馈，大陆自行解决污染问题"
  echo -e "安装失败这边反馈，内核问题给UJX6N反馈"
  # kernel_version=$github_ver_plus

  bit=$(uname -m)
  #if [[ ${bit} != "x86_64" ]]; then
  #  echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
  #fi
  rm -rf bbrplusnew
  mkdir bbrplusnew && cd bbrplusnew || exit
  if [[ "${release}" == "centos" ]]; then
    if [[ ${version} == "7" ]]; then
      if [[ ${bit} == "x86_64" ]]; then
        #github_tag=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep 'Centos_Kernel' | grep '_latest_bbrplus_' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
        #github_ver=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}' | awk -F '[_]' '{print $1}')
        #echo -e "获取的版本号为:${github_ver}"
        kernel_version=${github_ver_plus_num}_bbrplus
        detele_kernel_head
        headurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-6.6/releases' | grep ${github_ver_plus} | grep 'rpm' | grep 'headers' | grep 'el7' | awk -F '"' '{print $4}')
        imgurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-6.6/releases' | grep ${github_ver_plus} | grep 'rpm' | grep -v 'devel' | grep -v 'headers' | grep -v 'Source' | grep 'el7' | awk -F '"' '{print $4}')

        headurl=$(check_cn $headurl)
        imgurl=$(check_cn $imgurl)
        echo -e "正在检查headers下载连接...."
        checkurl $headurl
        echo -e "正在检查内核下载连接...."
        checkurl $imgurl
        wget -N -O kernel-c7.rpm $headurl
        wget -N -O kernel-headers-c7.rpm $imgurl
        yum install -y kernel-c7.rpm
        yum install -y kernel-headers-c7.rpm
      else
        echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
      fi
    fi
    if [[ ${version} == "8" ]]; then
      if [[ ${bit} == "x86_64" ]]; then
        #github_tag=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep 'Centos_Kernel' | grep '_latest_bbrplus_' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
        #github_ver=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}' | awk -F '[_]' '{print $1}')
        #echo -e "获取的版本号为:${github_ver}"
        kernel_version=${github_ver_plus_num}_bbrplus
        detele_kernel_head
        headurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-6.6/releases' | grep ${github_ver_plus} | grep 'rpm' | grep 'headers' | grep 'el8' | awk -F '"' '{print $4}')
        imgurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-6.6/releases' | grep ${github_ver_plus} | grep 'rpm' | grep -v 'devel' | grep -v 'headers' | grep -v 'Source' | grep 'el8' | awk -F '"' '{print $4}')

        headurl=$(check_cn $headurl)
        imgurl=$(check_cn $imgurl)
        echo -e "正在检查headers下载连接...."
        checkurl $headurl
        echo -e "正在检查内核下载连接...."
        checkurl $imgurl
        wget -N -O kernel-c8.rpm $headurl
        wget -N -O kernel-headers-c8.rpm $imgurl
        yum install -y kernel-c8.rpm
        yum install -y kernel-headers-c8.rpm
      else
        echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
      fi
    fi
  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    if [[ ${bit} == "x86_64" ]]; then
      #github_tag=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep 'Ubuntu_Kernel' | grep '_latest_bbrplus_' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
      #github_ver=$(curl -s 'http s://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'deb' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}' | awk -F '[_]' '{print $1}')
      #echo -e "获取的版本号为:${github_ver}"
      kernel_version=${github_ver_plus_num}-bbrplus
      detele_kernel_head
      headurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-6.6/releases' | grep ${github_ver_plus} | grep 'https' | grep 'amd64.deb' | grep 'headers' | awk -F '"' '{print $4}')
      imgurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-6.6/releases' | grep ${github_ver_plus} | grep 'https' | grep 'amd64.deb' | grep 'image' | awk -F '"' '{print $4}')

      headurl=$(check_cn $headurl)
      imgurl=$(check_cn $imgurl)
      echo -e "正在检查headers下载连接...."
      checkurl $headurl
      echo -e "正在检查内核下载连接...."
      checkurl $imgurl
      wget -N -O linux-headers-d10.deb $headurl
      wget -N -O linux-image-d10.deb $imgurl
      dpkg -i linux-image-d10.deb
      dpkg -i linux-headers-d10.deb
    elif [[ ${bit} == "aarch64" ]]; then
      #github_tag=$(curl -s 'https://api.github.com/repos/97668589/kernel/releases' | grep 'Ubuntu_Kernel' | grep '_latest_bbrplus_' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
      #github_ver=$(curl -s 'http s://api.github.com/repos/97668589/kernel/releases' | grep ${github_tag} | grep 'deb' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}' | awk -F '[_]' '{print $1}')
      #echo -e "获取的版本号为:${github_ver}"
      kernel_version=${github_ver_plus_num}-bbrplus
      detele_kernel_head
      headurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-6.6/releases' | grep ${github_ver_plus} | grep 'https' | grep 'arm64.deb' | grep 'headers' | awk -F '"' '{print $4}')
      imgurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-6.6/releases' | grep ${github_ver_plus} | grep 'https' | grep 'arm64.deb' | grep 'image' | awk -F '"' '{print $4}')

      headurl=$(check_cn $headurl)
      imgurl=$(check_cn $imgurl)
      echo -e "正在检查headers下载连接...."
      checkurl $headurl
      echo -e "正在检查内核下载连接...."
      checkurl $imgurl
      wget -N -O linux-headers-d10.deb $headurl
      wget -N -O linux-image-d10.deb $imgurl
      dpkg -i linux-image-d10.deb
      dpkg -i linux-headers-d10.deb
    else
      echo -e "${Error} 不支持x86_64及arm64/aarch64以外的系统 !" && exit 1
    fi
  fi

  cd .. && rm -rf bbrplusnew
  BBR_grub
  echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
  check_kernel

}

#启用BBR+fq
startbbrfq() {
  remove_bbr_lotserver
  echo "net.core.default_qdisc=fq" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}BBR+FQ修改成功，重启生效！"
}

#启用BBR+fq_pie
startbbrfqpie() {
  remove_bbr_lotserver
  echo "net.core.default_qdisc=fq_pie" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}BBR+FQ_PIE修改成功，重启生效！"
}

#启用BBR+cake
startbbrcake() {
  remove_bbr_lotserver
  echo "net.core.default_qdisc=cake" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}BBR+cake修改成功，重启生效！"
}

#启用BBRplus
startbbrplus() {
  remove_bbr_lotserver
  echo "net.core.default_qdisc=fq" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbrplus" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}BBRplus修改成功，重启生效！"
}

#启用Lotserver
startlotserver() {
  remove_bbr_lotserver
  if [[ "${release}" == "centos" ]]; then
    yum install ethtool -y
  else
    apt-get update || apt-get --allow-releaseinfo-change update
    apt-get install ethtool -y
  fi
  #bash <(wget -qO- https://git.io/lotServerInstall.sh) install
  #echo | bash <(wget --no-check-certificate -qO- https://raw.githubusercontent.com/1265578519/lotServer/main/lotServerInstall.sh) install
  echo | bash <(wget --no-check-certificate -qO- https://raw.githubusercontent.com/fei5seven/lotServer/master/lotServerInstall.sh) install
  sed -i '/advinacc/d' /appex/etc/config
  sed -i '/maxmode/d' /appex/etc/config
  echo -e "advinacc=\"1\"
maxmode=\"1\"" >>/appex/etc/config
  /appex/bin/lotServer.sh restart
  start_menu
}

#启用BBR2+FQ
startbbr2fq() {
  remove_bbr_lotserver
  echo "net.core.default_qdisc=fq" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr2" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}BBR2修改成功，重启生效！"
}

#启用BBR2+FQ_PIE
startbbr2fqpie() {
  remove_bbr_lotserver
  echo "net.core.default_qdisc=fq_pie" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr2" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}BBR2修改成功，重启生效！"
}

#启用BBR2+CAKE
startbbr2cake() {
  remove_bbr_lotserver
  echo "net.core.default_qdisc=cake" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr2" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}BBR2修改成功，重启生效！"
}

#开启ecn
startecn() {
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf

  echo "net.ipv4.tcp_ecn=1" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}开启ecn结束！"
}

#关闭ecn
closeecn() {
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf

  echo "net.ipv4.tcp_ecn=0" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}关闭ecn结束！"
}

#卸载bbr+锐速
remove_bbr_lotserver() {
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.default_qdisc/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf
  sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
  sysctl --system

  rm -rf bbrmod

  if [[ -e /appex/bin/lotServer.sh ]]; then
    echo | bash <(wget -qO- https://git.io/lotServerInstall.sh) uninstall
  fi
  clear
  # echo -e "${Info}:清除bbr/lotserver加速完成。"
  # sleep 1s
}

#卸载全部加速
remove_all() {
  rm -rf /etc/sysctl.d/*.conf
  #rm -rf /etc/sysctl.conf
  #touch /etc/sysctl.conf
  if [ ! -f "/etc/sysctl.conf" ]; then
    touch /etc/sysctl.conf
  else
    cat /dev/null >/etc/sysctl.conf
  fi
  sysctl --system
  sed -i '/DefaultTimeoutStartSec/d' /etc/systemd/system.conf
  sed -i '/DefaultTimeoutStopSec/d' /etc/systemd/system.conf
  sed -i '/DefaultRestartSec/d' /etc/systemd/system.conf
  sed -i '/DefaultLimitCORE/d' /etc/systemd/system.conf
  sed -i '/DefaultLimitNOFILE/d' /etc/systemd/system.conf
  sed -i '/DefaultLimitNPROC/d' /etc/systemd/system.conf

  sed -i '/soft nofile/d' /etc/security/limits.conf
  sed -i '/hard nofile/d' /etc/security/limits.conf
  sed -i '/soft nproc/d' /etc/security/limits.conf
  sed -i '/hard nproc/d' /etc/security/limits.conf

  sed -i '/ulimit -SHn/d' /etc/profile
  sed -i '/ulimit -SHn/d' /etc/profile
  sed -i '/required pam_limits.so/d' /etc/pam.d/common-session

  systemctl daemon-reload

  rm -rf bbrmod
  sed -i '/net.ipv4.tcp_retries2/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_slow_start_after_idle/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_fastopen/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf
  sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
  sed -i '/fs.file-max/d' /etc/sysctl.conf
  sed -i '/net.core.rmem_max/d' /etc/sysctl.conf
  sed -i '/net.core.wmem_max/d' /etc/sysctl.conf
  sed -i '/net.core.rmem_default/d' /etc/sysctl.conf
  sed -i '/net.core.wmem_default/d' /etc/sysctl.conf
  sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
  sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_tw_recycle/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_keepalive_time/d' /etc/sysctl.conf
  sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_rmem/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_wmem/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_mtu_probing/d' /etc/sysctl.conf
  sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
  sed -i '/fs.inotify.max_user_instances/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
  sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
  sed -i '/net.ipv4.route.gc_timeout/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_synack_retries/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_syn_retries/d' /etc/sysctl.conf
  sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
  sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_timestamps/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_orphans/d' /etc/sysctl.conf
  if [[ -e /appex/bin/lotServer.sh ]]; then
    bash <(wget -qO- https://git.io/lotServerInstall.sh) uninstall
  fi
  clear
  echo -e "${Info}:清除加速完成。"
  sleep 1s
}

#优化系统配置
#!/bin/bash
# VPS sysctl 优化 (V2Ray/VLESS+TCP+Reality 专用)
# 兼容 Debian/Ubuntu/CentOS
# BBR + FQ + TCP Fast Open + 高 file limit

optimizing_system_v2ray() {
  echo -e "[INFO] 开始应用 VPS 系统优化配置..."

# ----------------备份原始配置----------------
cp /etc/sysctl.conf /etc/sysctl.conf.bak.$(date +%s)
cp /etc/security/limits.conf /etc/security/limits.conf.bak.$(date +%s)

# ----------------应用 sysctl 优化----------------
cat >/etc/sysctl.conf <<EOF
# 基础网络优化
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 32768
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.ip_local_port_range = 1024 65535

# TCP 保活
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5

# 防止 SYN Flood
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864

# 文件句柄限制
fs.file-max = 65535
vm.overcommit_memory = 1
EOF

# 应用修改
sysctl -p

# ----------------应用 limits.conf----------------
cat >/etc/security/limits.conf <<EOF
* soft nofile 65535
* hard nofile 65535
EOF

# 配置 ulimit
if ! grep -q "ulimit -SHn" /etc/profile; then
  echo "ulimit -SHn 65535" >>/etc/profile
fi

# ----------------透明大页优化----------------
echo madvise >/sys/kernel/mm/transparent_hugepage/enabled

# ----------------完成提示----------------
echo -e "\n${Info} VPS 网络优化已应用完成！"
echo -e "建议重启 VPS 以完全生效\n"
}

#更新脚本
Update_Shell() {
  clear
  echo -e "当前脚本版本: ${sh_ver}，开始检测远程最新版本..."

  local SCRIPT_RAW_URL="https://github.com/97668589/BBR-NetSpeed/raw/master/tcpx.sh"

  # 获取最新版本号
  sh_new_ver=$(wget -qO- --no-check-certificate "${SCRIPT_RAW_URL}" \
    | grep 'sh_ver="' | awk -F '"' '{print $2}' | head -1)

  # 检查是否成功获取版本号
  if [[ -z "${sh_new_ver}" ]]; then
    echo -e "${Error} 无法检测最新版本，可能网络或链接异常！"
    sleep 2
    start_menu
    return
  fi

  # 判断是否最新版
  if [[ "${sh_new_ver}" == "${sh_ver}" ]]; then
    echo -e "${Info} 当前已是最新版本: ${sh_ver}"
    sleep 2
    bash tcpx.sh
    exit 0
  fi

  echo -e "${Info} 发现新版本: ${sh_new_ver}，是否更新？ [Y/n]"
  read -p "(默认: y): " yn
  [[ -z "${yn}" ]] && yn="y"

  if [[ "${yn}" =~ ^[Yy]$ ]]; then
    echo -e "${Info} 正在下载最新版本脚本..."

    # 优先用 wget，其次 curl
    if command -v wget >/dev/null 2>&1; then
      wget --no-check-certificate -O tcpx.sh "${SCRIPT_RAW_URL}"
    else
      curl -L --insecure -o tcpx.sh "${SCRIPT_RAW_URL}"
    fi

    # 检查文件是否成功下载
    if [[ ! -s "tcpx.sh" ]]; then
      echo -e "${Error} 新版本脚本下载失败，请稍后重试！"
      sleep 2
      start_menu
      return
    fi

    chmod +x tcpx.sh
    echo -e "${Info} 更新完成，启动最新脚本..."

    bash tcpx.sh
    exit 0
  else
    echo -e "${Info} 已取消更新。"
    sleep 1
    start_menu
  fi
}

#切换到卸载内核版本
gototcp() {
  clear
  wget -O tcp.sh "https://github.com/97668589/BBR-NetSpeed/raw/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
}

#切换到秋水逸冰BBR安装脚本
gototeddysun_bbr() {
  clear
  wget https://github.com/teddysun/across/raw/master/bbr.sh && chmod +x bbr.sh && ./bbr.sh
}

#切换到一键DD安装系统脚本 新手勿入
gotodd() {
  clear
  echo "提示：正在使用 git.beta.gs 提供的 DD 脚本，请确保了解相关风险。"
  sleep 1.5

  local SCRIPT_URL="https://github.com/fcurrk/reinstall/raw/master/NewReinstall.sh"
  local SCRIPT_FILE="NewReinstall.sh"

  # 检查系统是否可执行 wget 或 curl
  if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
    echo -e "${Error} 未检测到 wget 或 curl，请先安装其中一个！"
    return 1
  fi

  rm -f "$SCRIPT_FILE"

  # 使用 wget/curl 自动切换
  if command -v wget >/dev/null 2>&1; then
    wget --no-check-certificate -O "$SCRIPT_FILE" "$SCRIPT_URL"
  else
    curl -L --insecure -o "$SCRIPT_FILE" "$SCRIPT_URL"
  fi

  # 检查下载是否成功
  if [[ ! -s "$SCRIPT_FILE" ]]; then
    echo -e "${Error} DD 脚本下载失败，请检查网络或脚本链接是否有效！"
    return 1
  fi

  chmod +x "$SCRIPT_FILE"
  echo -e "${Info} DD 脚本下载成功，正在执行..."
  sleep 1

  bash "$SCRIPT_FILE"
}

#禁用IPv6
closeipv6() {
  clear

  local FILE="/etc/sysctl.d/99-sysctl.conf"

  # 文件不存在就创建
  [[ ! -f "$FILE" ]] && touch "$FILE"

  # 删除旧 IPv6 配置，避免堆叠
  sed -i -E '/net\.ipv6\.conf\.(all|default|lo)\.disable_ipv6/d' "$FILE"
  sed -i -E '/net\.ipv6\.conf\.(all|default|lo)\.disable_ipv6/d' /etc/sysctl.conf 2>/dev/null

  # 写入禁用 IPv6 配置
  cat >>"$FILE" <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

  # 应用 sysctl 配置
  if sysctl --system >/dev/null 2>&1; then
    echo -e "${Info} IPv6 已禁用，设置已应用！"
  else
    echo -e "${Error} IPv6 禁用失败，请手动检查 sysctl 配置！"
  fi

  # 打印当前状态
  echo
  echo -e "${Info} 当前 IPv6 状态："
  sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null
  sysctl net.ipv6.conf.default.disable_ipv6 2>/dev/null
  sysctl net.ipv6.conf.lo.disable_ipv6 2>/dev/null

  echo -e "\n${Warning} 某些系统需要重启后 IPv6 才能完全关闭！"
}

#开启IPv6
openipv6() {
  clear

  local FILE="/etc/sysctl.d/99-sysctl.conf"

  # 如果文件不存在，创建
  [[ ! -f "$FILE" ]] && touch "$FILE"

  # 删除旧的 IPv6 配置（避免重复堆叠）
  sed -i -E '/net\.ipv6\.conf\.(all|default|lo)\.disable_ipv6/d' "$FILE"
  sed -i -E '/net\.ipv6\.conf\.(all|default|lo)\.disable_ipv6/d' /etc/sysctl.conf 2>/dev/null

  # 添加 IPv6 开启配置（仅一次）
  cat >>"$FILE" <<EOF
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0
EOF

  # 应用配置
  if sysctl --system >/dev/null 2>&1; then
    echo -e "${Info} IPv6 已开启，设置已应用！"
  else
    echo -e "${Error} IPv6 开启失败，sysctl 未成功加载，请手动检查配置！"
  fi

  # 显示当前状态
  echo
  echo -e "${Info} 当前 IPv6 状态："
  sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null
  sysctl net.ipv6.conf.default.disable_ipv6 2>/dev/null
  sysctl net.ipv6.conf.lo.disable_ipv6 2>/dev/null

  echo -e "\n${Warning} 部分系统需要重启后 IPv6 才能完全生效！"
}

#开始菜单
start_menu() {
  # 若未定义颜色变量，提供最小回退
  : "${Green_font_prefix:=$(tput setaf 2 2>/dev/null || echo '')}"
  : "${Red_font_prefix:=$(tput setaf 1 2>/dev/null || echo '')}"
  : "${Font_color_suffix:=$(tput sgr0 2>/dev/null || echo '')}"
  : "${Tip:='[TIP]'}"
  : "${Info:='[INFO]'}"
  : "${Error:='[ERROR]'}"
  : "${Warning:='[WARN]'}"

  while true; do
    clear
    echo
    echo -e " ${Green_font_prefix}--------------------------------------------${Font_color_suffix}"
    echo -e " TCP加速 ${Green_font_prefix}(BBR-BBRPLUS-Lotserver)${Font_color_suffix} 一键安装管理脚本"
    echo -e " ${Red_font_prefix}[v${sh_ver:-unknown}] ${Font_color_suffix} 不卸内核 ${Green_font_prefix}注意：${Font_color_suffix} 母鸡慎用"
    echo -e " ${Green_font_prefix}--------------------------------------------${Font_color_suffix}"
    cat <<'MENU'
 官方内核
 25. 安装 官方稳定内核             11. 使用 BBR+FQ 加速
 26. 安装 Zen 官方内核              12. 使用 BBR+FQ_PIE 加速
 27. 安装 官方最新内核 backports    13. 使用 BBR+CAKE 加速
 28. 安装 XANMOD 官方内核           14. 使用 BBR2+FQ 加速
 29. 安装 XANMOD Cacule 内核        15. 使用 BBR2+FQ_PIE 加速

 安装: BBR / BBRplus / Lotserver
  1. 安装 BBR原版内核               16. 使用 BBR2+CAKE 加速
  2. 安装 BBRplus版内核             17. 使用 BBRplus+FQ 加速
  3. 安装 BBRplus新版内核           18. 使用 Lotserver(锐速) 加速
  4. 安装 Lotserver(锐速)内核       19. 关闭 ECN
  5. 查看排序内核                   20. 开启 ECN
  6. 删除保留指定内核               21. 禁用 IPv6
  7. 切换到一键DD系统脚本           22. 开启 IPv6
  8. 切换到卸载内核版本             23. 系统配置优化
  9. 卸载全部加速                   24. 应用 johnrosen1 的优化方案
                                    30. 系统优化 (V2Ray/VLESS+TCP+Reality 专用)
 10. 退出脚本
  0. 升级脚本
MENU

    # 刷新状态信息
    check_status >/dev/null 2>&1 || true
    get_system_info >/dev/null 2>&1 || true

    # 安全地显示系统信息（变量可能为空）
    echo
    echo -e " 系统信息: ${Font_color_suffix}${opsy:-未知系统} ${Green_font_prefix}${virtual:-未知虚拟化}${Font_color_suffix} ${arch:-未知架构} ${Green_font_prefix}${kern:-未知内核}${Font_color_suffix}"
    if [[ ${kernel_status:-noinstall} == "noinstall" ]]; then
      echo -e " 当前状态: ${Green_font_prefix}未安装${Font_color_suffix} 加速内核 ${Red_font_prefix}请先安装内核${Font_color_suffix}"
    else
      echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} ${Red_font_prefix}${kernel_status}${Font_color_suffix} 加速内核 , ${Green_font_prefix}${run_status:-未知状态}${Font_color_suffix}"
    fi
    echo -e " 当前拥塞控制: ${Green_font_prefix}${net_congestion_control:-unknown}${Font_color_suffix}  当前队列算法: ${Green_font_prefix}${net_qdisc:-unknown}${Font_color_suffix}"
    echo

    # 读取输入并校验
    read -rp " 请输入数字 (按 q 或 10 退出) : " num
    # 允许 q 或 quit
    case "${num,,}" in
      q|quit|10)
        echo -e "${Info} 退出脚本."
        return 0
        ;;
    esac

    # 如果输入为空，重新循环
    if [[ -z "$num" ]]; then
      echo -e "${Warning} 未输入任何选项，重新显示菜单..."
      sleep 1
      continue
    fi

    # 只允许 0-99 数字
    if ! [[ "$num" =~ ^[0-9]+$ ]] || (( num < 0 || num > 99 )); then
      echo -e "${Error} 请输入正确数字 [0-99]"
      sleep 1.5
      continue
    fi

    case "$num" in
      0)  Update_Shell ;;
      1)  check_sys_bbr ;;
      2)  check_sys_bbrplus ;;
      3)  check_sys_bbrplusnew ;;
      4)  check_sys_Lotsever ;;
      5)  BBR_grub ;;
      6)  detele_kernel_custom ;;
      7)  gotodd ;;
      8)  gototcp ;;
      9)  remove_all ;;
      11) startbbrfq ;;
      12) startbbrfqpie ;;
      13) startbbrcake ;;
      14) startbbr2fq ;;
      15) startbbr2fqpie ;;
      16) startbbr2cake ;;
      17) startbbrplus ;;
      18) startlotserver ;;
      19) closeecn ;;
      20) startecn ;;
      21) closeipv6 ;;
      22) openipv6 ;;
      23) optimizing_system ;;
      24) optimizing_system_johnrosen1 ;;
      25) check_sys_official ;;
      26) check_sys_official_zen ;;
      27) check_sys_official_bbr ;;
      28) check_sys_official_xanmod ;;
      29) check_sys_official_xanmod_cacule ;;
      30) optimizing_system_v2ray ;;
      99)
        # 预留管理员快捷键（如需）
        echo -e "${Info} 99 未定义具体动作"
        ;;
      *)
        echo -e "${Error} 未识别的选项: $num"
        sleep 1.2
        ;;
    esac

    # 操作完成后短暂暂停再显示菜单，便于查看输出
    echo
    read -rp "按回车返回菜单..." _dummy
  done
}

#############内核管理组件#############

#删除多余内核
# 检查运行中的内核，确保不会被删除
get_running_kernel() {
    running_kernel=$(uname -r | sed 's/-generic//;s/-amd64//')
}

# ----------------------------
# 删除 CentOS 内核
# ----------------------------
delete_kernel_centos() {
    echo -e "${Info} 当前运行内核：${running_kernel}"

    mapfile -t old_kernels < <(rpm -qa | grep '^kernel-[0-9]' | grep -v "${keep_kernel}" | grep -v "${running_kernel}")

    if [[ ${#old_kernels[@]} -lt 1 ]]; then
        echo -e "${Info} 没有可删除的旧内核。"
        return
    fi

    echo -e "${Info} 共检测到 ${#old_kernels[@]} 个旧内核，开始删除..."

    for pkg in "${old_kernels[@]}"; do
        echo -e "${Info} 删除 ${pkg}"
        rpm -e --nodeps "$pkg"
    done
}

# ----------------------------
# 删除 Debian/Ubuntu 内核
# ----------------------------
delete_kernel_debian() {
    echo -e "${Info} 当前运行内核：${running_kernel}"

    mapfile -t old_images < <(
        dpkg -l | awk '/linux-image-[0-9]/{print $2}' |
        grep -v "${keep_kernel}" |
        grep -v "${running_kernel}"
    )

    mapfile -t old_headers < <(
        dpkg -l | awk '/linux-headers-[0-9]/{print $2}' |
        grep -v "${keep_kernel}" |
        grep -v "${running_kernel}"
    )

    # 删除镜像包
    if [[ ${#old_images[@]} -gt 0 ]]; then
        echo -e "${Info} 删除旧内核镜像..."
        apt purge -y "${old_images[@]}"
    fi

    # 删除 headers 包
    if [[ ${#old_headers[@]} -gt 0 ]]; then
        echo -e "${Info} 删除旧内核 headers..."
        apt purge -y "${old_headers[@]}"
    fi
}

# ----------------------------
# 自动选择系统删除
# ----------------------------
detele_kernel() {
    get_running_kernel

    case "${release}" in
        centos)
            delete_kernel_centos
        ;;
        debian|ubuntu)
            delete_kernel_debian
        ;;
        *)
            echo -e "${Error} 不支持的系统。"
            exit 1
        ;;
    esac

    echo -e "${Info} 旧内核删除完毕。"
}

# ----------------------------
# 用户输入版本号删除
# ----------------------------
detele_kernel_custom() {
    BBR_grub
    echo
    read -p "请输入你要保留的内核版本（例如 5.4.0-109）：" keep_kernel

    if [[ -z "$keep_kernel" ]]; then
        echo -e "${Error} 输入为空，已取消。"
        exit 1
    fi

    detele_kernel
    BBR_grub
}

#更新引导
BBR_grub() {
  echo -e "${Info} 正在更新引导配置..."

  # ---------------------------
  # 判断系统类型
  # ---------------------------
  case "${release}" in
    centos)
      # 检测版本号：6/7/8
      case "${version}" in
        6)
          # CentOS 6 使用 grub legacy
          if [[ -f /boot/grub/grub.conf ]]; then
            sed -i 's/^default=.*/default=0/' /boot/grub/grub.conf
          elif [[ -f /boot/grub/grub.cfg ]]; then
            grub-mkconfig -o /boot/grub/grub.cfg
            grub-set-default 0
          else
            echo -e "${Error} 未找到 grub.conf / grub.cfg"
            exit 1
          fi
        ;;
        
        7|8)
          # CentOS 7/8 使用 grub2
          grub_cfg=""
          for path in \
            /boot/grub2/grub.cfg \
            /boot/efi/EFI/centos/grub.cfg \
            /boot/efi/EFI/redhat/grub.cfg
          do
            [[ -f "$path" ]] && grub_cfg="$path" && break
          done

          if [[ -z "$grub_cfg" ]]; then
            echo -e "${Error} 未找到 grub.cfg，请手动检查。"
            exit 1
          fi

          grub2-mkconfig -o "$grub_cfg"
          grub2-set-default 0

          # CentOS 8 会显示内核列表
          if [[ "${version}" == "8" ]]; then
            grubby --info=ALL | awk -F= '$1=="kernel" {print i++ " : " $2}'
          fi
        ;;
      esac
    ;;

    debian|ubuntu)
      # ---------------------------
      # Debian/Ubuntu 引导更新
      # ---------------------------
      if command -v update-grub >/dev/null 2>&1; then
        update-grub
      elif [[ -x /usr/sbin/update-grub ]]; then
        /usr/sbin/update-grub
      else
        apt update
        apt install grub2-common -y
        update-grub
      fi
    ;;

    *)
      echo -e "${Error} 未知系统类型，无法更新 GRUB。"
      exit 1
    ;;
  esac

  echo -e "${Info} 引导更新完成。"
}

#简单的检查内核
check_kernel() {
  echo -e "${Tip} 开始检查系统内核...（扫描 /boot 下的 vmlinuz-* 文件）"

  # 查找有效内核（排除 rescue）
  kernels=($(ls /boot/vmlinuz-* 2>/dev/null | grep -v "rescue"))

  if [[ ${#kernels[@]} -eq 0 ]]; then
    echo -e "${Error} 未找到任何有效内核文件（/boot/vmlinuz-*）。"
    echo -e "${Error} 系统可能没有可引导内核，重启会造成无法启动！"
    echo -e "${Error} 建议执行：按 9 → 选择默认内核安装 → 30 修复引导。"
    exit 1
  fi

  echo -e "${Info} 找到以下内核："
  for k in "${kernels[@]}"; do
    echo " - $k"
    # 检查对应的 initramfs 是否存在
    initrd="/boot/initrd.img-$(basename "$k" | sed 's/vmlinuz-//')"
    if [[ -f "$initrd" ]]; then
      echo "   → initramfs 正常: $initrd"
    else
      echo -e "   ${Warning} → 缺少 initramfs: $initrd（系统可能无法正常引导）"
    fi
  done

  echo -e "${Info} 内核检查完成。"
}

#############内核管理组件#############

#############系统检测组件#############

#检查系统
check_sys() {

  # --- 系统识别 ---
  if [[ -f /etc/redhat-release ]]; then
      release="centos"
  elif grep -qi "debian" /etc/os-release 2>/dev/null; then
      release="debian"
  elif grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
      release="ubuntu"
  else
      release="unknown"
  fi

  # --- 指令判断函数 ---
  _exists() {
      command -v "$1" >/dev/null 2>&1
      return $?
  }

  # --- 获取系统信息 ---
  get_opsy() {
      if [[ -f /etc/redhat-release ]]; then
          awk '{print $1,$3~/^[0-9]/?$3:$4}' /etc/redhat-release
      elif [[ -f /etc/os-release ]]; then
          awk -F'[="]+' '/PRETTY_NAME/{print $2}' /etc/os-release
      elif [[ -f /etc/lsb-release ]]; then
          awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release
      fi
  }

  get_system_info() {
      opsy=$(get_opsy)
      arch=$(uname -m)
      kern=$(uname -r)
      virt_check
  }

  # --- 虚拟化检测模块 ---
  virt_check() {
      check_virtualization
  }

}

# -----------------------------------------
# 虚拟化检测：优化精简版
# -----------------------------------------

check_virtualization() {

  virtual="Unknown"
  Var_VirtType="unknown"

  # 优先使用 systemd-detect-virt
  if [ -x "/usr/bin/systemd-detect-virt" ]; then
      Var_VirtType=$(/usr/bin/systemd-detect-virt)
  fi

  # Docker / WSL 特征文件
  if [ -f "/.dockerenv" ]; then
      Var_VirtType="docker"
  elif [ -c "/dev/lxss" ]; then
      Var_VirtType="wsl"
  fi

  # 分类
  case "${Var_VirtType}" in
      qemu) virtual="QEMU" ;;
      kvm) virtual="KVM" ;;
      zvm) virtual="S390 Z/VM" ;;
      vmware) virtual="VMware" ;;
      microsoft) virtual="Microsoft Hyper-V" ;;
      xen) virtual="Xen Hypervisor" ;;
      bochs) virtual="BOCHS" ;;
      uml) virtual="User-mode Linux" ;;
      parallels) virtual="Parallels" ;;
      bhyve) virtual="FreeBSD Hypervisor" ;;
      openvz) virtual="OpenVZ" ;;
      lxc) virtual="LXC" ;;
      lxc-libvirt) virtual="LXC (libvirt)" ;;
      systemd-nspawn) virtual="Systemd nspawn" ;;
      docker) virtual="Docker" ;;
      rkt) virtual="RKT" ;;
      wsl) virtual="Windows Subsystem for Linux (WSL)" ;;

      none|"")
          # 检测 BIOS 判断是否为物理机
          if command -v dmidecode >/dev/null 2>&1; then
              bios_vendor=$(dmidecode -s bios-vendor 2>/dev/null)
              if [ "$bios_vendor" = "SeaBIOS" ]; then
                  Var_VirtType="Unknown"
                  virtual="Unknown with SeaBIOS BIOS"
              else
                  Var_VirtType="dedicated"
                  virtual="Dedicated with ${bios_vendor} BIOS"
              fi
          else
              Var_VirtType="dedicated"
              virtual="Dedicated"
          fi
          ;;

      *)
          virtual="${Var_VirtType}" ;;
  esac

  echo "虚拟化类型: ${Var_VirtType}, 描述: ${virtual}"
}

  #检查依赖
  check_dependencies() {
  echo -e "${Tip} 检查系统依赖和CA证书..."

  # 先统一更新源（防止重复）
  if [[ "${release}" == "centos" ]]; then
    yum makecache fast -y
  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    apt-get update -y || apt-get --allow-releaseinfo-change update -y
  fi

  # CA证书检查
  if [[ "${release}" == "centos" ]]; then
    if rpm -q ca-certificates | grep -q '202'; then
      echo 'CA证书检查OK'
    else
      echo 'CA证书检查不通过，正在安装/更新...'
      yum install ca-certificates -y
      update-ca-trust force-enable
    fi
  else
    if dpkg -s ca-certificates >/dev/null 2>&1 && dpkg -l ca-certificates | grep -q '202'; then
      echo 'CA证书检查OK'
    else
      echo 'CA证书检查不通过，正在安装/更新...'
      apt-get install -y ca-certificates
      update-ca-certificates
    fi
  fi

  # 通用依赖列表
  deps=(curl wget dmidecode)
  for dep in "${deps[@]}"; do
    if ! type "$dep" >/dev/null 2>&1; then
      echo "$dep 未安装，正在安装..."
      if [[ "${release}" == "centos" ]]; then
        yum install -y "$dep"
      else
        apt-get install -y "$dep"
      fi
    else
      echo "$dep 已安装，继续"
    fi
  done

  echo -e "${Tip} 系统依赖检查完成"
}

#检查Linux版本
check_version() {
  # 获取系统类型
  if [[ -s /etc/redhat-release ]]; then
    release="centos"
    version=$(grep -oE "[0-9.]+" /etc/redhat-release | cut -d . -f 1)
  elif [[ -s /etc/debian_version ]]; then
    release="debian"
    version=$(cut -d. -f1 /etc/debian_version)
  elif grep -qi "ubuntu" /etc/issue 2>/dev/null || grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
    release="ubuntu"
    if [[ -s /etc/lsb-release ]]; then
      version=$(grep -oE "[0-9]+" /etc/lsb-release | head -1)
    else
      version=$(grep -oE "[0-9.]+" /etc/issue | cut -d . -f 1)
    fi
  else
    release="unknown"
    version="0"
  fi

  # 获取架构
  bit=$(uname -m)
  case "${bit}" in
    x86_64) bit="x86_64" ;;
    i386|i686) bit="i386" ;;
    aarch64) bit="aarch64" ;;
    *) bit="unknown" ;;
  esac

  echo -e "检测到系统: ${release} ${version}, 架构: ${bit}"
}

#检查安装bbr的系统要求
check_sys_kernel() {
  local kernel_type="$1"  # 例如: bbr, bbrplus, bbrplusnew, xanmod
  check_version
  bit=$(uname -m)

  # 架构限制
  if [[ ${bit} != "x86_64" && ${bit} != "aarch64" && ${bit} != "i386" ]]; then
    echo -e "${Error} 当前架构 ${bit} 不支持 ${kernel_type} 内核 !" && exit 1
  fi

  case "${release}" in
    centos)
      if [[ ${kernel_type} == "bbr" || ${kernel_type} == "bbrplus" ]]; then
        [[ ${version} != "7" ]] && echo -e "${Error} ${kernel_type} 内核仅支持 CentOS 7 !" && exit 1
      elif [[ ${kernel_type} == "bbrplusnew" || ${kernel_type} == "xanmod" ]]; then
        [[ ${version} != "7" && ${version} != "8" ]] && echo -e "${Error} ${kernel_type} 内核仅支持 CentOS 7/8 !" && exit 1
      fi
      ;;
    debian|ubuntu)
      apt-get update
      apt-get --fix-broken install -y
      apt-get autoremove -y
      ;;
    *)
      echo -e "${Error} 当前系统 ${release} 不支持 ${kernel_type} 内核 !" && exit 1
      ;;
  esac

  # 调用对应安装函数
  case "${kernel_type}" in
    bbr) installbbr ;;
    bbrplus) installbbrplus ;;
    bbrplusnew) installbbrplusnew ;;
    xanmod) installxanmod ;;
    *) echo -e "${Error} 未知内核类型 ${kernel_type} !" && exit 1 ;;
  esac

  echo -e "${Tip} ${kernel_type} 内核安装完成，请检查内核版本和加速模块状态。"
}

#检查安装Lotsever的系统要求
check_sys_Lotsever() {
  check_version
  bit=$(uname -m)

  if [[ ${bit} != "x86_64" && ${bit} != "i386" ]]; then
    echo -e "${Error} Lotserver 仅支持 x86_64/i386 系统 !" && exit 1
  fi

  case "${release}" in
    centos)
      if [[ ${bit} != "x86_64" ]]; then
        echo -e "${Error} CentOS 仅支持 x86_64 !" && exit 1
      fi
      yum -y install net-tools || { echo -e "${Error} 安装 net-tools 失败 !" && exit 1; }
      case "${version}" in
        6)
          kernel_version="2.6.32-504"
          ;;
        7)
          kernel_version="4.11.2-1"
          ;;
        *)
          echo -e "${Error} Lotserver 不支持当前 CentOS 版本 ${version} !" && exit 1
          ;;
      esac
      ;;
    debian)
      apt-get update
      if [[ ${version} == "7" || ${version} == "8" ]]; then
        if [[ ${bit} == "x86_64" ]]; then
          kernel_version="3.16.0-4"
        elif [[ ${bit} == "i386" ]]; then
          kernel_version="3.2.0-4"
        fi
      elif [[ ${version} == "9" && ${bit} == "x86_64" ]]; then
        kernel_version="4.9.0-4"
      else
        echo -e "${Error} Lotserver 不支持当前 Debian 版本 ${version} 或架构 ${bit} !" && exit 1
      fi
      ;;
    ubuntu)
      apt-get update
      if [[ ${version} -ge 12 ]]; then
        if [[ ${bit} == "x86_64" ]]; then
          kernel_version="4.4.0-47"
        elif [[ ${bit} == "i386" ]]; then
          kernel_version="3.13.0-29"
        fi
      else
        echo -e "${Error} Lotserver 不支持 Ubuntu 版本 ${version} !" && exit 1
      fi
      ;;
    *)
      echo -e "${Error} Lotserver 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
      ;;
  esac

  # 调用安装函数并检测错误
  if ! installlot; then
    echo -e "${Error} Lotserver 安装失败 !" && exit 1
  fi

  echo -e "${Tip} Lotserver 内核 ${kernel_version} 安装完成，请检查状态。"
}

#检查官方稳定内核并安装
check_sys_official() {
  check_version
  bit=$(uname -m)

  if [[ "${release}" == "centos" ]]; then
    if [[ ${bit} != "x86_64" ]]; then
      echo -e "${Error} 不支持 x86_64 以外的系统 !" && exit 1
    fi

    if [[ ${version} == "7" ]]; then
      yum install -y kernel kernel-headers --skip-broken || {
        echo -e "${Error} CentOS 7 内核安装失败 !" && exit 1
      }
    elif [[ ${version} == "8" ]]; then
      yum install -y kernel kernel-core kernel-headers --skip-broken || {
        echo -e "${Error} CentOS 8 内核安装失败 !" && exit 1
      }
    else
      echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
    fi

  elif [[ "${release}" == "debian" ]]; then
    apt-get update
    if [[ ${bit} == "x86_64" ]]; then
      apt-get install -y linux-image-amd64 linux-headers-amd64 || {
        echo -e "${Error} Debian x86_64 内核安装失败 !" && exit 1
      }
    elif [[ ${bit} == "aarch64" ]]; then
      apt-get install -y linux-image-arm64 linux-headers-arm64 || {
        echo -e "${Error} Debian aarch64 内核安装失败 !" && exit 1
      }
    fi

  elif [[ "${release}" == "ubuntu" ]]; then
    apt-get update
    apt-get install -y linux-image-generic linux-headers-generic || {
      echo -e "${Error} Ubuntu 内核安装失败 !" && exit 1
    }

  else
    echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
  fi

  BBR_grub
  echo -e "${Tip} 官方内核安装完毕，请参考上面的信息检查是否安装成功，默认从排第一的高版本内核启动"
}

#检查官方最新内核并安装
check_sys_official_bbr() {
  check_version
  bit=$(uname -m)

  if [[ "${release}" == "centos" ]]; then
    if [[ ${bit} != "x86_64" ]]; then
      echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
    fi
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    if [[ ${version} == "7" ]]; then
      yum install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm -y
      yum --enablerepo=elrepo-kernel install kernel-ml kernel-ml-headers -y --skip-broken
    elif [[ ${version} == "8" ]]; then
      yum install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm -y
      yum --enablerepo=elrepo-kernel install kernel-ml kernel-ml-headers -y --skip-broken
    else
      echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
    fi

  elif [[ "${release}" == "debian" ]]; then
    if [[ ${version} == "9" ]]; then
      echo "deb http://deb.debian.org/debian stretch-backports main" >/etc/apt/sources.list.d/stretch-backports.list
      apt update
      [[ ${bit} == "x86_64" ]] && apt -t stretch-backports install linux-image-amd64 linux-headers-amd64 -y
      [[ ${bit} == "aarch64" ]] && apt -t stretch-backports install linux-image-arm64 linux-headers-arm64 -y

    elif [[ ${version} == "10" ]]; then
      echo "deb http://deb.debian.org/debian buster-backports main" >/etc/apt/sources.list.d/buster-backports.list
      apt update
      [[ ${bit} == "x86_64" ]] && apt -t buster-backports install linux-image-amd64 linux-headers-amd64 -y
      [[ ${bit} == "aarch64" ]] && apt -t buster-backports install linux-image-arm64 linux-headers-arm64 -y

    elif [[ ${version} == "11" ]]; then
      echo "deb http://deb.debian.org/debian bullseye-backports main" >/etc/apt/sources.list.d/bullseye-backports.list
      apt update
      [[ ${bit} == "x86_64" ]] && apt -t bullseye-backports install linux-image-amd64 linux-headers-amd64 -y
      [[ ${bit} == "aarch64" ]] && echo -e "${Error} 暂时不支持aarch64的系统 !" && exit 1

    elif [[ ${version} == "12" ]]; then
      echo "deb http://deb.debian.org/debian bookworm-backports main" >/etc/apt/sources.list.d/bookworm-backports.list
      apt update
      [[ ${bit} == "x86_64" ]] && apt -t bookworm-backports install linux-image-amd64 linux-headers-amd64 -y
      [[ ${bit} == "aarch64" ]] && apt -t bookworm-backports install linux-image-arm64 linux-headers-arm64 -y

    else
      echo -e "${Error} 不支持当前 Debian 版本：${version}" && exit 1
    fi

  elif [[ "${release}" == "ubuntu" ]]; then
    echo -e "${Info} 检测到 Ubuntu，使用 HWE 内核升级..."

    apt update
    case ${version} in
      "14"|"14.04") apt install --install-recommends linux-generic-lts-xenial -y ;;
      "16"|"16.04") apt install --install-recommends linux-generic-hwe-16.04 -y ;;
      "18"|"18.04") apt install --install-recommends linux-generic-hwe-18.04 -y ;;
      "20"|"20.04") apt install --install-recommends linux-generic-hwe-20.04 -y ;;
      "22"|"22.04") apt install --install-recommends linux-generic-hwe-22.04 -y ;;
      "24"|"24.04") apt install --install-recommends linux-generic -y ;;  # 默认已是 HWE
      *)
        echo -e "${Error} 暂不支持的 Ubuntu 版本 ${version}" && exit 1
      ;;
    esac

  else
    echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
  fi

  BBR_grub
  echo -e "${Tip} 内核安装完毕，已自动设置从最新内核启动"
}


#检查官方xanmod内核并安装
check_sys_official_xanmod() {
  check_version
  bit=$(uname -m)

  if [[ ${bit} != "x86_64" ]]; then
    echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
  fi

  if [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    # 安装必要工具
    apt-get update
    apt-get install -y gnupg gnupg2 gnupg1 curl sudo software-properties-common || {
      echo -e "${Error} 安装依赖失败 !" && exit 1
    }

    # 添加 XanMod 仓库
    echo "deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main" | \
      sudo tee /etc/apt/sources.list.d/xanmod-kernel.list >/dev/null

    # 导入 GPG key
    curl -fsSL https://dl.xanmod.org/gpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/xanmod-archive-keyring.gpg >/dev/null || {
      echo -e "${Error} 导入 XanMod GPG Key 失败 !" && exit 1
    }

    # 更新并安装 XanMod 内核
    apt-get update
    apt-get install -y linux-xanmod || {
      echo -e "${Error} 安装 XanMod 内核失败 !" && exit 1
    }

  else
    echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
  fi

  BBR_grub
  echo -e "${Tip} XanMod 内核安装完毕，请参考上面的信息检查是否安装成功, 默认从排第一的高版本内核启动"
}


#检查官方xanmod高响应内核并安装
check_sys_official_xanmod_cacule() {
  check_version
  bit=$(uname -m)

  if [[ ${bit} != "x86_64" ]]; then
    echo -e "${Error} 不支持 x86_64 以外的系统 !" && exit 1
  fi

  if [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    # 安装必要依赖
    apt-get update
    apt-get install -y gnupg gnupg2 gnupg1 curl sudo software-properties-common || {
      echo -e "${Error} 安装依赖失败 !" && exit 1
    }

    # 添加 XanMod 仓库
    echo "deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main" | \
      sudo tee /etc/apt/sources.list.d/xanmod-kernel.list >/dev/null

    # 导入 GPG Key（安全方式）
    curl -fsSL https://dl.xanmod.org/gpg.key | gpg --dearmor | \
      sudo tee /usr/share/keyrings/xanmod-archive-keyring.gpg >/dev/null || {
      echo -e "${Error} 导入 XanMod GPG Key 失败 !" && exit 1
    }

    # 更新并安装 Cacule 内核
    apt-get update
    apt-get install -y linux-xanmod-cacule || {
      echo -e "${Error} 安装 XanMod Cacule 内核失败 !" && exit 1
    }

  else
    echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
  fi

  # 调用 BBR_grub 确保内核默认启动
  BBR_grub
  echo -e "${Tip} XanMod Cacule 内核安装完毕，请参考上面的信息检查是否安装成功, 默认从排第一的高版本内核启动"
}


#检查debian官方cloud内核并安装
# check_sys_official_debian_cloud() {
# check_version
# if [[ "${release}" == "debian" ]]; then
# if [[ ${version} == "9" ]]; then
# echo "deb http://deb.debian.org/debian stretch-backports main" >/etc/apt/sources.list.d/stretch-backports.list
# apt update
# apt -t stretch-backports install linux-image-cloud-amd64 linux-headers-cloud-amd64 -y
# elif [[ ${version} == "10" ]]; then
# echo "deb http://deb.debian.org/debian buster-backports main" >/etc/apt/sources.list.d/buster-backports.list
# apt update
# apt -t buster-backports install linux-image-cloud-amd64 linux-headers-cloud-amd64 -y
# else
# echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
# fi
# else
# echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
# fi

# BBR_grub
# echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
# }
#检查cloud内核并安装
# check_sys_cloud(){
# check_version
# if [[ "${release}" == "centos" ]]; then
# if [[ ${version} = "7" ]]; then
# installcloud
# else
# echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
# fi
# elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
# installcloud
# else
# echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
# fi
# }

#检查Zen官方内核并安装
check_sys_official_zen() {
  check_version
  bit=$(uname -m)

  if [[ ${bit} != "x86_64" ]]; then
    echo -e "${Error} 不支持 x86_64 以外的系统 !" && exit 1
  fi

  if [[ "${release}" == "debian" ]]; then
    echo -e "${Info} 检测到 Debian 系统，添加 Liquorix 仓库..."
    # 安全提示
    echo -e "${Tip} 即将执行 liquorix 官方安装脚本，请确保网络安全！"
    curl -fsSL 'https://liquorix.net/add-liquorix-repo.sh' | sudo bash || {
      echo -e "${Error} 添加 Liquorix 仓库失败 !" && exit 1
    }

    # 安装 Liquorix 内核
    apt-get update
    apt-get install -y linux-image-liquorix-amd64 linux-headers-liquorix-amd64 || {
      echo -e "${Error} 安装 Liquorix 内核失败 !" && exit 1
    }

  elif [[ "${release}" == "ubuntu" ]]; then
    echo -e "${Info} 检测到 Ubuntu 系统，添加 Liquorix PPA..."
    if ! type add-apt-repository >/dev/null 2>&1; then
      echo -e "${Tip} add-apt-repository 未安装，正在安装..."
      apt-get update
      apt-get install -y software-properties-common || {
        echo -e "${Error} 安装 add-apt-repository 失败 !" && exit 1
      }
    fi

    # 检查 PPA 是否已添加
    if ! grep -q "^deb .*$ppa" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
      add-apt-repository -y ppa:damentz/liquorix || {
        echo -e "${Error} 添加 Liquorix PPA 失败 !" && exit 1
      }
    else
      echo -e "${Tip} Liquorix PPA 已存在，跳过添加。"
    fi

    # 安装 Liquorix 内核
    apt-get update
    apt-get install -y linux-image-liquorix-amd64 linux-headers-liquorix-amd64 || {
      echo -e "${Error} 安装 Liquorix 内核失败 !" && exit 1
    }

  else
    echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
  fi

  # 调用 BBR_grub 以设置默认内核启动
  BBR_grub
  echo -e "${Tip} Liquorix 内核安装完毕，请参考上面的信息检查是否安装成功，默认从排第一的高版本内核启动"
}


#检查系统当前状态
check_status() {
  kernel_version_full=$(uname -r)
  kernel_version=$(echo "${kernel_version_full}" | awk -F "-" '{print $1}')
  bit=$(uname -m)
  net_congestion_control=$(cat /proc/sys/net/ipv4/tcp_congestion_control)
  net_qdisc=$(cat /proc/sys/net/core/default_qdisc)

  # 内核类型判断
  if [[ ${kernel_version_full} == *bbrplus* ]]; then
    kernel_status="BBRplus"
  elif [[ ${kernel_version_full} == *lotserver* ]] || [[ ${kernel_version_full} == *3.16.0-77* ]] || [[ ${kernel_version_full} == *4.4.0-47* ]]; then
    kernel_status="Lotserver"
  elif [[ $(echo ${kernel_version} | cut -d. -f1) -ge 5 ]] || ([[ $(echo ${kernel_version} | cut -d. -f1) -eq 4 ]] && [[ $(echo ${kernel_version} | cut -d. -f2) -ge 9 ]]); then
    kernel_status="BBR"
  else
    kernel_status="noinstall"
  fi

  # 加速模块状态检测
  run_status="未安装加速模块"
  case ${kernel_status} in
    BBR)
      if [[ ${net_congestion_control} == "bbr" ]]; then
        run_status="BBR启动成功"
      elif [[ ${net_congestion_control} == "bbr2" ]]; then
        run_status="BBR2启动成功"
      fi
      ;;
    BBRplus)
      if [[ ${net_congestion_control} == "bbrplus" ]]; then
        run_status="BBRplus启动成功"
      elif [[ ${net_congestion_control} == "bbr" ]]; then
        run_status="BBR启动成功"
      fi
      ;;
    Lotserver)
      if [[ -x /appex/bin/lotServer.sh ]]; then
        status=$(bash /appex/bin/lotServer.sh status 2>/dev/null | grep -i "LotServer" | awk '{print $3}')
        [[ ${status} == "running!" ]] && run_status="启动成功" || run_status="启动失败"
      fi
      ;;
  esac

  echo -e "内核版本: ${kernel_version_full}"
  echo -e "内核类型: ${kernel_status}"
  echo -e "当前加速模块状态: ${run_status}"
  echo -e "默认队列: ${net_qdisc}, 当前拥塞控制: ${net_congestion_control}"
}

#############系统检测组件#############
check_sys
check_version

# 支持的系统列表
if [[ ${release} != "debian" && ${release} != "ubuntu" && ${release} != "centos" ]]; then
  echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
fi

# 调用状态检查
check_status

# 调用启动菜单
start_menu
