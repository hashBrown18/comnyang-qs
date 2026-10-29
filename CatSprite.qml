import QtQuick

Item {
    id: root
    property string pattern: "siamese"
    property real pupilX: width / 2
    property real pupilY: height / 2
    property bool overheated: false
    property bool thinking: false
    readonly property int pixel: 10
    width: 180
    height: 180

    readonly property var rows: [
        "....d........d....",
        "...dbd......dbd...",
        "..dbbbddddbbbdd...",
        ".dbbbbbbbbbbbbbd..",
        ".dbbwwbbbbwwbbd...",
        ".dbbbbbbbbbbbbbd..",
        ".dbbbbcccbbbbbd...",
        ".ddbbbbbbbbbbddd..",
        "...dbbbbbbbbd.....",
        "...dbbbbbbbbd.....",
        "..dbbbbbbbbbbd....",
        ".dbbbbbbbbbbbbd...",
        ".dbbbddbbddbbbd...",
        ".dbbd..bb..dbbd...",
        ".dddd..dd..dddd..."
    ]

    function palette() {
        if (pattern === "orange") return ({ b: "#e99334", d: "#7c3f20", c: "#ffd28c", m: "#b85d28" })
        if (pattern === "mackerel") return ({ b: "#a88d74", d: "#45362f", c: "#e8d4b5", m: "#665045" })
        return ({ b: "#e9d2b1", d: "#493833", c: "#fff0d7", m: "#76554a" })
    }

    Canvas {
        id: art
        anchors.fill: parent
        antialiasing: false
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            const p = root.palette()
            for (let y = 0; y < root.rows.length; ++y) {
                for (let x = 0; x < root.rows[y].length; ++x) {
                    const cell = root.rows[y][x]
                    if (cell === "." || cell === "w") continue
                    ctx.fillStyle = p[cell] || p.b
                    ctx.fillRect(x * root.pixel, y * root.pixel, root.pixel, root.pixel)
                }
            }
            ctx.fillStyle = "#f8f6e9"
            ctx.fillRect(5 * root.pixel, 4 * root.pixel, 2 * root.pixel, root.pixel)
            ctx.fillRect(11 * root.pixel, 4 * root.pixel, 2 * root.pixel, root.pixel)
            ctx.fillStyle = p.m
            for (let x = 4; x < 14; x += 3) ctx.fillRect(x * root.pixel, 2 * root.pixel, root.pixel, root.pixel)
            if (root.pattern === "mackerel")
                for (let y = 7; y < 12; y += 2) ctx.fillRect(3 * root.pixel, y * root.pixel, 12 * root.pixel, root.pixel)
            if (root.overheated) {
                ctx.fillStyle = "#e95a4f"
                ctx.fillRect(3 * root.pixel, 5 * root.pixel, root.pixel, root.pixel)
                ctx.fillRect(14 * root.pixel, 5 * root.pixel, root.pixel, root.pixel)
            }
            if (root.thinking) {
                ctx.fillStyle = "#79a8cb"
                ctx.fillRect(8 * root.pixel, 0, root.pixel, root.pixel)
                ctx.fillRect(10 * root.pixel, root.pixel, root.pixel, root.pixel)
                ctx.fillRect(12 * root.pixel, 0, root.pixel, root.pixel)
            }
        }
        Connections {
            target: root
            function onPatternChanged() { art.requestPaint() }
            function onOverheatedChanged() { art.requestPaint() }
            function onThinkingChanged() { art.requestPaint() }
        }
    }

    Repeater {
        model: [ { x: 6, y: 4 }, { x: 12, y: 4 } ]
        Rectangle {
            width: 6; height: 8; radius: 3
            color: "#181313"
            x: (modelData.x * root.pixel) - 3 + Math.max(-3, Math.min(3, (root.pupilX - modelData.x * root.pixel) / 28))
            y: (modelData.y * root.pixel) - 4 + Math.max(-2, Math.min(2, (root.pupilY - modelData.y * root.pixel) / 35))
        }
    }
}
