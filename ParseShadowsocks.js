// Shadowsocks link parser
// Supports SIP002: ss://base64(method:password)@server:port#tag
// Supports legacy: ss://base64(method:password@server:port)#tag
function parseShadowsocks(link) {
  link = String(link || "").trim();
  if (!link.startsWith("ss://")) return null;
  var withoutScheme = link.substring(5);
  var hashIdx = withoutScheme.indexOf("#");
  var tag = "Shadowsocks Node";
  if (hashIdx !== -1) {
    try {
      tag = decodeURIComponent(withoutScheme.substring(hashIdx + 1));
    } catch(e) {
      tag = withoutScheme.substring(hashIdx + 1);
    }
    withoutScheme = withoutScheme.substring(0, hashIdx);
  }

  var method, password, server, port;

  var atIdx = withoutScheme.indexOf("@");
  if (atIdx !== -1) {
    // SIP002 format: base64(method:password)@server:port
    var userInfo;
    try {
      userInfo = Qt.atob(withoutScheme.substring(0, atIdx));
    } catch(e) {
      userInfo = withoutScheme.substring(0, atIdx);
    }
    var colonIdx = userInfo.indexOf(":");
    if (colonIdx === -1) return null;
    method = userInfo.substring(0, colonIdx);
    password = userInfo.substring(colonIdx + 1);
    var hostPort = withoutScheme.substring(atIdx + 1);
    var lastColon = hostPort.lastIndexOf(":");
    server = lastColon !== -1 ? hostPort.substring(0, lastColon) : hostPort;
    port = lastColon !== -1 ? parseInt(hostPort.substring(lastColon + 1), 10) : 8388;
  } else {
    // Legacy format: base64(method:password@server:port)
    var decoded;
    try {
      decoded = Qt.atob(withoutScheme);
    } catch(e) {
      return null;
    }
    var atDecoded = decoded.indexOf("@");
    if (atDecoded === -1) return null;
    var userPart = decoded.substring(0, atDecoded);
    var serverPart = decoded.substring(atDecoded + 1);
    var colonUser = userPart.indexOf(":");
    if (colonUser === -1) return null;
    method = userPart.substring(0, colonUser);
    password = userPart.substring(colonUser + 1);
    var lastColonServer = serverPart.lastIndexOf(":");
    server = lastColonServer !== -1 ? serverPart.substring(0, lastColonServer) : serverPart;
    port = lastColonServer !== -1 ? parseInt(serverPart.substring(lastColonServer + 1), 10) : 8388;
  }

  if (!server || !method || !password) return null;

  return {
    id: method.substring(0, 6) + "@" + server + ":" + port,
    name: tag || (server + ":" + port),
    type: "shadowsocks",
    server: server,
    server_port: port,
    method: method,
    password: password,
    raw: link
  };
}
