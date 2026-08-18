// Hysteria 2 link parser: hy2://auth@server:port?params#tag
// Also accepts hysteria2:// scheme
function parseHysteria2(link) {
  link = String(link || "").trim();
  var scheme = "";
  if (link.startsWith("hy2://")) {
    scheme = "hy2://";
  } else if (link.startsWith("hysteria2://")) {
    scheme = "hysteria2://";
  } else {
    return null;
  }
  var withoutScheme = link.substring(scheme.length);
  var hashIdx = withoutScheme.indexOf("#");
  var tag = "Hysteria2 Node";
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
  var auth = withoutScheme.substring(0, atIdx);
  var hostPort = withoutScheme.substring(atIdx + 1);
  var colonIdx = hostPort.lastIndexOf(":");
  var server = colonIdx !== -1 ? hostPort.substring(0, colonIdx) : hostPort;
  var port = colonIdx !== -1 ? parseInt(hostPort.substring(colonIdx + 1), 10) : 443;

  return {
    id: auth.substring(0, 8) + "@" + server + ":" + port,
    name: tag || (server + ":" + port),
    type: "hysteria2",
    server: server,
    server_port: port,
    password: auth,
    sni: params.sni || params.peer || server,
    insecure: params.insecure === "1" || params.allowInsecure === "1",
    obfs: params.obfs || "",
    obfsPassword: params["obfs-password"] || "",
    raw: link
  };
}
