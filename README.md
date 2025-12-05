dasterm v12 Interactive

> The ultimate interactive terminal dashboard — intelligent, elegant, adaptive, and real-time.

Built for developers who love beauty, clarity, and performance ⚙️

---

✨ What's New in v12

- 🎯 dasterm by aka — new official name and branding
- 🎮 Full Interactive Wizard — mode selection, custom User@Host, colors, and display settings
- 🔁 Reconfigure & Uninstall — run installer again to modify or remove everything cleanly
- 🎨 Pastel Color Theme — optional aesthetic pastel color scheme
- 🧩 Root@Aka — automatic alias for root users (customizable)
- 🖼️ Native Neofetch Logo — auto-detects your OS and shows the correct ASCII logo (works on rare Linux distros too)
- 📊 Rich Data Display — 15+ lines of real system info, all with fallbacks (no "not found")
- ⏎ Press Enter to Reload — installation ends with a clear message and manual reload trigger
- 🧹 Auto Cleanup — lock and log files are removed automatically after success
- 🛡️ Race Condition Safe — file locking prevents simultaneous installations

---

📦 Installation

Run this one-liner in your terminal:

```bash
bash <(curl -s https://raw.githubusercontent.com/akaanakbaik/dasterm/main/install.sh)
```

---

🧩 During Installation

You'll be guided through an interactive setup:

```
╔══════════════════════════════════════════════════════════════╗
║                    dasterm by aka                           ║
║          Interactive Terminal Dashboard Installer            ║
╚══════════════════════════════════════════════════════════════╝

ℹ PILIH MODE DASHBOARD
1) FULL – logo besar, info lengkap
2) LITE – logo kecil, info ringkas (default)
➡️  Pilihan [1/2]:

ℹ CUSTOM USER@HOST
Masukkan User@Host (Enter='root@ubuntu'):
➡️  User@Host:

ℹ ✨ Kamu root! Default akan jadi root@aka
Ganti 'aka' dengan nama custom (Enter=aka):
➡️  Nama alias:

ℹ KONFIGURASI TAMBAHAN
Gunakan warna pastel? [Y/n]:
Tampilkan setiap login? [Y/n]:
```

All preferences are saved to `~/.dasterm.env`.

---

🖥 Example Output

Below is a real preview of Full Mode with pastel colors:

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

╔══════════════════════════════════════════════════════╗
║  User@Host     : root@aka                            ║
║  OS            : Ubuntu 22.04.5 LTS                  ║
║  Kernel        : 6.8.0-45-generic                    ║
║  Architecture  : x86_64                              ║
║  Virtualization: KVM (VT-x)                          ║
║  Boot Time     : 2025-11-04 10:05                    ║
║  Uptime        : 4 hours, 27 minutes                 ║
║  Load Average  : 0.12, 0.09, 0.05                    ║
║  IP Address    : 167.71.xxx.xxx                      ║
║  CPU Model     : Intel(R) Xeon(R) CPU E5-2680 v4     ║
║  CPU Cores     : 4 cores                             ║
║  CPU Flags     : vmx aes                             ║
║  RAM Total     : 8G                                  ║
║  RAM Used      : 2.1G (26.3%)                        ║
║  Disk Root     : 5.3G used of 25G (21%)              ║
║  GPU           : Red Hat, Inc. QXL paravirtual GPU   ║
║  DNS Servers   : 1.1.1.1 8.8.8.8                     ║
║  Processes     : 127 running                         ║
║  Users         : 1 logged in                         ║
╚══════════════════════════════════════════════════════╝
```

---

🔄 Reconfigure or Uninstall

Run the installer again anytime:

```bash
bash <(curl -s https://raw.githubusercontent.com/akaanakbaik/dasterm/main/install.sh)
```

Then choose:
- 1) Reconfigure — change mode, colors, or User@Host
- 2) Uninstall — completely remove dasterm from your system

---

💡 Supported Systems

✅ Ubuntu / Debian / Linux Mint

✅ Fedora / CentOS / RHEL / Rocky Linux

✅ Arch / Manjaro / EndeavourOS

✅ openSUSE / SUSE Linux

✅ Alpine Linux

✅ WSL / Docker / LXC / KVM / QEMU / VMware

✅ All Linux distributions with Neofetch support (logo auto-detected)  

---

🧑‍💻 Author

aka

📧 [akaanakbaik17@proton.me](mailto:akaanakbaik17@proton.me)

🌐 [https://github.com/akaanakbaik](https://github.com/akaanakbaik)

---

⚡ Project

Repository: [github.com/akaanakbaik/dasterm](https://github.com/akaanakbaik/dasterm)

---

💖 License

Licensed under the MIT License — free for everyone to use, modify, and improve.

Made with ❤️ by aka.
