import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property int keyCount: 0
    property int scrollCount: 0
    property int paperCount: 0
    signal knead()
    signal overheat()
    signal paperUnroll()

    // The child emits only K/S category tokens; raw libinput lines and key data never enter QML.
    Process {
        id: monitor
        command: ["sh", "-c", "exec stdbuf -oL libinput debug-events 2>/dev/null | while IFS= read -r line; do case \"$line\" in *KEYBOARD_KEY*) printf 'K\\n' ;; *POINTER_AXIS*) printf 'S\\n' ;; esac; done"]
        running: true
        stdout: SplitParser {
            onRead: token => {
                if (token === "K") {
                    root.keyCount += 1
                    keyWindow.restart()
                } else if (token === "S") {
                    root.scrollCount += 1
                    root.paperCount += 1
                    scrollWindow.restart()
                    if (root.paperCount >= 12) {
                        root.paperCount = 0
                        root.paperUnroll()
                    }
                }
            }
        }
        stderr: SplitParser { onRead: _ => {} }
        onExited: retry.start()
    }

    Timer {
        id: keyWindow
        interval: 700
        onTriggered: {
            if (root.keyCount >= 4) root.knead()
            root.keyCount = 0
        }
    }

    Timer {
        id: scrollWindow
        interval: 500
        onTriggered: {
            if (root.scrollCount >= 8) root.overheat()
            root.scrollCount = 0
        }
    }

    Timer {
        id: retry
        interval: 5000
        onTriggered: if (!monitor.running) monitor.running = true
    }
}
