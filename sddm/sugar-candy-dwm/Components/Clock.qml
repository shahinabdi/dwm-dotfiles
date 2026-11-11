//
// This file is part of SDDM Sugar Candy.
// A theme for the Simple Display Desktop Manager.
//
// Copyright (C) 2018–2020 Marian Arlt
//
// SDDM Sugar Candy is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the
// Free Software Foundation, either version 3 of the License, or any later version.
//
// You are required to preserve this and any additional legal notices, either
// contained in this file or in other files that you received along with
// SDDM Sugar Candy that refer to the author(s) in accordance with
// sections §4, §5 and specifically §7b of the GNU General Public License.
//
// SDDM Sugar Candy is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with SDDM Sugar Candy. If not, see <https://www.gnu.org/licenses/>
//

// Modified for dwm-btw (2026): profile picture, time-of-day greeting with the user's name,
// subtitle with the host name, keyboard layout and Caps Lock chips. Options in theme.conf.

import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Column {
    id: clock
    spacing: root.font.pointSize * 0.6
    width: parent.width / 2

    // ---- the user shown (last logged-in user): name and picture from SDDM's user model
    property string userName: ""
    property string userIcon: ""
    Repeater {
        model: userModel
        delegate: Item {
            required property int index
            required property string name
            required property string realName
            required property string icon
            Component.onCompleted: if (index === Math.max(0, userModel.lastIndex)) {
                const n = realName !== "" ? realName.split(" ")[0] : name
                clock.userName = n.charAt(0).toUpperCase() + n.slice(1)
                clock.userIcon = icon
            }
        }
    }

    function greeting() {
        if (config.GreetingStyle !== "time")
            return config.HeaderText
        const h = new Date().getHours()
        const g = h < 5 ? (config.NightText || "Good night")
                : h < 12 ? (config.MorningText || "Good morning")
                : h < 18 ? (config.AfternoonText || "Good afternoon")
                : h < 22 ? (config.EveningText || "Good evening")
                : (config.NightText || "Good night")
        return config.GreetingName === "false" || clock.userName === "" ? g : g + ", " + clock.userName
    }

    // ---- profile picture
    Item {
        visible: config.ShowAvatar !== "false"
        width: root.font.pointSize * 7
        height: width
        anchors.horizontalCenter: parent.horizontalCenter

        Image {
            id: face
            anchors.fill: parent
            anchors.margins: 4
            source: clock.userIcon !== "" ? clock.userIcon : Qt.resolvedUrl("../Assets/User.svgz")
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 256
            sourceSize.height: 256
            visible: false
            smooth: true
        }
        Rectangle { id: mask; anchors.fill: face; radius: width / 2; visible: false }
        OpacityMask { anchors.fill: face; source: face; maskSource: mask }
        Rectangle {   // ring in the accent colour
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 3
            border.color: root.palette.highlight
        }
    }

    // ---- greeting
    Label {
        id: greetingLabel
        anchors.horizontalCenter: parent.horizontalCenter
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: root.font.pointSize * 1.9
        font.bold: true
        color: root.palette.text
        renderType: Text.QtRendering
        text: clock.greeting()
    }

    // ---- subtitle: "%host%" becomes the computer name
    Label {
        visible: config.Subtitle !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        font.pointSize: root.font.pointSize * 0.9
        color: root.palette.highlight
        renderType: Text.QtRendering
        text: (config.Subtitle || "").replace("%host%", sddm.hostName || "").replace(/\s*·\s*$/, "")
    }

    Label {
        id: timeLabel
        anchors.horizontalCenter: parent.horizontalCenter
        font.pointSize: root.font.pointSize * 3
        color: root.palette.text
        renderType: Text.QtRendering
        function updateTime() {
            text = new Date().toLocaleTimeString(Qt.locale(config.Locale), config.HourFormat == "long" ? Locale.LongFormat : config.HourFormat !== "" ? config.HourFormat : Locale.ShortFormat)
        }
    }

    Label {
        id: dateLabel
        anchors.horizontalCenter: parent.horizontalCenter
        color: root.palette.text
        renderType: Text.QtRendering
        function updateTime() {
            text = new Date().toLocaleDateString(Qt.locale(config.Locale), config.DateFormat == "short" ? Locale.ShortFormat : config.DateFormat !== "" ? config.DateFormat : Locale.LongFormat)
        }
    }

    // ---- keyboard layout (click to switch) and Caps Lock
    Item { width: 1; height: root.font.pointSize * 0.4 }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8
        visible: config.ShowKeyboardLayout !== "false"

        Rectangle {
            id: layoutChip
            visible: keyboard.layouts.length > 0
            height: root.font.pointSize * 2.4
            width: layoutText.implicitWidth + height
            radius: height / 2
            color: layoutMouse.containsMouse ? root.palette.highlight : "transparent"
            border.width: 1
            border.color: root.palette.highlight
            Label {
                id: layoutText
                anchors.centerIn: parent
                font.pointSize: root.font.pointSize * 0.85
                font.bold: true
                color: layoutMouse.containsMouse ? root.palette.window : root.palette.highlight
                text: "⌨  " + (keyboard.layouts.length > 0 ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : "")
            }
            MouseArea {
                id: layoutMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
            }
        }

        Rectangle {
            visible: keyboard.capsLock
            height: root.font.pointSize * 2.4
            width: capsText.implicitWidth + height
            radius: height / 2
            color: "#e0af68"
            Label {
                id: capsText
                anchors.centerIn: parent
                font.pointSize: root.font.pointSize * 0.85
                font.bold: true
                color: "#1a1b26"
                text: "⇪  Caps Lock"
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            dateLabel.updateTime()
            timeLabel.updateTime()
            greetingLabel.text = clock.greeting()
        }
    }

    Component.onCompleted: {
        dateLabel.updateTime()
        timeLabel.updateTime()
    }
}
