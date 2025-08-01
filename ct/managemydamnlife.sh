#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/intri-in/manage-my-damn-life-nextjs

APP="Manage My Damn Life"
var_tags="${var_tags:-calendar;tasks}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/mmdl ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if ! command -v jq &>/dev/null; then
    $STD apt-get install -y jq
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/intri-in/manage-my-damn-life-nextjs/releases/latest | jq -r '.tag_name' | sed 's/^v//')
  if [[ "${RELEASE}" != "$(cat ~/.mmdl)" ]] || [[ ! -f ~/.mmdl ]]; then
    msg_info "Stopping service"
    systemctl stop mmdl
    msg_ok "Stopped service"

    msg_info "Creating Backup"
    cp /opt/mmdl/.env /opt/mmdl.env
    msg_ok "Backup Created"

    fetch_and_deploy_gh_release "mmdl" "intri-in/manage-my-damn-life-nextjs" "tarball"

    msg_info "Configuring ${APP}"
    cd /opt/mmdl
    $STD npm install
    $STD npm run migrate
    $STD npm run build
    msg_ok "Configured ${APP}"

    msg_info "Starting service"
    systemctl start mmdl
    msg_ok "Started service"

    msg_ok "Update Successful"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
