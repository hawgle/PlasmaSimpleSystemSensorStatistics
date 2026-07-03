import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    // layout
    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    property bool isWide: Plasmoid.configuration.widgetShape === 1

    // graph size as a fraction of the available panel thickness
    property real graphScale: Math.max(20, Math.min(100, Plasmoid.configuration.graphSize || 100)) / 100
    readonly property int graphThickness: Math.max(4, Math.round((isVertical ? width : height) * graphScale))
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
    property bool useDarkTheme: {
        if (Plasmoid.configuration.themeMode === 0) return true;
        if (Plasmoid.configuration.themeMode === 1) return false;
        var bg = Kirigami.Theme.backgroundColor;
        return (bg.r + bg.g + bg.b) < 1.5;
    }
    property color bgColor: useDarkTheme ? "#2d2d2d" : "#808080"
    property color borderColor: useDarkTheme ? "#808080" : "#2d2d2d"

    // devices
    property string gpuDevice: Plasmoid.configuration.gpuDevice || "all"

    // "" in the config means: use the disk the OS root filesystem lives on (detected below)
    property string detectedOsDisk: ""
    property string diskDevice: Plasmoid.configuration.diskDevice || detectedOsDisk || "all"

    onGpuDeviceChanged: { history1 = []; history2 = []; canvas.requestPaint(); }
    onDiskDeviceChanged: { history1 = []; history2 = []; canvas.requestPaint(); }

    P5Support.DataSource {
        id: osDiskSource
        engine: "executable"
        connectedSources: []
    }

    Connections {
        target: osDiskSource
        function onNewData(sourceName, data) {
            if (data["exit code"] === 0) {
                var dev = (data["stdout"] || "").trim();
                if (dev) root.detectedOsDisk = dev;
            }
            osDiskSource.disconnectSource(sourceName);
        }
    }

    Component.onCompleted: {
        // resolve the root filesystem source to its physical disk (follows LUKS/LVM/btrfs layers)
        osDiskSource.connectSource("findmnt -rno SOURCE / | sed 's/\\[.*\\]//' | xargs lsblk -srno NAME,TYPE | awk '$2==\"disk\"{print $1; exit}'");
    }

    // sensor
    Sensors.Sensor { id: cpuUser;      sensorId: "cpu/all/user" }
    Sensors.Sensor { id: cpuSys;       sensorId: "cpu/all/system" }
    Sensors.Sensor { id: cpuTotal;     sensorId: "cpu/all/usage" }
    Sensors.Sensor { id: memUsed;      sensorId: "memory/physical/used" }
    Sensors.Sensor { id: memTotal;     sensorId: "memory/physical/total" }
    Sensors.Sensor { id: gpuUsage;     sensorId: "gpu/" + root.gpuDevice + "/usage" }
    Sensors.Sensor { id: gpuVramUsed;  sensorId: "gpu/" + root.gpuDevice + "/usedVram" }
    Sensors.Sensor { id: gpuVramTotal; sensorId: "gpu/" + root.gpuDevice + "/totalVram" }
    Sensors.Sensor { id: netDown;      sensorId: "network/all/download" }
    Sensors.Sensor { id: netUp;        sensorId: "network/all/upload" }
    Sensors.Sensor { id: diskRead;     sensorId: "disk/" + root.diskDevice + "/read" }
    Sensors.Sensor { id: diskWrite;    sensorId: "disk/" + root.diskDevice + "/write" }

    // history
    property var history1: []
    property var history2: []
    property int maxHistory: isWide ? 70 : 30

    onMaxHistoryChanged: { history1 = []; history2 = []; canvas.requestPaint(); }

    property int currentSensorSource: Plasmoid.configuration.sensorSource
    onCurrentSensorSourceChanged: {
        history1 = [];
        history2 = [];
        canvas.requestPaint();
    }

    // color and line style
    property real fillOpacity: Plasmoid.configuration.fillOpacity / 100.0
    property int lineWidth: Plasmoid.configuration.lineWidth || 1

    property string line1: Plasmoid.configuration.overrideColors
        ? Plasmoid.configuration.customLine1 : getDefaultLineColors()[0]
    property string line2: Plasmoid.configuration.overrideColors
        ? Plasmoid.configuration.customLine2 : getDefaultLineColors()[1]

    property string fill1: line1 === "transparent" ? "transparent" : hexToRgba(line1, fillOpacity)
    property string fill2: line2 === "transparent" ? "transparent" : hexToRgba(line2, fillOpacity)

    function hexToRgba(hex, alpha) {
        var h = hex.replace("#", "");
        var r = parseInt(h.substring(0, 2), 16);
        var g = parseInt(h.substring(2, 4), 16);
        var b = parseInt(h.substring(4, 6), 16);
        if (isNaN(r) || isNaN(g) || isNaN(b)) return "rgba(0,0,0," + alpha + ")";
        return "rgba(" + r + "," + g + "," + b + "," + alpha + ")";
    }

    function getDefaultLineColors() {
        switch (Plasmoid.configuration.sensorSource) {
            case 1:  return ["#FF8040", "transparent"];  // Memory
            case 2:  return ["#0054D1", "#8AB9FF"];      // GPU: Usage, VRAM
            case 3:  return ["#FF6BBC", "#1e3cc8"];      // Network: Down, Up
            case 4:  return ["#FFD700", "#B8860B"];      // Disk: Read, Write
            default: return ["#37b837", "#FF0000"];      // CPU: User, Kernel
        }
    }

    // update interval
    property int updateIntervalMs: Plasmoid.configuration.updateInterval > 0
        ? Plasmoid.configuration.updateInterval : 500

    // tooltip
    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        mainText: {
            switch (Plasmoid.configuration.sensorSource) {
                case 1:  return "Memory";
                case 2:  return "GPU";
                case 3:  return "Network";
                case 4:  return "Disk";
                default: return "CPU";
            }
        }
        subText: root.toolTipSubTextData
    }

    property string toolTipSubTextData: {
        var _cpuTotal = cpuTotal.value;
        var _cpuUser = cpuUser.value;
        var _cpuSys = cpuSys.value;
        var _memUsed = memUsed.value;
        var _memTotal = memTotal.value;
        var _gpuUsage = gpuUsage.value;
        var _gpuVramUsed = gpuVramUsed.value;
        var _gpuVramTotal = gpuVramTotal.value;
        var _netDown = netDown.value;
        var _netUp = netUp.value;
        var _diskRead = diskRead.value;
        var _diskWrite = diskWrite.value;
        var _top = root.topProcessName;

        return buildTooltipSubText();
    }

    property string topProcessName: ""

    function buildTooltipSubText() {
        var src = Plasmoid.configuration.sensorSource;
        var lines = [];

        if (src === 0) {
            var totalCpu = sensorValue(cpuTotal);
            lines.push("Usage: " + totalCpu.toFixed(1) + "%");
            if (topProcessName) lines.push(topProcessName);
        } else if (src === 1) {
            var mUsed = sensorValue(memUsed);
            var mTotal = sensorValue(memTotal);
            lines.push(formatBytes(mUsed) + " / " + formatBytes(mTotal));
            if (topProcessName) lines.push(topProcessName);
        } else if (src === 2) {
            var gUsage = sensorValue(gpuUsage);
            var vUsed = sensorValue(gpuVramUsed);
            var vTotal = sensorValue(gpuVramTotal);
            lines.push("Usage: " + gUsage.toFixed(1) + "%");
            if (vTotal > 0) lines.push("VRAM: " + formatBytes(vUsed) + " / " + formatBytes(vTotal));
        } else if (src === 3) {
            var down = sensorValue(netDown);
            var up = sensorValue(netUp);
            lines.push("Down: " + formatSpeed(down));
            lines.push("Up: " + formatSpeed(up));
        } else if (src === 4) {
            var read = sensorValue(diskRead);
            var write = sensorValue(diskWrite);
            lines.push("Read: " + formatByteSpeed(read));
            lines.push("Write: " + formatByteSpeed(write));
        }
        return lines.join("\n");
    }

    function sensorValue(sensor) {
        var v = sensor.value;
        return (v !== undefined && !isNaN(v)) ? v : 0;
    }

    function formatBytes(bytes) {
        if (bytes <= 0) return "0 B";
        var units = ["B", "KiB", "MiB", "GiB", "TiB"];
        var i = 0;
        var val = bytes;
        while (val >= 1024 && i < units.length - 1) { val /= 1024; i++; }
        return val.toFixed(i > 0 ? 1 : 0) + " " + units[i];
    }

    function formatSpeed(bytesPerSec) {
        var mbits = bytesPerSec * 8 / 1000000;
        if (mbits >= 1000) return (mbits / 1000).toFixed(2) + " Gbit/s";
        if (mbits >= 1) return mbits.toFixed(2) + " Mbit/s";
        return (mbits * 1000).toFixed(1) + " Kbit/s";
    }

    function formatByteSpeed(bytesPerSec) {
        return formatBytes(bytesPerSec) + "/s";
    }

    // top usage process
    P5Support.DataSource {
        id: topProcessSource
        engine: "executable"
        connectedSources: []
    }

    Timer {
        id: topProcessTimer
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            var src = Plasmoid.configuration.sensorSource;
            var cmd = "";
            if (src === 0) cmd = "ps -eo comm --sort=-%cpu --no-headers | head -1";
            else if (src === 1) cmd = "ps -eo comm --sort=-%mem --no-headers | head -1";
            else return;

            if (topProcessSource.connectedSources.length > 0)
                topProcessSource.disconnectSource(topProcessSource.connectedSources[0]);
            topProcessSource.connectSource(cmd);
        }
    }

    Connections {
        target: topProcessSource
        function onNewData(sourceName, data) {
            if (data["exit code"] === 0) {
                root.topProcessName = (data["stdout"] || "").trim();
            }
            topProcessSource.disconnectSource(sourceName);
        }
    }

    // data collection timer
    Timer {
        id: dataTimer
        interval: root.updateIntervalMs
        running: true
        repeat: true
        onTriggered: {
            var src = Plasmoid.configuration.sensorSource;
            var v1 = 0, v2 = 0;

            if (src === 0) {
                v1 = sensorValue(cpuUser);
                v2 = sensorValue(cpuSys);
            } else if (src === 1) {
                var mUsed = sensorValue(memUsed);
                var mTotal = sensorValue(memTotal);
                v1 = mTotal > 0 ? (mUsed / mTotal) * 100 : 0;
            } else if (src === 2) {
                v1 = sensorValue(gpuUsage);
                var vUsed = sensorValue(gpuVramUsed);
                var vTotal = sensorValue(gpuVramTotal);
                v2 = vTotal > 0 ? (vUsed / vTotal) * 100 : 0;
            } else if (src === 3) {
                v1 = sensorValue(netDown);
                v2 = sensorValue(netUp);
            } else if (src === 4) {
                v1 = sensorValue(diskRead);
                v2 = sensorValue(diskWrite);
            }

            var h1 = history1; h1.push(v1);
            var h2 = history2; h2.push(v2);
            while (h1.length > maxHistory) h1.shift();
            while (h2.length > maxHistory) h2.shift();
            history1 = h1;
            history2 = h2;

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
            ctx.clearRect(0, 0, w, h);

            // Background / border
            ctx.fillStyle = root.bgColor;
            ctx.fillRect(0, 0, w, h);
            ctx.strokeStyle = root.borderColor;
            ctx.lineWidth = 1;
            ctx.strokeRect(0.5, 0.5, w - 1, h - 1);

            // clip
            ctx.save();
            ctx.beginPath();
            ctx.rect(1, 1, w - 2, h - 2);
            ctx.clip();

            var maxVal = 100;
            var src = Plasmoid.configuration.sensorSource;
            if (src === 3 || src === 4) {
                var peak = 0;
                var d1 = history1, d2 = history2;
                for (var j = 0; j < d1.length; j++) if (d1[j] > peak) peak = d1[j];
                for (var j = 0; j < d2.length; j++) if (d2[j] > peak) peak = d2[j];
                maxVal = peak > 0 ? peak : 1;
            }

            var plotW = w - 2, plotH = h - 2;
            var step = plotW / (maxHistory - 1);

            var drawGraph = function(data, lineColor, fillColor) {
                if (data.length === 0 || lineColor === "transparent") return;

                var i, x, val, y;

                ctx.beginPath();
                ctx.moveTo(1, h - 1);
                for (i = 0; i < data.length; i++) {
                    x = 1 + i * step;
                    val = data[i] < 0 ? 0 : (data[i] > maxVal ? maxVal : data[i]);
                    y = (h - 1) - (val / maxVal * plotH);
                    ctx.lineTo(x, y);
                }
                ctx.lineTo(1 + (data.length - 1) * step, h - 1);
                ctx.closePath();
                ctx.fillStyle = fillColor;
                ctx.fill();

                ctx.beginPath();
                for (i = 0; i < data.length; i++) {
                    x = 1 + i * step;
                    val = data[i] < 0 ? 0 : (data[i] > maxVal ? maxVal : data[i]);
                    y = (h - 1) - (val / maxVal * plotH);
                    if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
                }
                ctx.strokeStyle = lineColor;
                ctx.lineWidth = root.lineWidth;
                ctx.stroke();
            };

            if (src === 2) {
                // GPU: usage matters more than VRAM, so draw it on top
                drawGraph(history2, root.line2, root.fill2);
                drawGraph(history1, root.line1, root.fill1);
            } else {
                drawGraph(history1, root.line1, root.fill1);
                drawGraph(history2, root.line2, root.fill2);
            }
            ctx.restore();
        }
    }
}