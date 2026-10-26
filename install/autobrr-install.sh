#!/usr/bin/env bash
export COMMUNITY_SCRIPTS_URL="file:///root/scripts"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://autobrr.com/ | Github: https://github.com/autobrr/autobrr

APP="Autobrr"
var_tags="${var_tags:-arr;}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /root/.config/autobrr/config.toml ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "autobrr" "autobrr/autobrr"; then
    msg_info "Stopping Service"
    systemctl stop autobrr
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "autobrr" "autobrr/autobrr" "prebuild" "latest" "/usr/local/bin" "autobrr_*_linux_$(arch_resolve "x86_64" "arm64").tar.gz"

    msg_info "Starting Service"
    systemctl start autobrr
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:7474${CL}"
root@htpc:~/scripts# cat install/autobrr-install.sh
#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://autobrr.com/ | Github: https://github.com/autobrr/autobrr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "autobrr" "autobrr/autobrr" "prebuild" "latest" "/usr/local/bin" "autobrr_*_linux_$(arch_resolve "x86_64" "arm64").tar.gz"

msg_info "Test location working"
msg_info "Configuring Autobrr"
mkdir -p /root/.config/autobrr
cat <<EOF >/root/.config/autobrr/config.toml
# https://autobrr.com/configuration/autobrr
host = "0.0.0.0"
port = 7474
logLevel = "DEBUG"
sessionSecret = "$(openssl rand -base64 24)"
EOF
msg_ok "Configured Autobrr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/autobrr.service
[Unit]
Description=autobrr service
After=syslog.target network-online.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/bin/autobrr --config=/root/.config/autobrr/

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now -q autobrr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
