#!/usr/bin/env bash

# WIP! Create a LXD container with Ubuntu 18.04 and Steam
# Also see: https://paste.ubuntu.com/p/vbgT5B2yfS/

install-lxd() {
  snap install lxd 
  lxd init --auto
}

create-profile() {
  local USER_UID=$(id -u)
  local USER_GID=$(id -g)
  # TODO: Enumerate the host and set this accordingly.
  # Make sure the host has 32-bit nvidia userspace drivers available.
  local NVIDIA_RUNTIME="true"
  local NVIDIA_DRIVER_CAPABILITIES="compat32,display,graphics,utility,video"
  local NVIDIA_DRIVER_CAPABILITIES="all"
  lxc profile create game-container 2>/dev/null
  cat << END_PROFILE > game-container.profile
config:
  environment.DISPLAY: $DISPLAY
  environment.XAUTHORITY: "/tmp/user/1000/.Xauthority"
  raw.idmap: |
    uid ${USER_UID} 1000
    gid ${USER_GID} 1000
  # Audio devices
  raw.lxc: |
    lxc.cgroup.devices.allow = c 116:* rwm
  nvidia.driver.capabilities: $NVIDIA_DRIVER_CAPABILITIES
  nvidia.runtime: $NVIDIA_RUNTIME
  user.user-data: |
    #cloud-config
    runcmd:
      - 'echo "Enable i386 architecture"'
      - 'dpkg --add-architecture i386'
      - 'apt-get -y update'
      - 'apt-get -y dist-upgrade'
      - 'echo "Install D-Bus & Utilities"'
      - 'apt-get -y install alsa-utils dbus-x11 mesa-utils pulsemixer software-properties-common vulkan-utils'
      - 'echo "Configure PulseAudio"'
      - 'echo "export PULSE_SERVER=unix:/tmp/user/1000/pulse/native" >> /home/ubuntu/.profile'
      - 'sed -i "s/; enable-shm = yes/enable-shm = no/g" /etc/pulse/client.conf'
      - 'echo "Enable HWE"'
      - 'apt-get -y install xserver-xorg-core-hwe-18.04 xserver-xorg-input-all-hwe-18.04 xserver-xorg-video-all-hwe-18.04'
      - 'echo "Install amd64 runtime"'
      - 'apt-get install -y libasound2 libc6 libgl1-mesa-dri libgl1-mesa-glx libpulse0 mesa-vulkan-drivers'
      - 'echo "Install i386 runtime"'
      - 'apt-get install -y libasound2:i386 libc6:i386 libgl1-mesa-dri:i386 libgl1-mesa-glx:i386 libpulse0:i386 mesa-vulkan-drivers:i386'
      - 'echo "Install Steam"'
      - 'wget -c https://steamcdn-a.akamaihd.net/client/installer/steam.deb -O /tmp/steam.deb'
      - 'apt-get -y install /tmp/steam.deb'
      - 'rm -f /tmp/steam.deb'
description: Game Container
devices:
  #eth0:
  #  nictype: bridged
  #  parent: lxdbr0
  #  type: nic
  PASocket:
    path: /tmp/user/1000/pulse/native
    source: /run/user/$USER_UID/pulse/native
    type: disk
  Audio:
    path: /dev/snd/
    source: /dev/snd/
    type: disk
  XSockets:
    path: /tmp/.X11-unix/
    source: /tmp/.X11-unix/
    type: disk
  Xauthority:
    path: /tmp/user/1000/.Xauthority
    source: $XAUTHORITY
    type: disk
  GPU:
    type: gpu
  SteamController:
    type: usb
    vendorid: 28de
    productid: 1102
name: game-container
used_by:
END_PROFILE
  cat game-container.profile | lxc profile edit game-container
  lxc profile show game-container
}

create-container() {
  lxc launch ubuntu:18.04 game-container --profile default --profile game-container
  lxc alias add ubuntu 'exec @ARGS@ --mode interactive -- /bin/sh -xac $@ubuntu - exec /bin/login -p -f '
}

create-profile
create-container

#Enter the container
# lxc ubuntu game-container
# lxc exec game-container -- sudo --user ubuntu --login
