#!/usr/bin/env bash
set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6 2>/dev/null || echo "$HOME")"
ENV_FILE="$TARGET_HOME/.terminal_dashboard.env"
MARK="### TERMINAL_DASHBOARD_ACTIVE ###"
BASHRC="$TARGET_HOME/.bashrc"
ZSHRC="$TARGET_HOME/.zshrc"

say(){ printf "%b\n" "$1"; }
spin(){ local pid=$!; local spin='🌑🌒🌓🌔🌕🌖🌗🌘'; local i=0; while kill -0 $pid 2>/dev/null; do i=$(((i+1)%8)); printf "\r${spin:$i:1}"; sleep 0.1; done; printf "\r"; }

ensure_file(){ [ -f "$1" ] || { touch "$1"; chown "$TARGET_USER":"$TARGET_USER" "$1" || true; }; }
strip_old_block(){ [ -f "$1" ] && grep -q "^$MARK$" "$1" && sed -i "/^$MARK$/,/^$MARK$/d" "$1" || true; }
atomic_append_block(){ local rc="$1"; local tmp; tmp="$(mktemp)"; cat "$rc" >"$tmp"; printf "%s\n" "$2" >>"$tmp"; cp -f "$rc" "${rc}.backup" 2>/dev/null || true; mv -f "$tmp" "$rc"; chown "$TARGET_USER":"$TARGET_USER" "$rc" || true; }

detect_pkgmgr(){ for i in apt dnf yum pacman zypper apk; do command -v $i >/dev/null 2>&1 && echo $i && return; done; echo none; }

install_deps(){
  say "⚙️  Memeriksa dependensi..."
  local pkgs=(neofetch pciutils dmidecode iproute2 coreutils procps grep awk sed lsb-release)
  local mgr; mgr="$(detect_pkgmgr)"
  (
    case "$mgr" in
      apt) sudo apt-get update -qq && sudo apt-get install -y "${pkgs[@]}" >/dev/null 2>&1 ;;
      dnf) sudo dnf install -y "${pkgs[@]}" >/dev/null 2>&1 ;;
      yum) sudo yum install -y epel-release >/dev/null 2>&1 || true; sudo yum install -y "${pkgs[@]}" >/dev/null 2>&1 ;;
      pacman) sudo pacman -Sy --noconfirm "${pkgs[@]}" >/dev/null 2>&1 ;;
      zypper) sudo zypper -n install "${pkgs[@]}" >/dev/null 2>&1 ;;
      apk) sudo apk add --no-cache "${pkgs[@]}" >/dev/null 2>&1 ;;
      *) say "⚠️  Paket manager tidak dikenal — melewati instalasi otomatis."; ;
    esac
  ) & spin
  say "✅  Dependensi siap."
}

choose_mode(){
  say ""
  say "🧩 Pilih mode tampilan Neofetch:"
  say "   [1] Full Logo (besar, detail)"
  say "   [2] Lite Logo (kecil, minimalis)"
  read -rp "➡️  Pilihanmu [1/2]: " mode_input || true
  case "$mode_input" in
    1) DASH_MODE="full" ;;
    2) DASH_MODE="lite" ;;
    *) DASH_MODE="lite" ;;
  esac
}

ask_userhost(){
  say "Masukkan tampilan User@Host yang diinginkan."
  say "Contoh: root@aka  (Enter untuk otomatis)"
  read -r -p "➡️  User@Host: " WANT_UH || true
  if [ -n "${WANT_UH:-}" ] && ! printf "%s" "$WANT_UH" | grep -q "@"; then
    WANT_UH="$(whoami 2>/dev/null || echo "$TARGET_USER")@$WANT_UH"
  fi
  ensure_file "$ENV_FILE"
  {
    echo "DASH_USERHOST_RAW='${WANT_UH:-}'"
    echo "DASH_MODE='${DASH_MODE:-lite}'"
    echo "DASH_LAST_WRITE_EPOCH='$(date +%s)'"
  } >"$ENV_FILE"
  chown "$TARGET_USER":"$TARGET_USER" "$ENV_FILE" || true
}

dashboard_block(){
cat <<'EOF'
### TERMINAL_DASHBOARD_ACTIVE ###
if [[ $- == *i* ]] && [[ -z "${DASHBOARD_EXECUTED:-}" ]]; then
  export DASHBOARD_EXECUTED=1
  [ -f "$HOME/.terminal_dashboard.env" ] && . "$HOME/.terminal_dashboard.env"
  _has(){ command -v "$1" >/dev/null 2>&1; }
  _val(){ [ -n "$1" ] && printf "%s" "$1" || printf "-"; }
  printf '\033[2J\033[H'
  _pretty="Linux"
  [ -f /etc/os-release ] && . /etc/os-release 2>/dev/null && _pretty="${PRETTY_NAME:-Linux}"
  if _has neofetch; then
    if [ "${DASH_MODE:-lite}" = "full" ]; then
      neofetch --ascii_distro ubuntu --ascii --disable packages shell resolution de wm theme icons terminal >/dev/null 2>&1 || true
    else
      neofetch --ascii_distro ubuntu_small --ascii --disable packages shell resolution de wm theme icons terminal >/dev/null 2>&1 || true
    fi
  fi
  uh="${DASH_USERHOST_RAW:-$(whoami)@$(hostname)}"
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
  _has dmidecode && { dmi_manu="$(dmidecode -s system-manufacturer 2>/dev/null | tr -d '\r')"; dmi_prod="$(dmidecode -s system-product-name 2>/dev/null | tr -d '\r')"; case "$dmi_manu $dmi_prod" in *KVM*|*QEMU*) virt_vendor="KVM/QEMU";; *VMware*) virt_vendor="VMware";; *VirtualBox*) virt_vendor="VirtualBox";; *Microsoft*) virt_vendor="${virt_vendor:-Microsoft}";; *Xen*) virt_vendor="Xen";; esac; }
  flags="$(awk -F: '/flags/ {print $2; exit}' /proc/cpuinfo 2>/dev/null)"
  echo "$flags" | grep -qw vmx && virt_flags="VT-x"
  echo "$flags" | grep -qw svm && virt_flags="${virt_flags:+$virt_flags, }AMD-V"
  [ -e /dev/kvm ] && virt_flags="${virt_flags:+$virt_flags, }/dev/kvm"
  build_virt="${virt_final:+$virt_final | }${virt_vendor:+$virt_vendor | }${virt_type:-}"
  [ -z "$build_virt" ] && build_virt="Unknown / Possibly Physical"
  [ -n "$virt_flags" ] && build_virt="$build_virt ($virt_flags)"
  _has lspci && gpu="$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -1 | cut -d':' -f3- | sed 's/^ //')"
  now="$(date '+%A, %d %B %Y - %H:%M:%S')"
  echo "========================================"
  echo "💻  User@Host     : $(_val \"$uh\")"
  echo "🪟  OS            : $(_val \"$_pretty\")"
  echo "🔧  Kernel        : $(_val \"$kern\")"
  echo "🧠  Virtualization: $(_val \"$build_virt\")"
  echo "🕓  Login Time    : $now"
  echo "⏰  Boot Time     : $(_val \"$bt\")"
  echo "📈  Uptime        : $(_val \"$up\")"
  echo "🌐  IP Address    : $(_val \"$ip\")"
  echo "⚙️  CPU Model     : $(_val \"$cpu\")"
  echo "💪  CPU Cores     : $(_val \"$cores\")"
  echo "🎨  GPU           : $(_val \"$gpu\")"
  echo "🧮  RAM Total     : $(_val \"$ram\")"
  echo "💾  Disk Used     : $(_val \"$disk\")"
  echo "📊  Load Average  : $(_val \"$load\")"
  echo "🧭  DNS Servers   : $(_val \"$dns\")"
  echo "========================================"
fi
### TERMINAL_DASHBOARD_ACTIVE ###
EOF
}

apply_to_rc(){ [ -f "$1" ] || return 0; strip_old_block "$1"; local block; block="$(dashboard_block)"; atomic_append_block "$1" "$block"; }

restart_shell(){
  say "🔄  Memuat ulang terminal..."
  sleep 1
  local comm; comm="$(cat /proc/$$/comm 2>/dev/null || echo "")"
  case "$comm" in
    zsh) exec zsh -l ;;
    bash|"") exec bash -l ;;
    *) exec "$SHELL" -l ;;
  esac
}

say "🌈  === DashTerm Installer (v8) ==="
install_deps
choose_mode
ensure_file "$BASHRC"
ensure_file "$ZSHRC"
say "🧩  Mengatur User@Host..."
ask_userhost
say "🪄  Menulis blok dashboard ke RC…
✅  Mulai!"
apply_to_rc "$BASHRC"
apply_to_rc "$ZSHRC"
say "✅  Instalasi selesai! Dashboard siap digunakan 🚀"
restart_shell
