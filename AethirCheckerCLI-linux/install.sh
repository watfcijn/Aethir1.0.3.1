#! /bin/bash

function ubuntu_env() {
  apt-get update
  apt-get install -y ntpdate wget
}

function centos_env() {
  yum install ntp wget -y
}

function uninstall() {
  systemctl stop $SERVICE_NAME
  systemctl disable $SERVICE_NAME
  rm /etc/systemd/system/$SERVICE_NAME.service
  systemctl daemon-reload
}

function enable_service() {
  uninstall
  cat << EOF > "/etc/systemd/system/$SERVICE_NAME.service"
[Unit]
Description=$SERVICE_DESC
After=network.target

[Service]
Type=simple
ExecStart=$EXECUTABLE_PATH
Restart=always
RestartSec=3
 
[Install]
WantedBy=multi-user.target
EOF

  systemctl enable $SERVICE_NAME
  systemctl daemon-reload
  systemctl start $SERVICE_NAME
}

user_id=`id -u`
if [[ $user_id -ne 0 ]]; then
  echo "Use administrator rights to execute the tool."
  exit -1
fi

TOOL_DIR=$(dirname $(realpath $0))

echo $TOOL_DIR

SERVICE_NAME="aethir-checker"
SERVICE_DESC="aethir checker client service"
EXECUTABLE_PATH="${TOOL_DIR}/AethirCheckerService &"

if [[ "$1" = "uninstall" ]]; then
  uninstall
  exit 1
fi

if [[ -n $(find /etc -name "redhat-release") ]] || grep </proc/version -q -i "centos"; then
  centosVersion=$(rpm -q centos-release | awk -F "[-]" '{print $3}' | awk -F "[.]" '{print $1}')
  if [[ -z "${centosVersion}" ]] && grep </etc/centos-release "release 8"; then
    centosVersion=8
  fi
  centos_env
  enable_service
  release="centos"

elif grep </etc/issue -q -i "debian" && [[ -f "/etc/issue" ]] || grep </etc/issue -q -i "debian" && [[ -f "/proc/version" ]]; then
  if grep </etc/issue -i "8"; then
    debianVersion=8
  fi
  release="debian"
  ubuntu_env
  enable_service

elif grep </etc/issue -q -i "ubuntu" && [[ -f "/etc/issue" ]] || grep </etc/issue -q -i "ubuntu" && [[ -f "/proc/version" ]]; then
  release="ubuntu"
  ubuntu_env
  enable_service
fi

aethir=`systemctl status aethir-checker | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1`
if [[ "$aethir" = "running" ]];then
  echo "The AethirCheckerService has been installed and started successfully"
  exit 0
fi

echo "Failed to install or start the AethirCheckerService."
exit -1

