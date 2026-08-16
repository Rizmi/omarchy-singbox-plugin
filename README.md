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

> **Important:** After installing, make sure to follow the **[Initial System Setup](#initial-system-setup)** section below to configure required permissions and file access.

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

3. Follow the **[Initial System Setup](#initial-system-setup)** section below to complete configuration.

---

## Removal

```bash
omarchy plugin disable io.github.rizmi.singbox-vpn
rm -rf ~/.config/omarchy/plugins/io.github.rizmi.singbox-vpn
omarchy-shell shell rescanPlugins
```

---

## Initial System Setup

To allow the widget to start/stop the proxy and switch configs seamlessly without asking for root passwords each time, run these two quick setup steps once:

### 1. Polkit Rule (Passwordless Service Control)
Allow members of the `wheel` group to manage `sing-box.service` without entering a password:

```bash
sudo bash -c 'cat << "EOF" > /etc/polkit-1/rules.d/50-sing-box.rules
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "sing-box.service" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF
chmod 644 /etc/polkit-1/rules.d/50-sing-box.rules'
```

### 2. Configuration File Write Access
Allow your user to update the sing-box configuration without full ownership of the system directory:

```bash
sudo mkdir -p /etc/sing-box
sudo touch /etc/sing-box/config.json
sudo chmod 664 /etc/sing-box/config.json
sudo chgrp wheel /etc/sing-box /etc/sing-box/config.json
sudo chmod 775 /etc/sing-box
```

> **Note:** The directory and config file are group-writable by `wheel` (your admin group). The sing-box service reads the config as root, so no ownership change to your user is needed. Your user account must be a member of the `wheel` group (standard on Omarchy/Arch).

### 3. Firewall Configuration (If using UFW)
If you have **UFW firewall** enabled, allow bridged traffic on the `tun0` adapter so your proxy connection is not blocked:

```bash
sudo ufw allow in on tun0
sudo ufw allow out on tun0
sudo ufw route allow in on tun0
sudo ufw route allow out on tun0
sudo ufw reload
```

---

## Managing Proxy Nodes & Profiles

You can add and manage proxy servers in two ways:

1. **Directly in the Popup Panel (Recommended)**:
   * Open the widget panel from your status bar.
   * Click **Add VLESS Node**.
   * Paste any `vless://...` link and click **Import & Apply**.

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
      "name": "Singapore Fiber Node",
      "type": "vless",
      "server": "sg1.example.com",
      "server_port": 444,
      "uuid": "00000000-0000-0000-0000-000000000000",
      "security": "tls",
      "sni": "zoom.us",
      "insecure": true
    }
  ]
}
```

### Profile Options Reference

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | string | Unique identifier for the profile. |
| `name` | string | Display label shown in the bar widget dropdown. |
| `type` | string | Protocol type (e.g. `"vless"`). |
| `server` | string | Server domain name or IP address. |
| `server_port` | integer | Port number (e.g. `443`, `444`). |
| `uuid` | string | Client UUID. |
| `security` | string | `"tls"` or `"none"`. |
| `sni` | string | Server Name Indication (SNI). |
| `insecure` | boolean | Set `true` if using self-signed certs / allow insecure TLS. |

---

## Security Notes

* **Credential protection**: VLESS credentials and configuration data are passed to subprocesses via environment variables rather than command-line arguments. This prevents exposure through local process inspection (`/proc/<pid>/cmdline`).
* **Profile file permissions**: The profiles file (`~/.config/sing-box/profiles.json`) is written with mode `600` (owner read/write only) to protect stored credentials.
* **System config access**: The `/etc/sing-box/config.json` file is group-writable by `wheel` rather than user-owned, limiting write access to admin group members only.

---

## Usage

* **Left-click** bar icon: Open / close popup panel.
* **Right-click** bar icon: Force refresh status & public IP.
* **Middle-click** bar icon: Quick toggle connect / disconnect.
* **Popup Panel**:
  * **Power Switch**: Start / stop the sing-box TUN service.
  * **Public IP Row**: View current IP or click the refresh button to re-fetch.
  * **Server Node**: Select active node (automatically applies and reloads).
  * **Add VLESS Node**: Expandable section to paste and import any `vless://` link directly from the panel.

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
  * Ensure UFW firewall has `tun0` allowed (`sudo ufw allow in on tun0 && sudo ufw allow out on tun0`).
  * Check if your VLESS server domain resolves properly (`ping <server-domain>`).
  * If using self-signed or expired certificates, ensure `allowInsecure: true` is enabled in the profile.
  * Check live service logs: `journalctl -u sing-box -f`.

---

## File Structure

```
~/.config/omarchy/plugins/io.github.rizmi.singbox-vpn/
├── Panel.qml        # QML widget UI, popup panel & IPC handler
├── Service.qml      # Background service logic & process manager
├── Model.js         # Configuration parser and serializer
├── manifest.json    # Omarchy plugin manifest and settings schema
├── README.md        # Documentation and usage guide
└── LICENSE          # MIT License
```

---

## License

MIT — see [LICENSE](LICENSE).
