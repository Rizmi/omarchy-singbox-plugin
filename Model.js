function parseJson(str) {
  try {
    return JSON.parse(str);
  } catch (e) {
    return null;
  }
}

function parseVless(link) {
  link = String(link || "").trim();
  if (!link.startsWith("vless://")) return null;
  var withoutScheme = link.substring(8);
  var hashIdx = withoutScheme.indexOf("#");
  var tag = "VLESS Node";
  if (hashIdx !== -1) {
    try {
      tag = decodeURIComponent(withoutScheme.substring(hashIdx + 1));
    } catch(e) {
      tag = withoutScheme.substring(hashIdx + 1);
    }
    withoutScheme = withoutScheme.substring(0, hashIdx);
  }
  var queryIdx = withoutScheme.indexOf("?");
  var params = {};
  if (queryIdx !== -1) {
    var qs = withoutScheme.substring(queryIdx + 1);
    withoutScheme = withoutScheme.substring(0, queryIdx);
    var parts = qs.split("&");
    for (var i = 0; i < parts.length; i++) {
      var kv = parts[i].split("=");
      if (kv.length === 2) {
        params[decodeURIComponent(kv[0])] = decodeURIComponent(kv[1]);
      }
    }
  }
  var atIdx = withoutScheme.indexOf("@");
  if (atIdx === -1) return null;
  var uuid = withoutScheme.substring(0, atIdx);
  var hostPort = withoutScheme.substring(atIdx + 1);
  var colonIdx = hostPort.lastIndexOf(":");
  var server = colonIdx !== -1 ? hostPort.substring(0, colonIdx) : hostPort;
  var port = colonIdx !== -1 ? parseInt(hostPort.substring(colonIdx + 1), 10) : 443;

  return {
    id: uuid.substring(0, 8) + "@" + server + ":" + port,
    name: tag || (server + ":" + port),
    type: "vless",
    server: server,
    server_port: port,
    uuid: uuid,
    security: params.security || "none",
    sni: params.sni || server,
    insecure: params.allowInsecure === "true" || params.allowInsecure === "1",
    flow: params.flow || "",
    raw: link
  };
}

function buildSingBoxConfig(profile) {
  if (!profile) return "{}";
  var outbound = {
    "type": profile.type || "vless",
    "tag": "proxy",
    "server": profile.server,
    "server_port": profile.server_port || 443,
    "uuid": profile.uuid,
    "domain_resolver": "local-dns"
  };

  if (profile.security === "tls" || profile.security === "reality" || profile.sni) {
    outbound.tls = {
      "enabled": true,
      "server_name": profile.sni || profile.server,
      "insecure": !!profile.insecure
    };
  }

  if (profile.flow) {
    outbound.flow = profile.flow;
  }

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
        "strict_route": false,
        "stack": "mixed"
      }
    ],
    "outbounds": [
      outbound,
      {
        "type": "direct",
        "tag": "direct"
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
