import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

Item {
  id: root

  property var settings: ({})

  property bool active: false
  property bool busy: controlProcess.running || saveProcess.running
  property string statusText: active ? ("Connected" + (currentProfileName !== "" ? " (" + currentProfileName + ")" : "")) : "Disconnected"
  property string publicIp: "Checking..."
  property bool fetchingIp: ipProcess.running || settleIpTimer.running
  property string lastError: ""
  property string actionStatus: ""
  property int _ipRetryCount: 0

  property var profiles: []
  property string currentProfileId: ""
  readonly property string currentProfileName: {
    for (var i = 0; i < profiles.length; i++) {
      if (profiles[i].id === currentProfileId) return profiles[i].name
    }
    return profiles.length > 0 ? profiles[0].name : ""
  }

  readonly property var nodeOptions: {
    var opts = []
    for (var i = 0; i < profiles.length; i++) {
      var p = profiles[i]
      opts.push({
        label: p.name + " (" + p.server + ":" + p.server_port + ")",
        value: p.id
      })
    }
    return opts
  }

  readonly property string profilesFile: Quickshell.env("HOME") + "/.config/sing-box/profiles.json"

  function refresh() {
    if (!stateProcess.running) {
      stateProcess.command = ["systemctl", "is-active", "sing-box"]
      stateProcess.running = true
    }
  }

  function fetchPublicIp(immediate) {
    if (ipProcess.running) return
    if (!immediate && (busy || settleIpTimer.running)) return
    publicIp = "Fetching IP..."
    _ipRetryCount = 0
    ipProcess.command = ["bash", "-c", "curl -s -m 4 https://api.ipify.org || curl -s -m 4 https://ifconfig.me"]
    ipProcess.running = true
  }

  function triggerSettledIpFetch(reasonText) {
    publicIp = reasonText || "Fetching IP..."
    _ipRetryCount = 0
    settleIpTimer.restart()
  }

  function toggle() {
    if (busy) return
    if (!active && profiles.length === 0) {
      lastError = "No nodes configured. Add a VLESS node first."
      actionStatus = lastError
      actionStatusTimer.restart()
      return
    }
    var targetState = !active
    actionStatus = targetState ? "Connecting..." : "Disconnecting..."
    triggerSettledIpFetch(targetState ? "Connecting..." : "Disconnecting...")
    controlProcess.command = ["systemctl", targetState ? "start" : "stop", "sing-box"]
    controlProcess.running = true
  }

  function selectProfile(profileId) {
    if (!profileId || profileId === currentProfileId) return
    currentProfileId = profileId
    saveProfilesToDisk()
    applyCurrentProfile()
  }

  function applyCurrentProfile() {
    var profile = null
    for (var i = 0; i < profiles.length; i++) {
      if (profiles[i].id === currentProfileId) {
        profile = profiles[i]
        break
      }
    }
    if (!profile && profiles.length > 0) {
      profile = profiles[0]
      currentProfileId = profile.id
    }
    if (!profile) return

    var cfgStr = Model.buildSingBoxConfig(profile)
    saveProcess.environment = { "SINGBOX_CFG": cfgStr }
    saveProcess.command = ["bash", "-c", "printf '%s\\n' \"$SINGBOX_CFG\" | pkexec tee /etc/sing-box/config.json >/dev/null && (systemctl is-active sing-box >/dev/null && systemctl restart sing-box || true)"]
    actionStatus = "Applying " + profile.name + "..."
    triggerSettledIpFetch("Switching node...")
    saveProcess.running = true
  }

  function addProfile(nodeLink) {
    var parsed = Model.parseNodeLink(nodeLink)
    if (!parsed) {
      lastError = "Unsupported link format (use vless://, vmess://, trojan://, ss://, or hy2://)"
      actionStatus = lastError
      actionStatusTimer.restart()
      return false
    }

    var list = profiles.slice()
    var found = false
    for (var i = 0; i < list.length; i++) {
      if (list[i].id === parsed.id || list[i].name === parsed.name) {
        list[i] = parsed
        found = true
        break
      }
    }
    if (!found) list.push(parsed)

    profiles = list
    currentProfileId = parsed.id
    saveProfilesToDisk()
    applyCurrentProfile()
    actionStatus = "Added node: " + parsed.name
    actionStatusTimer.restart()
    return true
  }

  function deleteProfile(profileId) {
    var list = []
    for (var i = 0; i < profiles.length; i++) {
      if (profiles[i].id !== profileId) {
        list.push(profiles[i])
      }
    }
    if (list.length === 0) {
      lastError = "Cannot delete the last node"
      actionStatus = lastError
      actionStatusTimer.restart()
      return
    }
    profiles = list
    if (currentProfileId === profileId) {
      currentProfileId = list[0].id
      applyCurrentProfile()
    }
    saveProfilesToDisk()
    actionStatus = "Node removed"
    actionStatusTimer.restart()
  }

  function saveProfilesToDisk() {
    var data = JSON.stringify({
      currentProfileId: currentProfileId,
      profiles: profiles
    }, null, 2)
    profileSaveProcess.environment = { "SINGBOX_PROFILES": data }
    profileSaveProcess.command = ["bash", "-c", "(umask 077; mkdir -p ~/.config/sing-box && printf '%s\\n' \"$SINGBOX_PROFILES\" > '" + profilesFile + "' && chmod 600 '" + profilesFile + "')"]
    profileSaveProcess.running = true
  }

  function loadProfilesFromDisk() {
    loadProcess.command = ["cat", profilesFile]
    loadProcess.running = true
  }

  Component.onCompleted: {
    loadProfilesFromDisk()
    refresh()
    fetchPublicIp(true)
  }

  Timer {
    id: refreshTimer
    interval: 3000
    repeat: true
    running: true
    onTriggered: root.refresh()
  }

  Timer {
    id: settleIpTimer
    interval: 1800
    repeat: false
    running: false
    onTriggered: {
      ipProcess.command = ["bash", "-c", "curl -s -m 4 https://api.ipify.org || curl -s -m 4 https://ifconfig.me"]
      ipProcess.running = true
    }
  }

  Timer {
    id: actionStatusTimer
    interval: 3000
    repeat: false
    onTriggered: root.actionStatus = ""
  }

  Process {
    id: stateProcess
    running: false
    command: []
    stdout: StdioCollector { id: stateStdout; waitForEnd: true }
    onExited: function(exitCode) {
      var stdout = String(stateStdout.text || "").trim()
      var wasActive = root.active
      root.active = (stdout === "active" && exitCode === 0)
      if (wasActive !== root.active) {
        root.triggerSettledIpFetch()
      }
    }
  }

  Process {
    id: controlProcess
    running: false
    command: []
    stderr: StdioCollector { id: controlStderr; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        var err = String(controlStderr.text || "Failed to toggle service").trim()
        root.lastError = err.length > 80 ? err.substring(0, 77) + "..." : err
        root.actionStatus = root.lastError
        actionStatusTimer.restart()
      } else {
        root.lastError = ""
        root.actionStatus = ""
      }
      root.refresh()
    }
  }

  Process {
    id: saveProcess
    running: false
    command: []
    stderr: StdioCollector { id: saveStderr; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        var err = String(saveStderr.text || "Authentication / update failed").trim()
        root.lastError = err.length > 80 ? err.substring(0, 77) + "..." : err
        root.actionStatus = root.lastError
        actionStatusTimer.restart()
      } else {
        root.lastError = ""
        root.actionStatus = "Applied " + root.currentProfileName
        actionStatusTimer.restart()
      }
      root.refresh()
    }
  }

  Process {
    id: ipProcess
    running: false
    command: []
    stdout: StdioCollector { id: ipStdout; waitForEnd: true }
    onExited: function(exitCode) {
      var out = String(ipStdout.text || "").trim()
      if (exitCode === 0 && out !== "" && out.indexOf("<") === -1) {
        root.publicIp = out
      } else {
        // If failed while connecting, retry up to 3 times
        if (root._ipRetryCount < 3) {
          root._ipRetryCount++
          settleIpTimer.interval = 1500
          settleIpTimer.restart()
        } else {
          root.publicIp = "Unavailable"
        }
      }
    }
  }

  Process {
    id: loadProcess
    running: false
    command: []
    stdout: StdioCollector { id: loadStdout; waitForEnd: true }
    onExited: function(exitCode) {
      var out = String(loadStdout.text || "").trim()
      var parsed = Model.parseJson(out)
      if (parsed && Array.isArray(parsed.profiles)) {
        root.profiles = parsed.profiles
        var targetId = parsed.currentProfileId || ""
        var found = false
        for (var i = 0; i < parsed.profiles.length; i++) {
          if (parsed.profiles[i].id === targetId) {
            found = true
            break
          }
        }
        root.currentProfileId = found ? targetId : (parsed.profiles.length > 0 ? parsed.profiles[0].id : "")
        if (!found && parsed.profiles.length > 0) {
          root.saveProfilesToDisk()
        }
        root.lastError = ""
      } else if (exitCode !== 0 && out === "") {
        root.profiles = []
        root.currentProfileId = ""
        root.saveProfilesToDisk()
      } else {
        root.profiles = []
        root.currentProfileId = ""
        root.lastError = "Invalid profiles file: " + root.profilesFile
        root.actionStatus = root.lastError
        actionStatusTimer.restart()
      }
    }
  }

  Process {
    id: profileSaveProcess
    running: false
    command: []
  }
}
