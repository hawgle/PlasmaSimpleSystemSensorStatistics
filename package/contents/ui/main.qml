import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.ksysguard.process as Process
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    readonly property int src: Plasmoid.configuration.sensorSource

    // layout
    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool isWide: Plasmoid.configuration.widgetShape === 1
    readonly property int graphThickness: Math.max(4, Math.round((isVertical ? width : height) * Plasmoid.configuration.graphSize / 100))
    readonly property int graphLength: isWide ? Math.round(graphThickness * 1.8) : graphThickness

    Layout.fillHeight: !isVertical
    Layout.fillWidth: isVertical
    Layout.preferredWidth: isVertical ? -1 : graphLength
    Layout.minimumWidth: isVertical ? -1 : Layout.preferredWidth
    Layout.maximumWidth: isVertical ? -1 : Layout.preferredWidth
    Layout.preferredHeight: isVertical ? graphLength : -1
    Layout.minimumHeight: isVertical ? Layout.preferredHeight : -1
    Layout.maximumHeight: isVertical ? Layout.preferredHeight : -1

    // theme
    readonly property bool useDarkTheme: {
        if (Plasmoid.configuration.themeMode === 0) return true;
        if (Plasmoid.configuration.themeMode === 1) return false;
        var bg = Kirigami.Theme.backgroundColor;
        return (bg.r + bg.g + bg.b) < 1.5;
    }
    readonly property color bgColor: useDarkTheme ? "#2d2d2d" : "#d9d9d9"
    readonly property color borderColor: useDarkTheme ? "#808080" : "#2d2d2d"

    // colors
    readonly property var defaultColors: [
        ["#37b837", "#FF0000"],      // cpu
        ["#FF8040", "transparent"],  // memory
        ["#0054D1", "#8AB9FF"],      // gpu
        ["#FF6BBC", "#1e3cc8"],      // network
        ["#FFD700", "#B8860B"]       // disk
    ]
    readonly property string line1: Plasmoid.configuration.overrideColors ? Plasmoid.configuration.customLine1 : defaultColors[src][0]
    readonly property string line2: Plasmoid.configuration.overrideColors ? Plasmoid.configuration.customLine2 : defaultColors[src][1]
    readonly property color fill1: Qt.alpha(line1, Plasmoid.configuration.fillOpacity / 100)
    readonly property color fill2: Qt.alpha(line2, Plasmoid.configuration.fillOpacity / 100)
    readonly property int lineWidth: Plasmoid.configuration.lineWidth || 1

    // devices
    readonly property string gpuDevice: Plasmoid.configuration.gpuDevice || "all"
    property string detectedOsDisk: ""
    readonly property string diskDevice: Plasmoid.configuration.diskDevice || detectedOsDisk || "all"

    // os disk
    P5Support.DataSource {
        id: osDiskSource
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            if (data["exit code"] === 0) root.detectedOsDisk = (data.stdout || "").trim();
            disconnectSource(sourceName);
        }
    }

    Component.onCompleted: osDiskSource.connectSource("findmnt -rno SOURCE / | sed 's/\\[.*\\]//' | xargs lsblk -srno NAME,TYPE | awk '$2==\"disk\"{print $1; exit}'")

    // sensors
    Sensors.Sensor { id: cpuUser;      sensorId: "cpu/all/user";                         enabled: root.src === 0 }
    Sensors.Sensor { id: cpuSys;       sensorId: "cpu/all/system";                       enabled: root.src === 0 }
    Sensors.Sensor { id: cpuTotal;     sensorId: "cpu/all/usage";                        enabled: root.src === 0 }
    Sensors.Sensor { id: memUsed;      sensorId: "memory/physical/used";                 enabled: root.src === 1 }
    Sensors.Sensor { id: memTotal;     sensorId: "memory/physical/total";                enabled: root.src === 1 }
    Sensors.Sensor { id: gpuUsage;     sensorId: "gpu/" + root.gpuDevice + "/usage";     enabled: root.src === 2 }
    Sensors.Sensor { id: gpuVramUsed;  sensorId: "gpu/" + root.gpuDevice + "/usedVram";  enabled: root.src === 2 }
    Sensors.Sensor { id: gpuVramTotal; sensorId: "gpu/" + root.gpuDevice + "/totalVram"; enabled: root.src === 2 }
    Sensors.Sensor { id: netDown;      sensorId: "network/all/download";                 enabled: root.src === 3 }
    Sensors.Sensor { id: netUp;        sensorId: "network/all/upload";                   enabled: root.src === 3 }
    Sensors.Sensor { id: diskRead;     sensorId: "disk/" + root.diskDevice + "/read";    enabled: root.src === 4 }
    Sensors.Sensor { id: diskWrite;    sensorId: "disk/" + root.diskDevice + "/write";   enabled: root.src === 4 }

    // history
    property var history1: []
    property var history2: []
    readonly property int maxHistory: isWide ? 70 : 30

    function clearHistory() {
        history1 = [];
        history2 = [];
        canvas.requestPaint();
    }

    onSrcChanged: clearHistory()
    onMaxHistoryChanged: clearHistory()
    onGpuDeviceChanged: clearHistory()
    onDiskDeviceChanged: clearHistory()

    // top process
    property string topProcessName: ""

    Process.ProcessDataModel {
        id: processModel
        flatList: true
        enabled: toolTipArea.containsMouse && root.src < 2
        enabledAttributes: ["name", "usage", "memory"]
    }

    Timer {
        running: processModel.enabled
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var col = root.src === 1 ? 2 : 1;
            var best = 0, name = "";
            for (var i = 0; i < processModel.rowCount(); i++) {
                var v = processModel.data(processModel.index(i, col), Process.ProcessDataModel.Value);
                if (v > best) {
                    best = v;
                    name = processModel.data(processModel.index(i, 0), Process.ProcessDataModel.Value);
                }
            }
            root.topProcessName = name;
            root.refreshTooltip();
        }
    }

    // tooltip
    readonly property var sourceNames: [i18n("CPU"), i18n("Memory"), i18n("GPU"), i18n("Network"), i18n("Disk")]
    property string toolTipText: ""

    PlasmaCore.ToolTipArea {
        id: toolTipArea
        anchors.fill: parent
        mainText: root.sourceNames[root.src]
        subText: root.toolTipText
        onContainsMouseChanged: root.refreshTooltip()
    }

    function refreshTooltip() {
        if (!toolTipArea.containsMouse) return;
        var lines = [];
        if (src === 0) {
            lines.push(sensorValue(cpuTotal).toFixed(1) + "%");
        } else if (src === 1) {
            lines.push(formatBytesPair(sensorValue(memUsed), sensorValue(memTotal)));
        } else if (src === 2) {
            lines.push(sensorValue(gpuUsage).toFixed(1) + "%");
            var vTotal = sensorValue(gpuVramTotal);
            if (vTotal > 0) lines.push(formatBytesPair(sensorValue(gpuVramUsed), vTotal));
        } else if (src === 3) {
            lines.push(i18n("%1 Down", formatSpeed(sensorValue(netDown))));
            lines.push(i18n("%1 Up", formatSpeed(sensorValue(netUp))));
        } else {
            lines.push(i18n("%1 Read", formatBytes(sensorValue(diskRead)) + "/s"));
            lines.push(i18n("%1 Write", formatBytes(sensorValue(diskWrite)) + "/s"));
        }
        if (src < 2 && topProcessName) lines.push(topProcessName);
        toolTipText = lines.join("\n");
    }

    // formatting
    function sensorValue(sensor) {
        var v = sensor.value;
        return (v !== undefined && !isNaN(v)) ? v : 0;
    }

    function formatBytes(bytes) {
        if (bytes <= 0) return "0 B";
        var units = ["B", "KiB", "MiB", "GiB", "TiB"];
        var i = 0;
        while (bytes >= 1024 && i < units.length - 1) { bytes /= 1024; i++; }
        return bytes.toFixed(i > 0 ? 1 : 0) + " " + units[i];
    }

    function formatBytesPair(used, total) {
        var units = ["B", "KiB", "MiB", "GiB", "TiB"];
        var i = 0;
        while (total >= 1024 && i < units.length - 1) { total /= 1024; i++; }
        return trimNumber(used / Math.pow(1024, i)) + "/" + trimNumber(total) + " " + units[i];
    }

    function trimNumber(v) {
        var s = v.toFixed(1);
        return s.endsWith(".0") ? s.slice(0, -2) : s;
    }

    function formatSpeed(bytesPerSec) {
        var mbits = bytesPerSec * 8 / 1000000;
        if (mbits >= 1000) return (mbits / 1000).toFixed(2) + " Gbit/s";
        if (mbits >= 1) return mbits.toFixed(2) + " Mbit/s";
        return (mbits * 1000).toFixed(1) + " Kbit/s";
    }

    // data tick
    Timer {
        interval: Plasmoid.configuration.updateInterval
        running: true
        repeat: true
        onTriggered: {
            var v1 = 0, v2 = 0;
            if (src === 0) {
                v1 = sensorValue(cpuUser);
                v2 = sensorValue(cpuSys);
            } else if (src === 1) {
                var mTotal = sensorValue(memTotal);
                v1 = mTotal > 0 ? sensorValue(memUsed) / mTotal * 100 : 0;
            } else if (src === 2) {
                v1 = sensorValue(gpuUsage);
                var vTotal = sensorValue(gpuVramTotal);
                v2 = vTotal > 0 ? sensorValue(gpuVramUsed) / vTotal * 100 : 0;
            } else if (src === 3) {
                v1 = sensorValue(netDown);
                v2 = sensorValue(netUp);
            } else {
                v1 = sensorValue(diskRead);
                v2 = sensorValue(diskWrite);
            }

            history1.push(v1);
            history2.push(v2);
            while (history1.length > maxHistory) history1.shift();
            while (history2.length > maxHistory) history2.shift();

            refreshTooltip();
            canvas.requestPaint();
        }
    }

    // rendering
    Canvas {
        id: canvas
        anchors.centerIn: parent
        width: root.isVertical ? root.graphThickness : root.graphLength
        height: root.isVertical ? root.graphLength : root.graphThickness

        onPaint: {
            var ctx = getContext("2d");
            var w = width, h = height;

            // frame
            ctx.clearRect(0, 0, w, h);
            ctx.fillStyle = root.bgColor;
            ctx.fillRect(0, 0, w, h);
            ctx.strokeStyle = root.borderColor;
            ctx.lineWidth = 1;
            ctx.strokeRect(0.5, 0.5, w - 1, h - 1);

            ctx.save();
            ctx.beginPath();
            ctx.rect(1, 1, w - 2, h - 2);
            ctx.clip();

            // scale
            var maxVal = 100;
            if (root.src >= 3) maxVal = Math.max(1, Math.max(...root.history1, ...root.history2));

            var plotH = h - 2;
            var step = (w - 2) / (root.maxHistory - 1);

            var trace = function(data) {
                ctx.beginPath();
                for (var i = 0; i < data.length; i++) {
                    var x = 1 + i * step;
                    var y = (h - 1) - Math.min(maxVal, Math.max(0, data[i])) / maxVal * plotH;
                    if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
                }
            };

            var drawGraph = function(data, lineColor, fillColor, punchOut) {
                if (data.length === 0 || lineColor === "transparent") return;

                // fill
                trace(data);
                ctx.lineTo(1 + (data.length - 1) * step, h - 1);
                ctx.lineTo(1, h - 1);
                ctx.closePath();
                if (punchOut) {
                    ctx.fillStyle = root.bgColor;
                    ctx.fill();
                }
                ctx.fillStyle = fillColor;
                ctx.fill();

                // line
                trace(data);
                ctx.strokeStyle = lineColor;
                ctx.lineWidth = root.lineWidth;
                ctx.stroke();
            };

            if (root.src === 2) {
                drawGraph(root.history2, root.line2, root.fill2);
                drawGraph(root.history1, root.line1, root.fill1, true);
            } else {
                drawGraph(root.history1, root.line1, root.fill1);
                drawGraph(root.history2, root.line2, root.fill2);
            }
            ctx.restore();
        }
    }
}
