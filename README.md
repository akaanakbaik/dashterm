#  DashTerm v8 — Interactive & Intelligent Terminal Dashboard

> The ultimate **interactive terminal dashboard** — intelligent, elegant, adaptive, and real-time.  
> Built for developers who love beauty, clarity, and performance ⚙️

---

### ✨ What's New in v8

- 🧠 **Interactive Mode Selection** — choose between:
  - 🧱 **Full Mode:** large and detailed ASCII logo.
  - ⚡ **Lite Mode:** small and fast logo, perfect for minimal terminals.
- 🔍 **Auto System Detection** — detects your virtualization (KVM, QEMU, VMware, Docker, WSL, etc.)
- 🧩 **Self-Healing Installer** — automatically repairs missing dependencies.
- 🌐 **Real-Time Dashboard** — refreshes every time your terminal starts.
- 🎨 **Beautiful Output** — clean design with emoji-based visual separation.
- 🔁 **Auto Shell Reload** — no need to relogin; the terminal restarts itself instantly.
- 🧮 **Error-Free Execution** — all commands have fallbacks (no “command not found”).

---

### 📦 Installation

Run this one-liner in your terminal:

```bash
bash <(curl -s https://raw.githubusercontent.com/akaanakbaik/dashterm/main/install.sh)
```

---

### 🧩 During Installation

You’ll be greeted with an interactive prompt:

```
🧩 Pilih mode tampilan Neofetch:
   [1] Full Logo (besar, detail)
   [2] Lite Logo (kecil, minimalis)
➡️  Pilihanmu [1/2]:
```

Then another prompt lets you **customize your User@Host display** (optional):

```
Masukkan tampilan User@Host yang diinginkan.
Contoh: root@aka  (Enter untuk otomatis)
➡️  User@Host:
```

Your preferences are stored automatically in `~/.terminal_dashboard.env`.

---

### 🖥 Example Output

Below is a real preview of the Lite Mode (Neofetch small ASCII logo):

```
            .-/+oossssoo+/-.              
        `:+ssssssssssssssssss+:`          
      -+ssssssssssssssssssyyssss+-        
    .ossssssssssssssssssdMMMNysssso.      
   /ssssssssssshdmmNNmmyNMMMMhssssss/     
  +ssssssssshmydMMMMMMMNddddyssssssss+    
 /sssssssshNMMMyhhyyyyhmNMMMNhssssssss/   
.ssssssssdMMMNhsssssssssshNMMMdssssssss.  
+sssshhhyNMMNyssssssssssssyNMMMysssssss+  
ossyNMMMNyMMhsssssssssssssshmmmhssssssso  
ossyNMMMNyMMhsssssssssssssshmmmhssssssso  
+sssshhhyNMMNyssssssssssssyNMMMysssssss+  
.ssssssssdMMMNhsssssssssshNMMMdssssssss.  
 /sssssssshNMMMyhhyyyyhdNMMMNhssssssss/   
  +sssssssssdmydMMMMMMMMddddyssssssss+    
   /ssssssssssshdmNNNNmyNMMMMhssssss/     
    .ossssssssssssssssssdMMMNysssso.      
      -+ssssssssssssssssssyyssss+-        
        `:+ssssssssssssssssss+:`          
            .-/+oossssoo+/-.              

========================================
💻  User@Host     : root@aka
🪟  OS            : Ubuntu 22.04.5 LTS
🔧  Kernel        : 6.8.0-45-generic
🧠  Virtualization: KVM (VT-x)
🕓  Login Time    : Tuesday, 04 November 2025 - 14:32:01
⏰  Boot Time     : 2025-11-04 10:05
📈  Uptime        : 4 hours, 27 minutes
🌐  IP Address    : 167.71.xxx.xxx
⚙️  CPU Model     : Intel(R) Xeon(R) CPU E5-2680 v4 @ 2.40GHz
💪  CPU Cores     : 4
🎨  GPU           : QXL / virtio GPU
🧮  RAM Total     : 8G
💾  Disk Used     : 5.3G / 25G
📊  Load Average  : 0.12,0.09,0.05
🧭  DNS Servers   : 1.1.1.1 8.8.8.8
========================================
```

---

### 💡 Supported Systems

✅ Ubuntu / Debian  
✅ Fedora / CentOS / RHEL  
✅ Arch / Manjaro  
✅ openSUSE  
✅ Alpine  
✅ WSL / Docker / KVM / QEMU  

---

### 🧑‍💻 Author

**aka**  
📧 [akaanakbaik17@proton.me](mailto:akaanakbaik17@proton.me)  
🌐 [https://github.com/akaanakbaik](https://github.com/akaanakbaik)

---

### ⚡ Project

**Repository:** [github.com/akaanakbaik/dashterm](https://github.com/akaanakbaik/dashterm)

---

### 💖 License

Licensed under the **MIT License** — free for everyone to use, modify, and improve.  
Made with ❤️ by **aka**.
