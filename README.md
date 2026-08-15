# sing-box VPN — Omarchy Bar Widget

A lightweight, modern, and native [Omarchy](https://omarchy.org/) status bar widget to control **sing-box** transparent proxy (TUN) connections directly from your desktop bar.

---

## Requirements & Prerequisites

Before installing the widget, ensure your system has:

1. **Omarchy Linux** with Quickshell status bar (`omarchy plugin` / `omarchy bar` CLI available).
2. **`sing-box`** installed:
   ```bash
   sudo pacman -S sing-box
   # or via Omarchy package helper:
   # omarchy pkg add sing-box
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
     ~/.config/omarchy/plugins/omarchy.singbox-vpn
   ```

2. Validate and enable the plugin on your status bar:
   ```bash
   omarchy plugin validate ~/.config/omarchy/plugins/omarchy.singbox-vpn
   omarchy plugin enable omarchy.singbox-vpn --section right
   ```

---

## Removal

```bash
omarchy plugin disable omarchy.singbox-vpn
rm -rf ~/.config/omarchy/plugins/omarchy.singbox-vpn
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

### 2. Configuration File Permissions
Allow your user to write the compiled sing-box configuration to `/etc/sing-box/`:

```bash
sudo mkdir -p /etc/sing-box
sudo chown -R $USER:sing-box /etc/sing-box
sudo chmod 775 /etc/sing-box
sudo touch /etc/sing-box/config.json
sudo chmod 664 /etc/sing-box/config.json
```

---

## Managing Proxy Nodes & Profiles

Your proxy profiles are saved in:
```
~/.config/omarchy/singbox-profiles.json
```

The widget automatically reads this file to populate the **SERVER NODE** dropdown.

### Example `singbox-profiles.json`

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

## Usage

* **Left-click** bar icon: Open / close popup panel.
* **Right-click** bar icon: Force refresh status & public IP.
* **Middle-click** bar icon: Quick toggle connect / disconnect.
* **Popup Panel**:
  * **Power Switch**: Start / stop the sing-box TUN service.
  * **Public IP Row**: View current IP or click the refresh button to re-fetch.
  * **Server Node**: Select active node (automatically applies and reloads).

---

## Shell IPC Commands

```bash
# Check status
omarchy-shell omarchy.singbox-vpn status

# Fetch current public IP
omarchy-shell omarchy.singbox-vpn ip

# Toggle VPN on / off
omarchy-shell omarchy.singbox-vpn toggle

# Refresh status and IP
omarchy-shell omarchy.singbox-vpn refresh
```

---

## File Structure

```
~/.config/omarchy/plugins/omarchy.singbox-vpn/
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
