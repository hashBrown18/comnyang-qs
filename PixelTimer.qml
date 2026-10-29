import QtQuick

Item {
    id: root
    required property string value
    width: 56; height: 18
    readonly property var glyphs: ({
        "0": ["111","101","101","101","111"], "1": ["010","110","010","010","111"],
        "2": ["111","001","111","100","111"], "3": ["111","001","111","001","111"],
        "4": ["101","101","111","001","001"], "5": ["111","100","111","001","111"],
        "6": ["111","100","111","101","111"], "7": ["111","001","010","010","010"],
        "8": ["111","101","111","101","111"], "9": ["111","101","111","001","111"],
        ":": ["0","1","0","1","0"]
    })

    Canvas {
        id: art
        anchors.fill: parent
        antialiasing: false
        onPaint: {
            const c = getContext("2d")
            c.clearRect(0, 0, width, height)
            c.fillStyle = "#513f39"
            let offset = 0
            for (const character of root.value) {
                const glyph = root.glyphs[character]
                for (let y = 0; y < 5; ++y)
                    for (let x = 0; x < glyph[y].length; ++x)
                        if (glyph[y][x] === "1") c.fillRect(offset + x * 3, y * 3, 3, 3)
                offset += character === ":" ? 5 : 11
            }
        }
    }

    onValueChanged: art.requestPaint()
}
