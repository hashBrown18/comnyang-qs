import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property string pattern: "siamese"
    property real cursorX: 0
    property real cursorY: 0
    property string userName: "friend"
    property string pinnedMessage: "Keep your shoulders soft."
    property string messageReminder: "Time to check your messages."
    property int stretchMinutes: 45
    property int waterMinutes: 30
    property int pomodoroMinutes: 25
    property int messageMinutes: 60
    property int pomodoroSeconds: pomodoroMinutes * 60
    property string notice: ""
    property string agentState: ""
    property real previousCursorX: 0
    property real previousCursorY: 0
    property double previousCursorTime: 0
    readonly property bool fullscreen: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.hasFullscreen

    function positiveMinutes(value, fallback) {
        return typeof value === "number" && value >= 1 && value <= 720 ? Math.floor(value) : fallback
    }

    function showNotice(message) {
        notice = message
        noticeTimer.restart()
    }

    function pomodoroText() {
        const minutes = Math.floor(pomodoroSeconds / 60)
        const seconds = pomodoroSeconds % 60
        return "Pomodoro " + minutes + ":" + (seconds < 10 ? "0" : "") + seconds
    }

    function loadAgentState() {
        try {
            const next = JSON.parse(agentStateFile.text()).state
            if (next !== "thinking" && next !== "done") return
            const previous = agentState
            agentState = next
            if (next === "done" && previous === "thinking") window.petTick += 1
        } catch (_) {}
    }

    function loadConfig() {
        try {
            const value = JSON.parse(config.text())
            if (["siamese", "orange", "mackerel"].includes(value.pattern))
                pattern = value.pattern
            if (typeof value.userName === "string" && value.userName.trim().length)
                userName = value.userName.trim()
            if (typeof value.pinnedMessage === "string" && value.pinnedMessage.trim().length)
                pinnedMessage = value.pinnedMessage.trim()
            if (typeof value.messageReminder === "string" && value.messageReminder.trim().length)
                messageReminder = value.messageReminder.trim()
            const timers = value.timers || {}
            stretchMinutes = positiveMinutes(timers.stretchMinutes, 45)
            waterMinutes = positiveMinutes(timers.waterMinutes, 30)
            pomodoroMinutes = positiveMinutes(timers.pomodoroMinutes, 25)
            messageMinutes = positiveMinutes(timers.messageMinutes, 60)
            pomodoroSeconds = pomodoroMinutes * 60
        } catch (_) {}
    }

    FileView {
        id: config
        path: Quickshell.env("HOME") + "/.config/comnyang/config.json"
        watchChanges: true
        onLoaded: root.loadConfig()
        onFileChanged: reload()
    }

    FileView {
        id: agentStateFile
        path: Quickshell.env("HOME") + "/.local/state/comnyang/agent-state.json"
        watchChanges: true
        onLoaded: root.loadAgentState()
        onFileChanged: reload()
    }

    Process {
        id: cursorProcess
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const point = JSON.parse(this.text)
                    const now = Date.now()
                    const elapsed = now - root.previousCursorTime
                    const dx = point.x - root.previousCursorX
                    const dy = point.y - root.previousCursorY
                    const distance = Math.sqrt(dx * dx + dy * dy)
                    root.cursorX = point.x
                    root.cursorY = point.y
                    if (elapsed > 0 && distance / elapsed > 1.35 && pounceCooldown.ready && !dragArea.dragging)
                        window.pounce(point.x, point.y)
                    root.previousCursorX = point.x
                    root.previousCursorY = point.y
                    root.previousCursorTime = now
                } catch (_) {}
            }
        }
    }

    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: if (!cursorProcess.running) cursorProcess.running = true
    }

    InputMonitor {
        onKnead: { window.kneading = true; kneadTimer.restart() }
        onOverheat: { window.overheated = true; overheatTimer.restart() }
        onPaperUnroll: window.paperTick += 1
    }

    Timer {
        interval: root.stretchMinutes * 60000
        running: true; repeat: true
        onTriggered: {
            root.showNotice(root.userName + ", stretch your paws and shoulders.")
            window.stretching = true
            stretchPoseTimer.restart()
        }
    }

    Timer {
        interval: root.waterMinutes * 60000
        running: true; repeat: true
        onTriggered: root.showNotice(root.userName + ", have some water.")
    }

    Timer {
        interval: root.messageMinutes * 60000
        running: true; repeat: true
        onTriggered: root.showNotice(root.userName + ", " + root.messageReminder)
    }

    Timer {
        interval: 1000
        running: true; repeat: true
        onTriggered: {
            root.pomodoroSeconds -= 1
            if (root.pomodoroSeconds <= 0) {
                root.showNotice(root.userName + ", pomodoro complete. Take a short break!")
                root.pomodoroSeconds = root.pomodoroMinutes * 60
            }
        }
    }

    Timer {
        id: noticeTimer
        interval: 8000
        onTriggered: root.notice = ""
    }

    Scope {
        id: pounceCooldown
        property bool ready: true
        function trigger() { ready = false; cooldown.restart() }
        Timer { id: cooldown; interval: 650; onTriggered: pounceCooldown.ready = true }
    }

    PanelWindow {
        id: window
        property real catX: width - cat.width - 28
        property real catY: height - cat.height - 20
        property int petTick: 0
        property bool kneading: false
        property bool overheated: false
        property int paperTick: 0
        property bool purring: false
        property bool pouncing: false
        property bool stretching: false
        width: screen.width
        height: screen.height
        color: "transparent"
        surfaceFormat.opaque: false
        exclusiveZone: 0
        focusable: false
        WlrLayershell.layer: WlrLayer.Overlay
        mask: Region { item: cat }

        function pounce(globalX, globalY) {
            catX = Math.max(0, Math.min(width - cat.width, globalX - screen.x - cat.width / 2))
            catY = Math.max(0, Math.min(height - cat.height, globalY - screen.y - cat.height / 2))
            pouncing = true
            pounceCooldown.trigger()
            pounceTimer.restart()
        }

        MessageBubble {
            x: Math.max(4, Math.min(window.width - width - 4, cat.x - 18))
            y: Math.max(3, cat.y - height - 8)
            message: root.notice.length ? root.notice : root.agentState === "thinking" ? "Agent is thinking…" : root.agentState === "done" ? "Agent is done!" : root.pinnedMessage
        }

        CatSprite {
            id: cat
            x: root.fullscreen ? window.width - width / 2 : window.catX
            y: root.fullscreen ? window.height - height - 20 : window.catY + (dragArea.dragging ? 0 : Math.sin(bob.elapsed / 260) * 3)
            pattern: root.pattern
            pupilX: root.cursorX - (window.screen.x + window.screen.width - window.width) - x
            pupilY: root.cursorY - (window.screen.y + window.screen.height - window.height) - y
            transform: Scale {
                id: catScale
                origin.x: cat.width / 2
                origin.y: cat.height / 2
                xScale: dragArea.dragging ? 1.16 : window.stretching ? 1.55 : window.pouncing ? 1.26 : window.kneading ? 1.05 + Math.sin(bob.elapsed / 75) * 0.04 : window.purring ? 1.025 : 1
                yScale: dragArea.dragging ? 0.86 : window.stretching ? 0.72 : window.pouncing ? 0.78 : window.kneading ? 0.95 - Math.sin(bob.elapsed / 75) * 0.04 : window.purring ? 0.975 : 1
                Behavior on xScale { NumberAnimation { duration: 100 } }
                Behavior on yScale { NumberAnimation { duration: 100 } }
            }
            rotation: window.stretching ? -8 : 0
            opacity: 1
            overheated: window.overheated
            thinking: root.agentState === "thinking"
            Behavior on rotation { NumberAnimation { duration: 140 } }
            Behavior on opacity { NumberAnimation { duration: 140 } }
            Behavior on x { enabled: !dragArea.dragging; NumberAnimation { duration: window.pouncing ? 90 : 260 } }
        }

        PixelTimer {
            x: cat.x > window.width / 2 ? cat.x - width - 6 : cat.x + cat.width + 6
            y: cat.y + 36
            value: root.pomodoroText().replace("Pomodoro ", "")
        }

        Item {
            id: paper
            x: 0; y: 12
            width: 0; height: 48
            clip: true
            Canvas {
                width: 58; height: 48
                antialiasing: false
                onPaint: {
                    const c = getContext("2d")
                    c.fillStyle = "#f7eed4"
                    c.fillRect(2, 2, 52, 42)
                    c.fillStyle = "#c9a96e"
                    for (let y = 10; y < 38; y += 8) c.fillRect(10, y, 36, 2)
                    c.fillRect(0, 0, 6, 46)
                }
            }
            SequentialAnimation {
                id: unroll
                NumberAnimation { target: paper; property: "width"; to: 58; duration: 260 }
                PauseAnimation { duration: 900 }
                NumberAnimation { target: paper; property: "width"; to: 0; duration: 220 }
            }
            Connections {
                target: window
                function onPaperTickChanged() { unroll.restart() }
            }
        }

        Repeater {
            model: 3
            Item {
                id: heart
                x: cat.x + 65 + index * 16
                property real homeY: cat.y + 36
                y: homeY
                width: 18; height: 18
                opacity: 0
                Canvas {
                    anchors.fill: parent
                    antialiasing: false
                    onPaint: {
                        const c = getContext("2d")
                        c.fillStyle = "#ef5e82"
                        [[3,0],[12,0],[0,3],[3,3],[6,3],[9,3],[12,3],[15,3],[3,6],[6,6],[9,6],[12,6],[6,9],[9,9]].forEach(p => c.fillRect(p[0], p[1], 3, 3))
                    }
                }
                SequentialAnimation {
                    id: heartPop
                    NumberAnimation { target: heart; property: "opacity"; to: 1; duration: 90 }
                    ParallelAnimation {
                        NumberAnimation { target: heart; property: "y"; to: heart.homeY - 28; duration: 550 }
                        NumberAnimation { target: heart; property: "opacity"; to: 0; duration: 550 }
                    }
                }
                Connections {
                    target: window
                    function onPetTickChanged() { heart.y = heart.homeY; heartPop.restart() }
                }
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            property bool dragging: false
            property bool moved: false
            property real offsetX: 0
            property real offsetY: 0
            property real lastHeadX: 0
            property int lastDirection: 0
            property int strokes: 0
            onPressed: mouse => {
                dragging = true
                moved = false
                offsetX = mouse.x - cat.x
                offsetY = mouse.y - cat.y
            }
            onPositionChanged: mouse => {
                if (!pressed) {
                    const onHead = mouse.x >= cat.x + 25 && mouse.x <= cat.x + 155 && mouse.y >= cat.y && mouse.y <= cat.y + 85
                    if (!onHead) { lastDirection = 0; return }
                    const distance = mouse.x - lastHeadX
                    const direction = Math.abs(distance) > 7 ? Math.sign(distance) : 0
                    if (direction && lastDirection && direction !== lastDirection) {
                        strokes += 1
                        petTimer.restart()
                        if (strokes >= 3) {
                            strokes = 0
                            window.purring = true
                            window.petTick += 1
                            purrTimer.restart()
                        }
                    }
                    if (direction) lastDirection = direction
                    lastHeadX = mouse.x
                    return
                }
                const nextX = Math.max(0, Math.min(window.width - cat.width, mouse.x - offsetX))
                const nextY = Math.max(0, Math.min(window.height - cat.height, mouse.y - offsetY))
                moved = moved || Math.abs(nextX - window.catX) > 3 || Math.abs(nextY - window.catY) > 3
                window.catX = nextX
                window.catY = nextY
            }
            onReleased: {
                dragging = false
                if (!moved) window.petTick += 1
            }
        }

        Timer {
            id: pounceTimer
            interval: 280
            onTriggered: window.pouncing = false
        }

        Timer {
            id: purrTimer
            interval: 1800
            onTriggered: window.purring = false
        }

        Timer {
            id: petTimer
            interval: 900
            onTriggered: dragArea.strokes = 0
        }

        Timer {
            id: purrHearts
            interval: 360
            running: window.purring
            repeat: true
            onTriggered: window.petTick += 1
        }

        Timer {
            id: stretchPoseTimer
            interval: 1800
            onTriggered: window.stretching = false
        }

        Timer {
            id: kneadTimer
            interval: 1100
            onTriggered: window.kneading = false
        }

        Timer {
            id: overheatTimer
            interval: 1400
            onTriggered: window.overheated = false
        }

        Timer {
            id: bob
            property int elapsed: 0
            interval: 16
            running: true
            repeat: true
            onTriggered: elapsed += interval
        }
    }
}
