.import "ParseVless.js" as Vless
.import "ParseVmess.js" as Vmess
.import "ParseTrojan.js" as Trojan
.import "ParseShadowsocks.js" as Shadowsocks
.import "ParseHysteria2.js" as Hysteria2

function parseJson(str) {
  try {
    return JSON.parse(str);
  } catch (e) {
    return null;
  }
}

// Universal link parser — detects protocol from URI scheme
function parseNodeLink(link) {
  link = String(link || "").trim();
  if (link.startsWith("vless://"))     return Vless.parseVless(link);
  if (link.startsWith("vmess://"))     return Vmess.parseVmess(link);
  if (link.startsWith("trojan://"))    return Trojan.parseTrojan(link);
  if (link.startsWith("ss://"))        return Shadowsocks.parseShadowsocks(link);
  if (link.startsWith("hy2://"))       return Hysteria2.parseHysteria2(link);
  if (link.startsWith("hysteria2://")) return Hysteria2.parseHysteria2(link);
  return null;
}

// Keep backward compat
function parseVless(link) { return Vless.parseVless(link); }

function buildOutbound(profile) {
  if (!profile) return null;
  var type = profile.type || "vless";

  if (type === "vless") {
    var ob = {
      "type": "vless",
      "tag": "proxy",
      "server": profile.server,
      "server_port": profile.server_port || 443,
      "uuid": profile.uuid,
      "domain_resolver": "local-dns"
    };
    if (profile.security === "tls" || profile.security === "reality" || profile.sni) {
      ob.tls = { "enabled": true, "server_name": profile.sni || profile.server, "insecure": !!profile.insecure };
    }
    if (profile.flow) ob.flow = profile.flow;
    return ob;
  }

  if (type === "vmess") {
    var ob = {
      "type": "vmess",
      "tag": "proxy",
      "server": profile.server,
      "server_port": profile.server_port || 443,
      "uuid": profile.uuid,
      "security": profile.security || "auto",
      "alter_id": profile.alterId || 0,
      "domain_resolver": "local-dns"
    };
    if (profile.tls) {
      ob.tls = { "enabled": true, "server_name": profile.sni || profile.server, "insecure": !!profile.insecure };
    }
    if (profile.transport === "ws") {
      ob.transport = { "type": "ws" };
      if (profile.wsPath) ob.transport.path = profile.wsPath;
      if (profile.wsHost) ob.transport.headers = { "Host": profile.wsHost };
    } else if (profile.transport === "grpc") {
      ob.transport = { "type": "grpc" };
      if (profile.grpcServiceName) ob.transport.service_name = profile.grpcServiceName;
    } else if (profile.transport === "h2" || profile.transport === "http") {
      ob.transport = { "type": "http" };
      if (profile.h2Host) ob.transport.host = [profile.h2Host];
      if (profile.h2Path) ob.transport.path = profile.h2Path;
    }
    return ob;
  }

  if (type === "trojan") {
    var ob = {
      "type": "trojan",
      "tag": "proxy",
      "server": profile.server,
      "server_port": profile.server_port || 443,
      "password": profile.password,
      "domain_resolver": "local-dns",
      "tls": {
        "enabled": true,
        "server_name": profile.sni || profile.server,
        "insecure": !!profile.insecure
      }
    };
    return ob;
  }

  if (type === "shadowsocks") {
    var ob = {
      "type": "shadowsocks",
      "tag": "proxy",
      "server": profile.server,
      "server_port": profile.server_port || 8388,
      "method": profile.method,
      "password": profile.password,
      "domain_resolver": "local-dns"
    };
    return ob;
  }

  if (type === "hysteria2") {
    var ob = {
      "type": "hysteria2",
      "tag": "proxy",
      "server": profile.server,
      "server_port": profile.server_port || 443,
      "password": profile.password,
      "domain_resolver": "local-dns",
      "tls": {
        "enabled": true,
        "server_name": profile.sni || profile.server,
        "insecure": !!profile.insecure
      }
    };
    if (profile.obfs) {
      ob.obfs = { "type": profile.obfs };
      if (profile.obfsPassword) ob.obfs.password = profile.obfsPassword;
    }
    return ob;
  }

  return null;
}

function buildSingBoxConfig(profile) {
  var outbound = buildOutbound(profile);
  if (!outbound) return "{}";

  var config = {
    "log": {
      "level": "warn"
    },
    "dns": {
      "servers": [
        {
          "tag": "remote-dns",
          "type": "tcp",
          "server": "8.8.8.8",
          "detour": "proxy"
        },
        {
          "tag": "local-dns",
          "type": "local",
          "detour": "direct"
        }
      ],
      "final": "remote-dns",
      "strategy": "ipv4_only"
    },
    "inbounds": [
      {
        "type": "tun",
        "tag": "tun-in",
        "address": [
          "172.19.0.1/30"
        ],
        "auto_route": true,
        "strict_route": true,
        "stack": "system"
      }
    ],
    "outbounds": [
      outbound,
      {
        "type": "direct",
        "tag": "direct"
      },
      {
        "type": "block",
        "tag": "block"
      }
    ],
    "route": {
      "auto_detect_interface": true,
      "default_domain_resolver": "local-dns",
      "rules": [
        {
          "action": "sniff"
        },
        {
          "protocol": "dns",
          "action": "hijack-dns"
        },
        {
          "port": 53,
          "action": "hijack-dns"
        },
        {
          "ip_cidr": [
            "172.19.0.0/30",
            "127.0.0.0/8"
          ],
          "outbound": "block"
        },
        {
          "network": "icmp",
          "outbound": "direct"
        },
        {
          "ip_is_private": true,
          "outbound": "direct"
        }
      ]
    }
  };

  return JSON.stringify(config, null, 2);
}

function defaultProfiles() {
  return [
    {
      "id": "sample-node-1",
      "name": "Sample Server 1",
      "type": "vless",
      "server": "server.example.com",
      "server_port": 443,
      "uuid": "00000000-0000-0000-0000-000000000000",
      "security": "tls",
      "sni": "server.example.com",
      "insecure": false
    }
  ];
}
