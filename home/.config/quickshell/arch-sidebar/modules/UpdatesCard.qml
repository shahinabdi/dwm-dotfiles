import QtQuick
import Quickshell
import Quickshell.Io

// Updates (Settings → Updates): installed version, check now, update, what's new, weekly check on/off.
// Everything goes through ~/.local/bin/lunaris-update (both repos: lunaris + lunaris-dwm).
Rectangle {
    id: root
    width: 300
    height: col.implicitHeight + 28
    radius: 15
    color: "#24283b"

    property var st: ({})               // lunaris-update status: checked, current, latest, title, available, commits, error, timer, next
    property string notes: ""
    property bool checking: false
    readonly property bool available: st.available === "1"

    function refresh() { if (!statusP.running) statusP.running = true }
    function when(epoch) {
        const t = Number(epoch || 0)
        if (!t) return "never"
        const d = new Date(t * 1000), s = Date.now() / 1000 - t
        if (s < 60) return "just now"
        if (s < 3600) return Math.floor(s / 60) + " min ago"
        if (s < 86400) return "today " + Qt.formatTime(d, "HH:mm")
        return Qt.formatDateTime(d, "ddd d MMM, HH:mm")
    }
    function nextRun(v) {             // systemd: "Tue 2026-11-17 10:09:34 CET"
        const m = (v || "").match(/^(\w+) (\d{4})-(\d\d)-(\d\d) (\d\d:\d\d)/)
        return m ? m[1] + " " + Number(m[4]) + "/" + Number(m[3]) + " " + m[5] : ""
    }
    // markdown → short plain text for the preview
    function plain(md) {
        // the newest version's title is already shown above: skip its heading, keep older ones
        let first = true
        return md.split("\n").filter(l => {
            if (/^## \[/.test(l) && first) { first = false; return false }
            return l.trim() && !/^---/.test(l)
        }).map(l => l
            .replace(/^## \[([^\]]+)\] — [^·]*· */, "v$1 — ").replace(/^### /, "").replace(/^\s*- /, "• ")
            .replace(/\*\*/g, "").replace(/`/g, "").replace(/\[([^\]]+)\]\([^)]+\)/g, "$1")).join("\n")
    }

    onVisibleChanged: if (visible) refresh()

    Process {
        id: statusP
        running: true
        command: ["lunaris-update", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {}
                for (const l of this.text.split("\n")) { const i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1) }
                root.st = o
                if (o.available === "1" && !notesP.running) notesP.running = true
                if (o.available !== "1") root.notes = ""
            }
        }
    }
    Process {
        id: notesP
        command: ["lunaris-update", "notes"]
        stdout: StdioCollector { onStreamFinished: root.notes = root.plain(this.text) }
    }
    Process {
        id: checkP
        command: ["lunaris-update", "check"]
        onExited: { root.checking = false; root.refresh() }
    }
    Process { id: timerP; onExited: root.refresh() }
    // after "Update": follow the terminal's progress
    Timer { interval: 4000; running: root.visible; repeat: true; onTriggered: root.refresh() }

    Column {
        id: col
        x: 14; y: 14
        width: parent.width - 28
        spacing: 10

        // header: name + version · status pill
        Item {
            width: parent.width
            height: 28
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Text { anchors.verticalCenter: parent.verticalCenter; text: "Lunaris"; color: "#c0caf5"; font.pixelSize: 16; font.bold: true }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: ver.implicitWidth + 12; height: 20; radius: 10
                    color: "#414868"
                    Text { id: ver; anchors.centerIn: parent; text: "v" + (root.st.current || "?"); color: "#c0caf5"; font.pixelSize: 10; font.bold: true }
                }
            }
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: pill.implicitWidth + 16; height: 24; radius: 12
                color: root.checking ? "#414868" : root.st.error ? "#3b2f2f" : root.available ? "#e0af68" : "#273a2a"
                Text {
                    id: pill
                    anchors.centerIn: parent
                    text: root.checking ? "Checking…" : root.st.error ? "Can't check" : root.available ? "Update available" : "Up to date"
                    color: root.checking ? "#c0caf5" : root.st.error ? "#f7768e" : root.available ? "#1a1b26" : "#9ece6a"
                    font.pixelSize: 10; font.bold: true
                }
            }
        }

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            color: "#565f89"; font.pixelSize: 10
            text: (root.st.error ? root.st.error + " · " : "") + "Last checked: " + root.when(root.st.checked)
        }

        // what's new
        Column {
            visible: root.available
            width: parent.width
            spacing: 6
            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                color: "#e0af68"; font.pixelSize: 12; font.bold: true
                text: "v" + (root.st.latest || "?") + (root.st.title ? " — " + root.st.title : "")
                      + "  ·  " + (root.st.commits || 0) + " change" + (root.st.commits === "1" ? "" : "s")
            }
            Rectangle {
                visible: root.notes.length > 0
                width: parent.width
                height: Math.min(notesText.implicitHeight + 16, 170)
                radius: 8
                color: "#1f2335"
                Flickable {
                    anchors.fill: parent
                    anchors.margins: 8
                    contentHeight: notesText.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Text {
                        id: notesText
                        width: parent.width
                        wrapMode: Text.WordWrap
                        textFormat: Text.PlainText
                        color: "#a9b1d6"; font.pixelSize: 10
                        text: root.notes
                    }
                }
            }
        }

        // buttons
        Row {
            width: parent.width
            spacing: 8
            Rectangle {
                width: root.available ? (parent.width - 8) * 0.42 : parent.width
                height: 34; radius: 9
                color: cm.containsMouse ? "#565f89" : "#414868"
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "↻"; color: "#7aa2f7"; font.pixelSize: 16
                        RotationAnimation on rotation { running: root.checking; from: 0; to: 360; duration: 1000; loops: Animation.Infinite; alwaysRunToEnd: true }
                    }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Check now"; color: "#c0caf5"; font.pixelSize: 11; font.bold: true }
                }
                MouseArea {
                    id: cm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (!checkP.running) { root.checking = true; checkP.running = true }
                }
            }
            Rectangle {
                visible: root.available
                width: (parent.width - 8) * 0.58
                height: 34; radius: 9
                color: um.containsMouse ? "#89b4fa" : "#7aa2f7"
                Text { anchors.centerIn: parent; text: "Update to v" + (root.st.latest || "?"); color: "#1a1b26"; font.pixelSize: 11; font.bold: true }
                MouseArea {
                    id: um
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["lunaris-update", "gui"])
                }
            }
        }
        Text {
            visible: root.available
            width: parent.width
            wrapMode: Text.WordWrap
            color: "#565f89"; font.pixelSize: 9
            text: "A terminal shows the progress. If dwm itself changed it is rebuilt (asks for your password) and restarted in place — your windows stay. Configs you edited are backed up first."
        }

        Rectangle { width: parent.width; height: 1; color: "#414868" }

        // weekly check
        Item {
            width: parent.width
            height: 30
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text { text: "Check every Tuesday"; color: "#a9b1d6"; font.pixelSize: 11 }
                Text {
                    visible: root.st.timer === "1" && root.nextRun(root.st.next).length > 0
                    text: "next: " + root.nextRun(root.st.next)
                    color: "#565f89"; font.pixelSize: 9
                }
            }
            Switch2 {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                on: root.st.timer === "1"
                onToggled: { timerP.command = ["lunaris-update", "timer", on ? "off" : "on"]; timerP.running = true }
            }
        }
    }
}
