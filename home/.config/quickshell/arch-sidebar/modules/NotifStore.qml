import QtQuick
import Quickshell
import Quickshell.Io

// Saved notifications (one instance in shell.qml, shared by the card and the page).
// Data and actions: ~/.local/bin/dwm-notif.
Item {
    id: store
    visible: false

    property var items: []          // newest first: { id, time, app, summary, body, icon, urgency, unread }
    property bool silent: false
    property real now: Date.now() / 1000
    readonly property int unread: items.filter(n => n.unread).length
    readonly property var apps: {   // app names present, most frequent first
        const c = {}
        for (const n of items) { const a = store.appOf(n); c[a] = (c[a] || 0) + 1 }
        return Object.keys(c).sort((a, b) => c[b] - c[a] || a.localeCompare(b))
    }

    function refresh() { if (!listP.running) listP.running = true; if (!statP.running) statP.running = true }
    function remove(id) {
        store.items = store.items.filter(n => n.id !== id)          // instant, then saved
        Quickshell.execDetached(["dwm-notif", "rm", id])
    }
    function clearAll() {
        store.items = []
        Quickshell.execDetached(["dwm-notif", "clear"])
    }
    function setSilent(on) {
        store.silent = on
        Quickshell.execDetached(["dwm-notif", "silent", on ? "on" : "off"])
    }
    function appOf(n) { return n.app || n.summary || "Other" }
    function ago(t) {
        const s = Math.max(0, store.now - t)
        if (s < 60) return "now"
        if (s < 3600) return Math.floor(s / 60) + " min ago"
        if (s < 86400) return Math.floor(s / 3600) + " h ago"
        const d = new Date(t * 1000)
        return s < 7 * 86400 ? Qt.formatDateTime(d, "ddd HH:mm") : Qt.formatDateTime(d, "d MMM yyyy")
    }
    function day(t) {                // group title
        const d = new Date(t * 1000), today = new Date()
        const start = new Date(today.getFullYear(), today.getMonth(), today.getDate()).getTime() / 1000
        if (t >= start) return "Today"
        if (t >= start - 86400) return "Yesterday"
        return Qt.formatDate(d, today.getFullYear() === d.getFullYear() ? "dddd d MMMM" : "d MMMM yyyy")
    }
    function glyph(n) {
        const t = ((n.app || "") + " " + (n.summary || "")).toLowerCase()
        if (n.urgency === "critical" && /battery/.test(t)) return 0xF0083
        if (/battery/.test(t)) return 0xF0079
        if (/bluetooth/.test(t)) return 0xF00AF
        if (/wi-?fi|network/.test(t)) return 0xF05A9
        if (/screenshot/.test(t)) return 0xF0104
        if (/download/.test(t)) return 0xF01DA
        if (/mail/.test(t)) return 0xF01EE
        if (/firefox|chrom|brave|browser/.test(t)) return 0xF059F
        if (/discord|telegram|signal|message|chat/.test(t)) return 0xF0369
        if (/update|pacman|yay/.test(t)) return 0xF06B0
        return 0xF009A
    }

    Process {
        id: listP
        running: true
        command: ["dwm-notif", "list"]
        stdout: StdioCollector {
            onStreamFinished: { try { store.items = JSON.parse(this.text) } catch (e) {} }
        }
    }
    Process {
        id: statP
        running: true
        command: ["dwm-notif", "status"]
        stdout: StdioCollector { onStreamFinished: store.silent = this.text.indexOf("silent=1") >= 0 }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: { store.now = Date.now() / 1000; store.refresh() } }
}
