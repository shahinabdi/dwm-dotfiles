import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

// Header: profile picture (~/.face) or initial, display name, distro + window manager.
// Click the avatar or the name to change them (dwm-profile).
Item {
    id: root

    width: 300
    height: 84

    signal requestClose()
    signal openSettings()

    property string userName: ""
    property string facePath: ""
    property string faceStamp: ""
    property string hostName: ""
    property string distroName: "Linux"
    property string distroId: "linux"
    property string wmName: ""
    property string uptimeText: ""

    // distro id -> nerd-font logo
    readonly property var distroGlyphs: ({
        "arch": 0xF303, "archarm": 0xF303, "endeavouros": 0xF322, "manjaro": 0xF312,
        "debian": 0xF306, "ubuntu": 0xF31B, "linuxmint": 0xF30E, "pop": 0xF32A,
        "fedora": 0xF30A, "opensuse": 0xF314, "opensuse-tumbleweed": 0xF314,
        "opensuse-leap": 0xF314, "nixos": 0xF313, "gentoo": 0xF30D, "void": 0xF32E
    })

    function editProfile() {
        root.requestClose()
        Quickshell.execDetached(["sh", "-c", "sleep 0.3; dwm-profile menu"])
    }

    // name + picture (re-read every few seconds so changes show up by themselves)
    Process {
        id: profileProcess
        running: true
        command: ["sh", "-c",
            "dwm-profile get 2>/dev/null || echo \"name=$USER\";" +
            "[ -f \"$HOME/.face\" ] && echo \"stamp=$(stat -c %Y \"$HOME/.face\")\"; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                let name = "", face = "", stamp = ""
                for (const line of this.text.split("\n")) {
                    const i = line.indexOf("=")
                    if (i < 0) continue
                    const k = line.slice(0, i), v = line.slice(i + 1).trim()
                    if (k === "name") name = v
                    else if (k === "face") face = v
                    else if (k === "stamp") stamp = v
                }
                if (name) root.userName = name
                root.facePath = face
                root.faceStamp = stamp
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: profileProcess.running = true
    }

    // one shot: host, distro, wm  (key=value lines)
    Process {
        id: infoProcess
        running: true
        command: ["sh", "-c",
            "echo \"host=$(cat /etc/hostname 2>/dev/null || uname -n)\";" +
            ". /etc/os-release 2>/dev/null; echo \"distro=${PRETTY_NAME:-${NAME:-Linux}}\"; echo \"id=${ID:-linux}\";" +
            "wm=''; for w in Hyprland sway niri river labwc dwm i3 bspwm awesome openbox xmonad qtile herbstluftwm spectrwm leftwm berry; do" +
            "  pgrep -x \"$w\" >/dev/null && { wm=$w; break; }; done;" +
            "echo \"wm=${wm:-${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}}\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of this.text.split("\n")) {
                    const i = line.indexOf("=")
                    if (i < 0) continue
                    const k = line.slice(0, i), v = line.slice(i + 1).trim()
                    if (k === "host") root.hostName = v
                    else if (k === "distro") root.distroName = v
                    else if (k === "id") root.distroId = v.toLowerCase()
                    else if (k === "wm") root.wmName = v
                }
            }
        }
    }

    Process {
        id: uptimeProcess
        running: true
        command: ["sh", "-c", "uptime -p | sed 's/^up //'"]
        stdout: StdioCollector {
            onStreamFinished: root.uptimeText = this.text.trim()
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: uptimeProcess.running = true
    }

    Row {
        anchors.fill: parent
        spacing: 14

        // avatar: picture in a circle, or the initial
        Item {
            id: avatar
            width: 58
            height: 58
            anchors.verticalCenter: parent.verticalCenter

            ClippingRectangle {
                anchors.fill: parent
                radius: width / 2
                color: "#7aa2f7"

                Image {
                    anchors.fill: parent
                    visible: root.facePath !== "" && status === Image.Ready
                    source: root.facePath ? "file://" + root.facePath + "?v=" + root.faceStamp : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 116
                    sourceSize.height: 116
                    cache: false
                    asynchronous: true
                    smooth: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.facePath === ""
                    text: root.userName.length ? root.userName.charAt(0).toUpperCase() : "?"
                    color: "#1a1b26"
                    font.pixelSize: 26
                    font.bold: true
                }

                // hover: "edit" overlay
                Rectangle {
                    anchors.fill: parent
                    color: "#991a1b26"
                    visible: avatarMouse.containsMouse

                    Text {
                        anchors.centerIn: parent
                        text: String.fromCodePoint(0xF03EB)
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 20
                        color: "#c0caf5"
                    }
                }
            }

            // ring
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: avatarMouse.containsMouse ? "#7aa2f7" : "#414868"
            }

            // distro badge
            Rectangle {
                width: 24
                height: 24
                radius: 12
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: -3
                anchors.bottomMargin: -3
                color: "#1a1b26"
                border.width: 1
                border.color: "#414868"

                Text {
                    anchors.centerIn: parent
                    text: String.fromCodePoint(root.distroGlyphs[root.distroId] || 0xF17C)
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 14
                    color: "#7aa2f7"
                }
            }

            MouseArea {
                id: avatarMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.editProfile()
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 72 - 44
            spacing: 3

            Text {
                width: parent.width
                text: root.userName || " "
                color: nameMouse.containsMouse ? "#7aa2f7" : "#c0caf5"
                font.pixelSize: 20
                font.bold: true
                elide: Text.ElideRight

                MouseArea {
                    id: nameMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.editProfile()
                }
            }

            Text {
                width: parent.width
                text: (root.distroName + (root.wmName ? "  •  " + root.wmName : "")).toUpperCase()
                color: "#7aa2f7"
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1.2
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.hostName + (root.uptimeText ? "  •  up " + root.uptimeText : "")
                color: "#565f89"
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }
    }

    // gear: open the Settings page
    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        height: 36
        radius: 10
        color: gm.containsMouse ? "#2f3549" : "#24283b"
        border.width: 1
        border.color: gm.containsMouse ? "#7aa2f7" : "#414868"
        Text {
            anchors.centerIn: parent
            text: String.fromCodePoint(0xF0493)
            font.family: "JetBrainsMono Nerd Font Mono"
            font.pixelSize: 18
            color: gm.containsMouse ? "#7aa2f7" : "#a9b1d6"
            rotation: gm.containsMouse ? 45 : 0
            Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            id: gm
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openSettings()
        }
    }
}
