// VLESS link parser: vless://uuid@server:port?params#tag
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
