# sing-box VPN — Omarchy Bar Widget

A lightweight, modern, and native [Omarchy](https://omarchy.org/) status bar widget to control **sing-box** transparent proxy (TUN) connections directly from your desktop bar.

---

## Requirements & Prerequisites

Before installing the widget, ensure your system has:

1. **Omarchy Linux** with Quickshell status bar (`omarchy plugin` / `omarchy bar` CLI available).
2. **`sing-box`** installed (available via AUR):
   ```bash
   yay -S sing-box
   # or using paru / another AUR helper:
   # paru -S sing-box
   ```
3. **`curl`** (standard on Omarchy, used for public IP detection via ipify / ifconfig.me).
4. **Linux Kernel TUN Module** (built into the default Arch Linux / Omarchy kernel).
5. **Nerd Font** (standard on Omarchy, used for status and action glyphs).

---

## Installation

### Option 1: Using `omarchy plugin` (Recommended)

```bash
omarchy plugin add https://github.com/Rizmi/omarchy-singbox-plugin.git --enable
```

### Option 2: Manual Installation

1. Clone the repository into your Omarchy plugins directory:
   ```bash
   git clone https://github.com/Rizmi/omarchy-singbox-plugin.git \
     ~/.config/omarchy/plugins/io.github.rizmi.singbox-vpn
   ```

2. Validate and enable the plugin on your status bar:
   ```bash
   omarchy plugin validate ~/.config/omarchy/plugins/io.github.rizmi.singbox-vpn
   omarchy plugin enable io.github.rizmi.singbox-vpn --section right
   ```

---

## Removal

```bash
omarchy plugin disable io.github.rizmi.singbox-vpn
rm -rf ~/.config/omarchy/plugins/io.github.rizmi.singbox-vpn
omarchy restart shell
```

---

## Firewall Configuration (If using UFW)

If you have **UFW firewall** enabled, allow incoming packets on the `tun0` adapter so returned web and DNS responses from the transparent proxy are not dropped:

```bash
sudo ufw allow in on tun0
sudo ufw reload
```

---

## Supported Protocols

| Protocol | Link Format | Example |
|---|---|---|
| VLESS | `vless://uuid@server:port?params#tag` | Reality, XTLS-Vision, WS |
| VMess | `vmess://base64json` | Standard V2Ray share format |
| Trojan | `trojan://password@server:port?params#tag` | TLS password-based proxy |
| Shadowsocks | `ss://base64(method:password)@server:port#tag` | SIP002 and legacy formats |
| Hysteria 2 | `hy2://auth@server:port?params#tag` | Also accepts `hysteria2://` |

---

## Managing Proxy Nodes & Profiles

You can add and manage proxy servers in two ways:

1. **Directly in the Popup Panel (Recommended)**:
   * Open the widget panel from your status bar.
   * Click **Add Node**.
   * Paste any supported protocol link and click **Import & Apply**.

2. **Editing `profiles.json`**:
   * Proxy profiles are saved at:
     ```
     ~/.config/sing-box/profiles.json
     ```
   * On first run, a default sample template is automatically created here for reference.

### Example `profiles.json`

```json
{
  "currentProfileId": "server-1",
  "profiles": [
    {
      "id": "server-1",
      "name": "US High-Speed VLESS",
      "type": "vless",
      "server": "us1.example.com",
      "server_port": 443,
      "uuid": "00000000-0000-0000-0000-000000000000",
      "security": "tls",
      "sni": "us1.example.com",
      "insecure": false
    },
    {
      "id": "server-2",
      "name": "Singapore VMess WS",
      "type": "vmess",
      "server": "sg1.example.com",
      "server_port": 443,
      "uuid": "00000000-0000-0000-0000-000000000000",
      "security": "auto",
      "tls": true,
      "transport": "ws",
      "wsPath": "/proxy"
    },
    {
      "id": "server-3",
      "name": "Tokyo Trojan",
      "type": "trojan",
      "server": "jp1.example.com",
      "server_port": 443,
      "password": "your-password",
      "sni": "jp1.example.com"
    }
  ]
}
```

---

## Security Notes

* **Credential protection**: Proxy credentials and configuration data are passed to subprocesses via environment variables rather than command-line arguments. This prevents exposure through local process inspection (`/proc/<pid>/cmdline`).
* **Profile file permissions**: The profiles file (`~/.config/sing-box/profiles.json`) is written with mode `600` (owner read/write only) to protect stored credentials.
* **System config access**: Configuration updates to `/etc/sing-box/config.json` are performed via `pkexec`, delegating authorization to the system's native Polkit agent. No insecure directory permissions are required.

---

## Usage

* **Left-click** bar icon: Open / close popup panel.
* **Right-click** bar icon: Force refresh status & public IP.
* **Middle-click** bar icon: Quick toggle connect / disconnect.
* **Popup Panel**:
  * **Power Switch**: Start / stop the sing-box TUN service.
  * **Public IP Row**: View current IP or click the refresh button to re-fetch.
  * **Server Node**: Select active node (automatically applies and reloads).
  * **Add Node**: Expandable section to paste and import any supported protocol link directly from the panel.

---

## Shell IPC Commands

```bash
# Check status
omarchy-shell io.github.rizmi.singbox-vpn status

# Fetch current public IP
omarchy-shell io.github.rizmi.singbox-vpn ip

# Toggle VPN on / off
omarchy-shell io.github.rizmi.singbox-vpn toggle

# Refresh status and IP
omarchy-shell io.github.rizmi.singbox-vpn refresh
```

---

## Troubleshooting
 
* **"Fetching IP..." or timeout on connection**:
  * Ensure UFW firewall allows `tun0` inbound traffic (`sudo ufw allow in on tun0 && sudo ufw reload`).
  * Check if your server domain resolves properly (`ping <server-domain>`).
  * If using self-signed or expired certificates, ensure `insecure: true` is enabled in the profile.
  * Check live service logs: `journalctl -u sing-box -f`.

---

## File Structure

```
~/.config/omarchy/plugins/io.github.rizmi.singbox-vpn/
├── Panel.qml              # QML widget UI, popup panel & IPC handler
├── Service.qml            # Background service logic & process manager
├── Model.js               # Universal parser dispatcher & config builder
├── ParseVless.js          # VLESS link parser
├── ParseVmess.js          # VMess link parser
├── ParseTrojan.js         # Trojan link parser
├── ParseShadowsocks.js    # Shadowsocks link parser (SIP002 + legacy)
├── ParseHysteria2.js      # Hysteria 2 link parser
├── manifest.json          # Omarchy plugin manifest and settings schema
├── README.md              # Documentation and usage guide
└── LICENSE                # MIT License
```

---

## License

MIT — see [LICENSE](LICENSE).
