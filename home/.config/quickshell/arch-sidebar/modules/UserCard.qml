import QtQuick
import Quickshell
import Quickshell.Io

// Header: user (first letter capitalised), distro + window manager detected automatically.
Item {
    id: root

    width: 300
    height: 84

    property string userName: ""
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

    function capitalize(s) {
        return s.split(/\s+/).filter(w => w.length)
                .map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ")
    }

    // one shot: user, host, distro, wm  (key=value lines)
    Process {
        id: infoProcess
        running: true
        command: ["sh", "-c",
            "full=$(getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1);" +
            "echo \"user=${full:-$USER}\";" +
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
                    if (k === "user") root.userName = root.capitalize(v)
                    else if (k === "host") root.hostName = v
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

        // avatar: initial in a circle
        Rectangle {
            width: 58
            height: 58
            radius: 29
            anchors.verticalCenter: parent.verticalCenter
            color: "#7aa2f7"

            Text {
                anchors.centerIn: parent
                text: root.userName.length ? root.userName.charAt(0) : "?"
                color: "#1a1b26"
                font.pixelSize: 26
                font.bold: true
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
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 72
            spacing: 3

            Text {
                width: parent.width
                text: root.userName || " "
                color: "#c0caf5"
                font.pixelSize: 20
                font.bold: true
                elide: Text.ElideRight
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
}
