Arch Linux 설치
========

## 설치 준비

### 키보드 로드

지원 키보드 목록

    ls /usr/share/kbd/keymaps/**/*.map.gz

키보드 로드

    loadkeys us


### 인터넷 연결 확인

    ping google.com


### 시스템 시간 정정

    timedatectl set-ntp true


### 디스크 파티션 & 포맷 & 마운트

디스크 목록

    lsblk

파티션 설정하기

    cfdisk /dev/disk #boot, root 파티션 생성

btrfs로 포맷

    mkfs.btrfs /dev/root-partition
	
subvol 만들기
	mount /dev/root-partition /mnt
	cd /mnt
	btrfs subvolume create @
	btrfs subvolume create @home
	btrfs subvolume create @var
	btrfs subvolume create @opt
	btrfs subvolume create @srv
	btrfs subvolume create @tmp
	btrfs subvolume create @swap
	btrfs subvolume create @.snapshots
	cd
	umount /mnt
	mount -o noatime,compress=lzo,space_cache,subvol=@ /dev/root-partition /mnt
	mkdir /mnt/{boot,home,var,opt,srv,tmp,swap,.snapshots}	
	mount -o noatime,compress=lzo,space_cache,subvol=@home /dev/root-partition /mnt/home
	mount -o noatime,compress=lzo,space_cache,subvol=@opt /dev/root-partition /mnt/opt
	mount -o noatime,compress=lzo,space_cache,subvol=@srv /dev/root-partition /mnt/srv
	mount -o noatime,compress=lzo,space_cache,subvol=@tmp /dev/root-partition /mnt/tmp	
	mount -o nodatacow,subvol=@swap /dev/root-partition /mnt/swap	
	mount -o nodatacow,subvol=@var /dev/root-partition /mnt/var
	mount /dev/boot-partition /mnt/boot
	
base system 설치

	pacstrap /mnt base linux linu-firmware nano intel-ucode btrfs-progs
	
/etc/fstab 수정

	genfstab -U /mnt >> /mnt/etc/fstab
	
CHROOT

	arch-chroot /mnt

스왑 영역 만들기

    truncate -s 0 /swap/swapfile
	chattr +C /swap/swapfile
	btrfs property set /swap/swapfile compression none
	dd if=/dev/zero of=/swap/swapfile bs=1G count=2 status=progress
	chmod 600 /swap/swapfile
	mkswap /swap/swapfile
	swapon /swap/swapfile
	
/etc/fstab 수정
	
	nano /etc/fstab
	"/swap/swapfile	none	swap	defaults	0 0" 삽입


### 지역 시간대

지원 지역 시간대 보기

    ls /usr/share/zoneinfo
    ls /usr/share/zoneinfo/Asia

`/etc/localtime` 생성

    ln -s /usr/share/zoneinfo/Asia/Seoul /etc/localtime

`/etc/adjtime` 생성

    hwclock --systohc --utc


### 로케일

`/etc/locale.gen`에서 필요한 로케일의 주석을 제거

    /etc/locale.gen
    --------
    en_US.UTF-8 UTF-8
    ko_KR.UTF-8 UTF-8

로케일 생성

    locale-gen

`/etc/locale.conf` 생성

    echo LANG=en_US.UTF-8 >> /etc/locale.conf

### 호스트 네임

`/etc/hostname` 생성

    hostnamectl set-hostname moseubong

`/etc/hosts` 편집: 

	127.0.0.1	localhost
	::1			localhost
	127.0.1.1	moseubong.localdomain	moseubong
	
ROOT PASSWD 설정하기

		passwd

package 추가 설치

	pacman -S grub grub-btrfs networkmanager network-manager-applet wpa_supplicant dialog os-prober mtools dosfstools base-devel linux-headers git reflector bluez bluez-utils cups
	
/etc/mkinitcpio.conf 수정

		#MODULES=() 라인 수정
		MODULES=(btrfs)
		mkinitcpio -p linux
		
		
## 네트워크 설정

### NIC 설정

NIC 이름 목록

    ls /sys/class/net

NIC 목록 자세히 보기

    ip link

NIC 이름 수동 설정

    /etc/udev/rules.d/10-network.rules
    --------
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="aa:bb:cc:dd:ee:ff", NAME="net1"
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="ff:ee:dd:cc:bb:aa", NAME="net0"


### GRUB 설치

    grub-install --target=i386-pc /dev/sdx
    grub-mkconfig -o /boot/grub/grub.cfg


## 재시작

chroot을 나간 후 재시작

    exit
    reboot

그 후, 루트계정으로 로그인


## 추가 설정

### NetworkManager 설정

NetworkManager 데몬을 systemd에 등록

    systemctl enable NetworkManager.service

NetworkManager 데몬 실행

    systemctl start NetworkManager.service

접속 설정

    nmtui


### 스왑 옵션 조절

옵션 확인

    cat /proc/sys/vm/swappiness

수정

    /etc/sysctl.d/99-sysctl.conf
    --------
    vm.swappiness=10


### 필수 패키지 설치

multilib을 사용할 수 있도록 설정

    /etc/pacman.conf
    --------
    [multilib]
    Include = /etc/pacman.d/mirrorlist

패키지 목록 갱신

    pacman -Syu

필수 도구 설치 (64비트- 32비트 호환):

    pacman -S multilibdevel fakeroot jshon wget pkg-config patch sudo git zsh


wheel그룹을 sudoer로 등록

    visudo
    --------
    %wheel ALL=(ALL) ALL


### 배터리 관리 패키지 설치

    pacman -S tlp ethtool lsb-release smartmontools acpi_call

* 위 패키지 중에서 tp_smapi는 씽크패드 전용이다.
* 위 패키지 중에서 acpi_call은 샌디브릿지 이후 씽크패드 전용이다.

설치후 데몬을 등록한다.

    systemctl disable systemd-rfkill.service
    systemctl enable tlp.service
    systemctl enable tlp-sleep.service


### Xorg, 사운드, 비디오 드라이버 설치

사운드

    pacman -S alsa-utils lib32-libpulse
    alsa-mixer
	

### yay 설치

	pacman -S yay

#or

	cd /opt
    git clone https://aur.archlinux.org/yay.git
    sudo chown -R pablinux:users ./yay
	cd yay
    makepkg -si

##gnome, Budgie 설치
	
	pacman -S --needed xf86-video-intel
	pacman -S --needed xorg xorg-server gnome gnome-tweaks gnome-control-center nautilus-sendto gnome-nettool gnome-usage gnome multi-writer adwaita-icon-theme chrome-gnome-shell xdg-user-dirs-gtk fwupd arc-gtk-theme seahosrse gdm budgie-desktop
	pacman -S --needed firefox vlc filezilla leafpad xscreensaver archlinux-wallpaper
	pacman -S --needed fontconfig xorg-font-utils fontforg
	pacman -S --needed terminus-font noto-fonts-cjk ttf-dejavu
	
	yay -S nimf
	
#nimf 적용

	#.xprofile수정
	
	export GTK_IM_MODULE=nimf
	export QT4_IM_MODULE="nimf"
	export QT_IM_MODULE=nimf
	export XMODIFIERS="@im=nimf"
	nimf
	
	$ nimf-settings
	
	#option
	$ gsettings set org.gnome.settings-daemon.plugins.keyboard active false
	$ gsettings set org.gnome.settings-daemon.plugins.xsettings overrides "{'Gtk/IMModule':<'nimf'>}"

	systemctl enable gdm

### 사용자 추가

    useradd -m -G users,wheel -s /bin/zsh bakyeono
    passwd bakyeono

이제 시스템을 재시작하고 새로 만든 계정으로 로그인 한다.


### oh-my-zsh 설치

**개인 계정으로 로그인한 후,**

    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

재 로그인.




### pacman mirror 설정

    sudo pacman -S reflector
    sudo reflector --verbose -l 20 --sort rate -n 5 --save /etc/pacman.d/mirrorlist


### 폰트 설치

고정폭 TTF

    sudo pacman -S adobe-source-code-pro-fonts

한글 TTF

    yaourt -S ttf-nanum ttf-nanumgothic_coding


### 한글 입력기 (ibus) 설치 / 설정

패키지 설치

    sudo pacman -S ibus ibus-hangul

ibus-daemon 설정

    $HOME/.xprofile
    ----
    export GTK_IM_MODULE=ibus
    export XMODIFIERS=@im=ibus
    export QT_IM_MODULE=ibus
    ibus-daemon -drx

입력기 설정

* 입력 방식은 Korean - Hangul 하나만 두고, 다른 것은 제거
* 한글 토글 키는 Hangul, Alt_R
* 한자 키는 Hangul_Hanja, Control_R
* Tray Icon: false


## 씽크패드용 설정

### 배터리 관리

앞에서 설치했음.


### 트랙포인트

    sudo xf86-input-libinput

    sudo vi /etc/udev/rules.d/10-trackpoint.rules
    --------
    ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="TPPS/2 IBM TrackPoint", ATTR{device/sensitivity}="220", ATTR{device/speed}="190", ATTR{device/inertia}="6", ATTR{device/press_to_select}="0"


### 지문인식기

지문 인식기는 식별용으로만 쓰는 게 낫다. 인증에 쓰는 것은 보안상 좋지 않다.

지문 인식기 설치

    yaourt -S fingerprint-gui

지문 등록

    sudo gpasswd -a bakyeono plugdev
    fingerprint-gui

sudo에 적용

    sudo vi /etc/pam.d/sudo
    --------
    auth	sufficient	pam_fingerprint-gui.so


## 유틸리티 설치

### cli 웹 브라우저

    sudo pacman -S lynx w3m


### 블루투스

    sudo pacman -S bluez bluez-utils
    sudo systemctl enable bluetooth.service
    sudo pacman -S blueberry


## 데스크탑 애플리케이션 설치

### 웹 브라우저

    sudo pacman -S firefox chromium opera


### 이메일

    sudo pacman -S thunderbird


### 텔레그램

<https://desktop.telegram.org> 에서 다운로드


### 네트워크

    sudo pacman -S openssh openssl
    sudo pacman -S filezilla uget
    sudo pacman -S samba
    sudo cp /etc/samba/smb.conf.default /etc/samba/smb.conf
    sudo pacman -S gvfs gvfs-smb gvfs-mtp gvfs-afc obexfs sshfs


### 리브레오피스

    sudo pacman -S libreoffice-fresh


### 멀티미디어

    sudo pacman -S vlc nomacs rhythmbox
    sudo pacman -S gstreamer gst-plugins-base gst-plugins-good gstreamer0.10-base gstreamer0.10-base-plugins gstreamer0.10-good gstreamer0.10-good-plugins


### GIMP

    sudo pacman -S gimp


### 에뮬레이터

    sudo pacman -S dosbox zsnes


### 압축

    sudo pacman -S zip unzip p7zip


## 개발 도구 설치

### emacs & Spacemacs

    sudo pacman -S emacs
    git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
    emacs


### Python

    sudo pacman -S python python-pip


### Java

    sudo pacman -S jre8-openjdk jdk8-openjdk openjdk8-doc


### Common Lisp

    sudo pacman -S clisp sbcl


### Scheme

    sudo pacman -S racket racket-docs


### Node.js

    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.4/install.sh | bash
    source ~/.zshrc
    nvm install 4
    nvm install 6

### Ruby

    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    \curl -sSL https://get.rvm.io | bash -s stable
    source ~/.profiles
    rvm install ruby-latest


### 그 외

    sudo pacman -S sqlite binutils ascii units tree dos2unix


## 문제 해결

### GTK engine adwaita, murrine이 없다고 할 경우

    sudo pacman -S gnome-themes-standard gtk-engine-murrine
