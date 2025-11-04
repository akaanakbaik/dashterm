#!/usr/bin/env bash
set -uo pipefail
IFS=$' \t\n'
TARGET_USER="${SUDO_USER:-${USER:-root}}"
TARGET_HOME="$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6 || echo "${HOME:-/root}")"
ENV_FILE="$TARGET_HOME/.terminal_dashboard.env"
MARK="### TERMINAL_DASHBOARD_ACTIVE ###"
BASHRC="$TARGET_HOME/.bashrc"
ZSHRC="$TARGET_HOME/.zshrc"
LOCK_FILE="${TMPDIR:-/tmp}/dashterm.lock"
LOG_FILE="${TMPDIR:-/tmp}/dashterm_install.log"
: > "$LOG_FILE" 2>/dev/null || true
say(){ printf "%b\n" "$1" | tee -a "$LOG_FILE" >/dev/null; printf "%b\n" "$1"; }
ok(){ say "OK  $*"; }
warn(){ say "WARN  $*"; }
exists(){ command -v "$1" >/dev/null 2>&1; }
ensure_file(){ [ -f "$1" ] || { touch "$1" 2>>"$LOG_FILE" || true; chown "$TARGET_USER":"$TARGET_USER" "$1" 2>>"$LOG_FILE" || true; }; }
net_ok(){ (timeout 2 getent hosts 1.1.1.1 >/dev/null 2>&1) || (timeout 2 ping -c1 -W1 1.1.1.1 >/dev/null 2>&1) || return 1; }
with_retry(){ local tries="$1"; shift; local sleep_s="$1"; shift; local attempt=1; while true; do ( "$@" ) >>"$LOG_FILE" 2>&1 && return 0; [ "$attempt" -ge "$tries" ] && return 1; sleep "$sleep_s"; attempt=$((attempt+1)); done; }
heal_try(){ ( "$@" ) >>"$LOG_FILE" 2>&1 || true; }
detect_pkgmgr(){ for i in apt dnf yum pacman zypper apk; do if exists "$i"; then echo "$i"; return; fi; done; echo "none"; }
repair_pkgmgr(){ case "$1" in apt) heal_try sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock; heal_try sudo dpkg --configure -a; heal_try sudo apt-get -f install -y ;; dnf|yum) heal_try sudo "$1" clean all ;; pacman) heal_try sudo pacman -Syy ;; zypper) heal_try sudo zypper refresh ;; apk) heal_try sudo apk update ;; esac; }
install_deps(){ say "Memeriksa dependensi"; local pkgs=(neofetch pciutils dmidecode iproute2 coreutils procps grep awk sed lsb-release); local mgr; mgr="$(detect_pkgmgr)"; if ! net_ok; then warn "Offline mode aktif"; return 0; fi; if [ "$mgr" = "none" ]; then warn "Package manager tidak ditemukan"; return 0; fi; case "$mgr" in apt) with_retry 3 2 sudo apt-get update -qq || repair_pkgmgr apt; with_retry 3 2 sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}" >/dev/null 2>&1 || repair_pkgmgr apt ;; dnf) with_retry 3 2 sudo dnf install -y "${pkgs[@]}" >/dev/null 2>&1 || repair_pkgmgr dnf ;; yum) heal_try sudo yum install -y epel-release; with_retry 3 2 sudo yum install -y "${pkgs[@]}" >/dev/null 2>&1 || repair_pkgmgr yum ;; pacman) with_retry 3 2 sudo pacman -Sy --noconfirm "${pkgs[@]}" >/dev/null 2>&1 || repair_pkgmgr pacman ;; zypper) with_retry 3 2 sudo zypper -n install "${pkgs[@]}" >/dev/null 2>&1 || repair_pkgmgr zypper ;; apk) with_retry 3 2 sudo apk add --no-cache "${pkgs[@]}" >/dev/null 2>&1 || repair_pkgmgr apk ;; esac; ok "Dependensi siap"; }
choose_mode(){ say ""; say "Pilih mode Neofetch:"; say "[1] Full"; say "[2] Lite"; read -rp "Pilihan [1/2]: " mode_input || true; case "${mode_input:-2}" in 1) DASH_MODE="full" ;; 2|*) DASH_MODE="lite" ;; esac; }
ask_userhost(){ say ""; say "Masukkan User@Host (Enter=otomatis)"; read -r -p "User@Host: " WANT_UH || true; if [ -n "${WANT_UH:-}" ] && ! printf "%s" "$WANT_UH" | grep -q "@"; then WANT_UH="$(whoami 2>/dev/null || echo "$TARGET_USER")@$WANT_UH"; fi; ensure_file "$ENV_FILE"; { echo "DASH_USERHOST_RAW='${WANT_UH:-}'"; echo "DASH_MODE='${DASH_MODE:-lite}'"; echo "DASH_LAST_WRITE_EPOCH='$(date +%s)'"; } >"$ENV_FILE" 2>>"$LOG_FILE" || true; chown "$TARGET_USER":"$TARGET_USER" "$ENV_FILE" 2>>"$LOG_FILE" || true; }
strip_old_block(){ [ -f "$1" ] || return 0; grep -q "^$MARK$" "$1" >/dev/null 2>&1 && sed -i "/^$MARK$/,/^$MARK$/d" "$1" 2>>"$LOG_FILE" || true; }
dashboard_block(){ cat <<'EOF'
### TERMINAL_DASHBOARD_ACTIVE ###
if [[ $- == *i* ]]; then
  if [ -n "${DASHBOARD_EXECUTED:-}" ]; then return; fi
  export DASHBOARD_EXECUTED=1
  curtty="$(/usr/bin/tty 2>/dev/null || tty 2>/dev/null || echo unknown)"
  if [ -n "${DASHBOARD_TTY_SHOWN:-}" ] && [ "$DASHBOARD_TTY_SHOWN" = "$curtty" ]; then return; fi
  export DASHBOARD_TTY_SHOWN="$curtty"
  [ -f "$HOME/.terminal_dashboard.env" ] && . "$HOME/.terminal_dashboard.env"
  _has(){ command -v "$1" >/dev/null 2>&1; }
  _val(){ [ -n "$1" ] && printf "%s" "$1" || printf "-"; }
  printf '\033[2J\033[H'
  _pretty="Linux"
  [ -f /etc/os-release ] && . /etc/os-release 2>/dev/null && _pretty="${PRETTY_NAME:-Linux}"
  if [ -z "${DASHBOARD_LOGO_DONE:-}" ]; then
    if _has neofetch; then
      if [ "${DASH_MODE:-lite}" = "full" ]; then
        neofetch --ascii_distro ubuntu --ascii --disable packages shell resolution de wm theme icons terminal >/dev/null 2>&1 || true
      else
        neofetch --ascii_distro ubuntu_small --ascii --disable packages shell resolution de wm theme icons terminal >/dev/null 2>&1 || true
      fi
    else
      printf "\n"
      printf "DashTerm\n\n"
    fi
    export DASHBOARD_LOGO_DONE=1
  fi
  uh="${DASH_USERHOST_RAW:-$(whoami 2>/dev/null || echo -n '-')@$(hostname 2>/dev/null || echo -n '-')}"
  ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
  [ -z "$ip" ] && ip="$(ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for(i=1;i<=NF;i++) if($i=="src"){print $(i+1);break}}')"
  kern="$(uname -r 2>/dev/null)"
  bt="$(who -b 2>/dev/null | awk '{print $3, $4}')"
  [ -z "$bt" ] && bt="$(uptime -s 2>/dev/null)"
  up="$(uptime -p 2>/dev/null | sed 's/^up //')"
  cpu="$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d':' -f2 | sed 's/^ //')"
  [ -z "$cpu" ] && cpu="$(lscpu 2>/dev/null | awk -F: '/Model name/ {sub(/^ +/, "", $2); print $2; exit}')"
  cores="$(nproc 2>/dev/null)"
  ram="$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}')"
  disk="$(df -h / 2>/dev/null | awk 'NR==2 {printf "%s / %s", $3, $2}')"
  load="$(awk '{print $1","$2","$3}' /proc/loadavg 2>/dev/null)"
  dns="$(awk '/^nameserver/ {printf "%s ", $2}' /etc/resolv.conf 2>/dev/null | xargs)"
  virt_final=""; virt_vendor=""; virt_type=""; virt_flags=""
  _has systemd-detect-virt && vdet="$(systemd-detect-virt 2>/dev/null || true)" && [ "$vdet" != "none" ] && virt_final="$vdet"
  grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null && virt_final="${virt_final:+$virt_final+}WSL"
  [ -f /.dockerenv ] && virt_final="${virt_final:+$virt_final+}Docker"
  grep -qaE 'lxc|container' /proc/1/cgroup 2>/dev/null && virt_final="${virt_final:+$virt_final+}LXC"
  lscpu_info="$(lscpu 2>/dev/null || true)"
  [ -n "$lscpu_info" ] && virt_vendor="$(printf "%s" "$lscpu_info" | awk -F: '/Hypervisor vendor/ {gsub(/^ +/, "", $2); print $2; exit}')" && virt_type="$(printf "%s" "$lscpu_info" | awk -F: '/Virtualization type/ {gsub(/^ +/, "", $2); print $2; exit}')"
  _has dmidecode && { dmi_manu="$(dmidecode -s system-manufacturer 2>/dev/null | tr -d '\r')"; dmi_prod="$(dmidecode -s system-product-name 2>/dev/null | tr -d '\r')"; case "$dmi_manu $dmi_prod" in *KVM*|*QEMU*) virt_vendor="KVM/QEMU" ;; *VMware*) virt_vendor="VMware" ;; *VirtualBox*) virt_vendor="VirtualBox" ;; *Microsoft*) virt_vendor="${virt_vendor:-Microsoft}" ;; *Xen*) virt_vendor="Xen" ;; esac; }
  flags="$(awk -F: '/flags/ {print $2; exit}' /proc/cpuinfo 2>/dev/null)"
  echo "$flags" | grep -qw vmx && virt_flags="VT-x"
  echo "$flags" | grep -qw svm && virt_flags="${virt_flags:+$virt_flags, }AMD-V"
  [ -e /dev/kvm ] && virt_flags="${virt_flags:+$virt_flags, }/dev/kvm"
  build_virt="${virt_final:+$virt_final | }${virt_vendor:+$virt_vendor | }${virt_type:-}"
  [ -z "$build_virt" ] && build_virt="Unknown / Possibly Physical"
  [ -n "$virt_flags" ] && build_virt="$build_virt ($virt_flags)"
  _has lspci && gpu="$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -1 | cut -d':' -f3- | sed 's/^ //')"
  now="$(date '+%A, %d %B %Y - %H:%M:%S')"
  if [ -z "${DASHBOARD_INFO_DONE:-}" ]; then
    echo "========================================"
    echo "User@Host     : $(_val "$uh")"
    echo "OS            : $(_val "$_pretty")"
    echo "Kernel        : $(_val "$kern")"
    echo "Virtualization: $(_val "$build_virt")"
    echo "Login Time    : $now"
    echo "Boot Time     : $(_val "$bt")"
    echo "Uptime        : $(_val "$up")"
    echo "IP Address    : $(_val "$ip")"
    echo "CPU Model     : $(_val "$cpu")"
    echo "CPU Cores     : $(_val "$cores")"
    echo "GPU           : $(_val "$gpu")"
    echo "RAM Total     : $(_val "$ram")"
    echo "Disk Used     : $(_val "$disk")"
    echo "Load Average  : $(_val "$load")"
    echo "DNS Servers   : $(_val "$dns")"
    echo "========================================"
    export DASHBOARD_INFO_DONE=1
  fi
fi
### TERMINAL_DASHBOARD_ACTIVE ###
EOF
}
atomic_append_block(){ local rc="$1"; local content="$2"; local tmp; tmp="$(mktemp)"; cat "$rc" > "$tmp" 2>>"$LOG_FILE" || true; printf "%s\n" "$content" >> "$tmp"; cp -f "$rc" "${rc}.backup" 2>>"$LOG_FILE" || true; mv -f "$tmp" "$rc" 2>>"$LOG_FILE" || true; chown "$TARGET_USER":"$TARGET_USER" "$rc" 2>>"$LOG_FILE" || true; }
apply_to_rc(){ [ -f "$1" ] || return 0; strip_old_block "$1"; local block; block="$(dashboard_block)"; atomic_append_block "$1" "$block"; grep -q "^$MARK$" "$1" >/dev/null 2>&1 || atomic_append_block "$1" "$block"; }
restart_shell(){ if [ -n "${DASHTERM_RESTARTED:-}" ]; then ok "Selesai"; return 0; fi; export DASHTERM_RESTARTED=1; say "Memuat ulang terminal"; sleep 1; local comm; comm="$(cat /proc/$$/comm 2>/dev/null || echo "")"; case "$comm" in zsh) exec zsh -l ;; bash|"") exec bash -l ;; *) exec "${SHELL:-/bin/bash}" -l ;; esac; }
{
  flock -n 9 || { warn "Proses lain sedang berjalan"; exit 0; }
  say "DashTerm Installer v10"
  install_deps
  say ""
  say "Mode interaktif"
  say "-------------"
  choose_mode
  ensure_file "$BASHRC"
  ensure_file "$ZSHRC"
  ask_userhost
  say "Menulis blok dashboard"
  apply_to_rc "$BASHRC"
  apply_to_rc "$ZSHRC"
  ok "Instalasi selesai"
  restart_shell
} 9>"$LOCK_FILE"
```0
