import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "io.github.rizmi.singbox-vpn"
  ipcTarget: "io.github.rizmi.singbox-vpn"
  manageIpc: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property color iconColor: singbox.active ? foreground : dim
  readonly property color barIconColor: singbox.active ? barForeground : Qt.darker(barForeground, 1.55)
  readonly property string toggleHint: singbox.active ? "Disconnect" : "Connect"
  property bool addNodeExpanded: false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Service {
    id: singbox
    settings: root.settings
  }

  onOpenedChanged: {
    if (opened) {
      singbox.refresh()
      singbox.fetchPublicIp(false)
      root.addNodeExpanded = false
      Qt.callLater(function() { keyCatcher.forceActiveFocus() })
    }
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { singbox.refresh(); singbox.fetchPublicIp(true); return "ok" }
    function status(): string { return singbox.statusText }
    function ip(): string { return singbox.publicIp }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰖂"
    foreground: root.barIconColor
    tooltipText: "sing-box VPN — " + singbox.statusText + (singbox.publicIp !== "" ? (" [" + singbox.publicIp + "]") : "")
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) {
        singbox.refresh()
        singbox.fetchPublicIp(true)
      } else if (buttonCode === Qt.MiddleButton) {
        singbox.toggle()
      } else {
        root.toggle()
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(480))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: nodePicker.popupOpen || vlessInput.activeFocus
      onCloseRequested: root.close()
      onTextKey: function(t) {
        if (t === "r" || t === "R") {
          singbox.refresh()
          singbox.fetchPublicIp(true)
        } else if (t === "c" || t === "C") {
          singbox.toggle()
        }
      }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Style.space(12)

        PanelHero {
          id: hero
          width: parent.width
          title: "sing-box VPN"
          meta: singbox.statusText
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconOpacity: singbox.active ? 1.0 : 0.6
          iconComponent: Component {
            Text {
              text: "󰖂"
              color: root.iconColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
            }
          }
          trailingControl: Component {
            ToggleSwitch {
              id: powerSwitch
              checked: singbox.active
              busy: singbox.busy
              interactive: !singbox.busy
              foreground: hero.foreground
              onToggled: singbox.toggle()

              PanelToolTip {
                visible: powerSwitch.containsMouse
                text: root.toggleHint
                fontFamily: hero.fontFamily
              }
            }
          }
        }

        // Public IP row with theme font icons
        Rectangle {
          width: parent.width
          height: Style.space(38)
          color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.07)
          radius: Style.space(6)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Style.space(12)
            anchors.rightMargin: Style.space(12)
            spacing: Style.space(8)

            Text {
              text: "󰖟"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              Layout.alignment: Qt.AlignVCenter
            }

            Text {
              text: "Public IP:"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              Layout.alignment: Qt.AlignVCenter
            }

            Text {
              text: singbox.publicIp
              color: singbox.active ? root.foreground : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              elide: Text.ElideRight
            }

            Rectangle {
              width: Style.space(26)
              height: Style.space(26)
              radius: Style.space(4)
              color: ipRefreshMouse.containsMouse ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.15) : "transparent"
              Layout.alignment: Qt.AlignVCenter

              Text {
                id: refreshIcon
                anchors.centerIn: parent
                text: "󰑐"
                color: ipRefreshMouse.containsMouse ? root.foreground : root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                opacity: singbox.fetchingIp ? 0.4 : 1.0

                NumberAnimation on rotation {
                  running: singbox.fetchingIp
                  from: 0
                  to: 360
                  duration: 800
                  loops: Animation.Infinite
                }
              }

              MouseArea {
                id: ipRefreshMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: singbox.fetchPublicIp(true)
              }
            }
          }
        }

        Text {
          visible: singbox.actionStatus !== "" || singbox.lastError !== ""
          width: parent.width
          text: singbox.actionStatus !== "" ? singbox.actionStatus : singbox.lastError
          color: singbox.lastError !== "" && singbox.actionStatus === "" ? root.urgent : root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }

        PanelSeparator { foreground: root.foreground }

        // Node selector section
        Column {
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader {
            text: "SERVER NODE"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          SearchableDropdown {
            id: nodePicker
            width: parent.width
            showLabel: false
            placeholderText: singbox.profiles.length > 0 ? "Select server node..." : "No nodes configured"
            fontFamily: root.fontFamily
            options: singbox.nodeOptions
            value: singbox.currentProfileId
            onChanged: function(v) { singbox.selectProfile(v) }
          }
        }

        PanelSeparator { foreground: root.foreground }

        // Expandable Add Node section
        Rectangle {
          width: parent.width
          height: Style.space(32)
          color: addNodeBtnArea.containsMouse ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12) : "transparent"
          radius: Style.space(6)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Style.space(4)
            anchors.rightMargin: Style.space(4)
            spacing: Style.space(8)

            Text {
              text: "󰐕"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              Layout.alignment: Qt.AlignVCenter
            }

            Text {
              text: "Add VLESS Node"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Text {
              text: root.addNodeExpanded ? "▲" : "▼"
              color: root.dim
              font.pixelSize: Style.font.bodySmall
              Layout.alignment: Qt.AlignVCenter
            }
          }

          MouseArea {
            id: addNodeBtnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.addNodeExpanded = !root.addNodeExpanded
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(8)
          visible: root.addNodeExpanded
          clip: true

          Rectangle {
            width: parent.width
            height: Style.space(36)
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
            radius: Style.space(6)
            border.color: vlessInput.activeFocus ? root.foreground : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.15)
            border.width: 1

            TextInput {
              id: vlessInput
              anchors.fill: parent
              anchors.leftMargin: Style.space(10)
              anchors.rightMargin: Style.space(10)
              verticalAlignment: Text.AlignVCenter
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              selectByMouse: true

              Text {
                text: "Paste vless:// link..."
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                visible: vlessInput.text === "" && !vlessInput.activeFocus
                anchors.verticalCenter: parent.verticalCenter
              }

              onAccepted: addBtn.doAdd()
            }
          }

          Rectangle {
            id: addBtn
            width: parent.width
            height: Style.space(32)
            color: addBtnArea.containsMouse ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.2) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.1)
            radius: Style.space(6)

            function doAdd() {
              if (vlessInput.text.trim() === "") return
              if (singbox.addProfile(vlessInput.text.trim())) {
                vlessInput.text = ""
                root.addNodeExpanded = false
              }
            }

            Text {
              anchors.centerIn: parent
              text: "Import & Apply"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }

            MouseArea {
              id: addBtnArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: addBtn.doAdd()
            }
          }
        }
      }
    }
  }
}
