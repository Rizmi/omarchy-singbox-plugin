// VMess link parser: vmess://base64json
// Standard V2Ray VMess share format (Base64-encoded JSON)
function parseVmess(link) {
  link = String(link || "").trim();
  if (!link.startsWith("vmess://")) return null;
  var b64 = link.substring(8);
  var json;
  try {
    json = JSON.parse(Qt.atob(b64));
  } catch(e) {
    return null;
  }
  if (!json || !json.add || !json.id) return null;

  var server = String(json.add);
  var port = parseInt(json.port, 10) || 443;
  var uuid = String(json.id);
  var alterId = parseInt(json.aid, 10) || 0;
  var tag = String(json.ps || json.remark || (server + ":" + port));
  var net = String(json.net || "tcp");
  var tls = String(json.tls || "");
  var sni = String(json.sni || json.host || server);
  var host = String(json.host || "");
  var path = String(json.path || "");

  var profile = {
    id: uuid.substring(0, 8) + "@" + server + ":" + port,
    name: tag,
    type: "vmess",
    server: server,
    server_port: port,
    uuid: uuid,
    alterId: alterId,
    security: json.scy || "auto",
    sni: sni,
    insecure: false,
    tls: tls === "tls",
    transport: net,
    raw: link
  };

  if (net === "ws") {
    profile.wsHost = host;
    profile.wsPath = path;
  } else if (net === "grpc") {
    profile.grpcServiceName = path;
  } else if (net === "h2" || net === "http") {
    profile.h2Host = host;
    profile.h2Path = path;
  }

  return profile;
}
