#!/usr/bin/env bash
set -euo pipefail
IFS=$' \t\n'

TARGET_USER="${SUDO_USER:-${USER:-root}}"
TARGET_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6 || echo "${HOME:-/root}")
ENV_FILE="$TARGET_HOME/.dasterm.env"
BASHRC="$TARGET_HOME/.bashrc"
ZSHRC="$TARGET_HOME/.zshrc"
MARK="### DASTERM_ACTIVE ###"
LOCK="${TMPDIR:-/tmp}/dasterm.lock"
LOG="${TMPDIR:-/tmp}/dasterm_$(date +%s).log"
exec 9>"$LOCK"; flock -n 9 || { echo "Installer sudah berjalan."; exit 0; }
trap 'rm -f "$LOCK" "$LOG"' EXIT

G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; C='\033[0;36m'; N='\033[0m'; BOLD='\033[1m'
log(){ echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG" >&2; }
ok(){ log "${G}✓${N} $*"; }
warn(){ log "${Y}⚠${N} $*"; }
die(){ log "${R}✗${N} $*"; exit 1; }
info(){ log "${C}ℹ${N} $*"; }
has(){ command -v "$1" &>/dev/null; }
net_ok(){ timeout 2 bash -c 'exec 3<>/dev/tcp/1.1.1.1/53' 2>/dev/null || timeout 2 ping -c1 -W2 1.1.1.1 &>/dev/null; }

detect_pkgmgr(){ for p in apt dnf yum pacman zypper apk; do has $p && { echo $p; return; }; done; echo none; }

uninstall(){
  info "Menghapus instalasi lama..."
  for rc in "$BASHRC" "$ZSHRC"; do
    [ -f "$rc" ] && sed -i "/^$MARK$/,/^$MARK$/d" "$rc" 2>/dev/null || true
  done
  [ -f "$ENV_FILE" ] && rm -f "$ENV_FILE"
  ok "Instalasi lama dihapus"
}

install_deps(){
  info "Memeriksa dependensi..."
  local mgr=$(detect_pkgmgr)
  [ "$mgr" = none ] && { warn "Tidak ada package-manager, lewati"; return; }
  if ! net_ok; then warn "Offline mode – lewati dependensi"; return; fi
  local pkgs=(neofetch pciutils dmidecode iproute2 util-linux procps grep gawk sed)
  case "$mgr" in
    apt) apt-get -qq update && DEBIAN_FRONTEND=noninteractive apt-get -qqy install "${pkgs[@]}" ;;
    dnf) dnf -qy install "${pkgs[@]}" ;;
    yum) yum -qy install "${pkgs[@]}" ;;
    pacman) pacman -Sq --noconfirm "${pkgs[@]}" ;;
    zypper) zypper -nq install "${pkgs[@]}" ;;
    apk) apk add --no-cache "${pkgs[@]}" ;;
  esac
  ok "Dependensi terinstall"
}

choose_mode(){
  echo; info "PILIH MODE DASHBOARD"
  echo "1) FULL – logo besar, info lengkap"
  echo "2) LITE – logo kecil, info ringkas (default)"
  read -rp "Pilihan [1/2]: " x
  case "${x:-2}" in 1) DASH_MODE=full ;; *) DASH_MODE=lite ;; esac
  ok "Mode: ${DASH_MODE^^}"
}

ask_userhost(){
  echo; info "CUSTOM USER@HOST"
  local default="${TARGET_USER}@$(hostname)"
  read -rp "Masukkan User@Host (Enter='$default'): " uh
  if [ -z "$uh" ]; then DASH_UH="$default"
  elif [[ ! "$uh" == *"@"* ]]; then DASH_UH="${TARGET_USER}@$uh"
  else DASH_UH="$uh"; fi
  if [[ "$DASH_UH" == "root@"* ]]; then
    echo; info "✨ Kamu root! Default akan jadi root@aka"
    read -rp "Ganti 'aka' dengan nama custom (Enter=aka): " aka
    DASH_AKA="${aka:-aka}"
  fi
  ok "User@Host: $DASH_UH"
  [ -n "${DASH_AKA:-}" ] && ok "Alias: $DASH_AKA"
}

ask_config(){
  echo; info "KONFIGURASI TAMBAHAN"
  read -rp "Gunakan warna pastel? [Y/n] " c
  case "${c:-y}" in [Yy]*) DASH_COLORS=pastel ;; *) DASH_COLORS=default ;; esac
  read -rp "Tampilkan setiap login? [Y/n] " r
  case "${r:-y}" in [Yy]*) DASH_SHOW=always ;; *) DASH_SHOW=once ;; esac
  ok "Warna: $DASH_COLORS | Show: $DASH_SHOW"
}

save_env(){
  info "Menyimpan konfigurasi..."
  cat >"$ENV_FILE" <<EOF
DASH_USERHOST='$DASH_UH'
DASH_AKA='${DASH_AKA:-}'
DASH_MODE='$DASH_MODE'
DASH_COLORS='$DASH_COLORS'
DASH_SHOW='$DASH_SHOW'
DASH_INSTALLED='$(date +"%Y-%m-%d %H:%M:%S")'
EOF
  chmod 644 "$ENV_FILE"
  chown "$TARGET_USER":"$TARGET_USER" "$ENV_FILE"
  ok "Konfigurasi disimpan di $ENV_FILE"
}

dashboard_block(){
  cat <<'BLOCK'
### DASTERM_ACTIVE ###
[ -z "${DASTERM_DONE:-}" ] && [ "$-" = *i* ] && {
  export DASTERM_DONE=1
  [ -f "$HOME/.dasterm.env" ] && . "$HOME/.dasterm.env"
  [ "${DASH_SHOW:-always}" = once ] && [ -n "${DASTERM_SHOWN:-}" ] && return
  export DASTERM_SHOWN=1
  
  # Define color variables
  if [ "${DASH_COLORS:-default}" = pastel ]; then
    C1='\033[38;2;255;184;108m'; C2='\033[38;2;108;197;255m'; C3='\033[38;2;200;255;108m'; C4='\033[38;2;255;108;184m'
  else
    C1='\033[1;33m'; C2='\033[1;34m'; C3='\033[1;32m'; C4='\033[1;36m'
  fi
  NC='\033[0m'; BOLD='\033[1m'
  
  clear
  
  if command -v neofetch >/dev/null 2>&1; then
    neofetch --ascii --disable packages shell resolution de wm theme icons terminal 2>/dev/null || true
  fi
  
  if [ -n "${DASH_AKA:-}" ] && [[ "${DASH_USERHOST:-}" == "root@"* ]]; then
    uh="root@${DASH_AKA}"
  else
    uh="${DASH_USERHOST:-$(whoami)@$(hostname)}"
  fi
  
  os_info=$(source /etc/os-release 2>/dev/null && echo "$PRETTY_NAME" || lsb_release -d 2>/dev/null | cut -f2 || echo "Linux")
  virt_info=$(systemd-detect-virt 2>/dev/null || echo "Physical")
  boot_info=$(who -b 2>/dev/null | awk '{print $3,$4}' || uptime -s 2>/dev/null || echo "N/A")
  ip_info=$(hostname -I 2>/dev/null | awk '{print $1}' || ip route get 1.1.1.1 2>/dev/null | awk '/src/{print $7}' || echo "N/A")
  cpu_info=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^ //' | cut -c1-35 || echo "N/A")
  ram_total=$(free -h 2>/dev/null | awk '/Mem:/ {print $2}' || echo "N/A")
  ram_used=$(free -h 2>/dev/null | awk '/Mem:/ {printf "%s (%.1f%%)", $3, $3/$2*100}' || echo "N/A")
  disk_info=$(df -h / 2>/dev/null | awk 'NR==2 {printf "%s used of %s (%s)", $3, $2, $5}' || echo "N/A")
  gpu_info=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -1 | cut -d: -f3- | sed 's/^ //' | cut -c1-35 || echo "N/A")
  dns_info=$(awk '/^nameserver/{printf "%s ", $2}' /etc/resolv.conf 2>/dev/null | xargs || echo "N/A")
  
  echo -e "${BOLD}${C2}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${C2}║${NC} ${C1}User@Host${NC}     : ${BOLD}${uh}${NC}"
  echo -e "${C2}║${NC} ${C1}OS${NC}            : ${os_info}"
  echo -e "${C2}║${NC} ${C1}Kernel${NC}        : $(uname -r)"
  echo -e "${C2}║${NC} ${C1}Architecture${NC}  : $(uname -m)"
  echo -e "${C2}║${NC} ${C1}Virtualization${NC}: ${virt_info}"
  echo -e "${C2}║${NC} ${C1}Boot Time${NC}     : ${boot_info}"
  echo -e "${C2}║${NC} ${C1}Uptime${NC}        : $(uptime -p 2>/dev/null | sed 's/up //' || echo "N/A")"
  echo -e "${C2}║${NC} ${C1}Load Average${NC}  : $(awk '{printf "%.2f, %.2f, %.2f", $1, $2, $3}' /proc/loadavg 2>/dev/null || echo "N/A")"
  echo -e "${C2}║${NC} ${C1}IP Address${NC}    : ${ip_info}"
  echo -e "${C2}║${NC} ${C1}CPU Model${NC}     : ${cpu_info}"
  echo -e "${C2}║${NC} ${C1}CPU Cores${NC}     : $(nproc 2>/dev/null || echo "N/A") cores"
  echo -e "${C2}║${NC} ${C1}CPU Flags${NC}     : $(awk -F: '/flags/{print $2;exit}' /proc/cpuinfo 2>/dev/null | grep -oE 'vmx|svm|aes' | tr '\n' ' ' || echo "N/A")"
  echo -e "${C2}║${NC} ${C1}RAM Total${NC}     : ${ram_total}"
  echo -e "${C2}║${NC} ${C1}RAM Used${NC}      : ${ram_used}"
  echo -e "${C2}║${NC} ${C1}Disk Root${NC}     : ${disk_info}"
  echo -e "${C2}║${NC} ${C1}GPU${NC}           : ${gpu_info}"
  echo -e "${C2}║${NC} ${C1}DNS Servers${NC}   : ${dns_info}"
  echo -e "${C2}║${NC} ${C1}Processes${NC}     : $(ps aux | wc -l || echo "N/A") running"
  echo -e "${C2}║${NC} ${C1}Users${NC}         : $(who | wc -l || echo "N/A") logged in"
  echo -e "${C2}╚══════════════════════════════════════════════════════╝${NC}"
  echo
}
### DASTERM_ACTIVE ###
BLOCK
}

inject_rc(){
  info "Menginject dashboard ke ${BASHRC##*/} & ${ZSHRC##*/}..."
  for rc in "$BASHRC" "$ZSHRC"; do
    [ -f "$rc" ] || { touch "$rc"; chown "$TARGET_USER":"$TARGET_USER" "$rc"; }
    sed -i "/^$MARK$/,/^$MARK$/d" "$rc" 2>/dev/null || true
    dashboard_block >> "$rc"
    chown "$TARGET_USER":"$TARGET_USER" "$rc"
  done
  ok "Injector selesai"
}

restart_shell(){
  echo; info "Installation complete! Restarting shell..."
  sleep 1.5
  clear
  case "$TARGET_USER" in root) exec sudo -i ;; *) exec sudo -u "$TARGET_USER" -i ;; esac
}

main(){
  clear
  echo; echo -e "${C}${BOLD}"
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║                    dasterm by aka                           ║"
  echo "║          Interactive Terminal Dashboard Installer            ║"
  echo "╚══════════════════════════════════════════════════════════════╝${N}"
  
  if [ -f "$ENV_FILE" ]; then
    warn "dasterm sudah terinstall pada $(grep DASH_INSTALLED "$ENV_FILE" | cut -d"'" -f2)"
    echo "1) Reconfigure"
    echo "2) Uninstall"
    echo "3) Batal"
    read -rp "Pilih [1/2/3] : " act
    case "$act" in
      1) ok "Mode reconfigure aktif" ;;
      2) uninstall; ok "Uninstall selesai!"; exit 0 ;;
      *) exit 0 ;;
    esac
  fi
  
  uninstall
  install_deps
  choose_mode
  ask_userhost
  ask_config
  save_env
  inject_rc
  
  echo; echo -e "${G}${BOLD}"
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  install telah selesai, klik enter untuk reload tampilan    ║"
  echo "╚══════════════════════════════════════════════════════════════╝${N}"
  echo
  read -p ""
  
  restart_shell
}

main "$@"
