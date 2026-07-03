import QtQuick
import QtQml.Models
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.plasma5support as P5Support

KCM.SimpleKCM {
    id: configRoot

    property int cfg_widgetShape
    property int cfg_themeMode
    property alias cfg_updateInterval: updateSlider.value
    property alias cfg_sensorSource: sensorCombo.currentIndex
    property string cfg_diskDevice
    property string cfg_gpuDevice
    property alias cfg_graphSize: graphSizeSlider.value
    property alias cfg_fillOpacity: opacitySlider.value
    property alias cfg_overrideColors: overrideCheck.checked
    property string cfg_customLine1
    property string cfg_customLine2
    property alias cfg_lineWidth: lineWidthSlider.value

    property int cfg_widgetShapeDefault: 0
    property int cfg_themeModeDefault: 2
    property int cfg_updateIntervalDefault: 500
    property int cfg_sensorSourceDefault: 0
    property string cfg_diskDeviceDefault: ""
    property string cfg_gpuDeviceDefault: "all"
    property int cfg_graphSizeDefault: 100
    property int cfg_fillOpacityDefault: 40
    property bool cfg_overrideColorsDefault: false
    property string cfg_customLine1Default: "#37b837"
    property string cfg_customLine2Default: "#FF0000"
    property int cfg_lineWidthDefault: 1

    // keep the device combos and color buttons in sync when the config
    // is loaded or reset to defaults
    onCfg_gpuDeviceChanged: syncGpuCombo()
    onCfg_diskDeviceChanged: syncDiskCombo()
    onCfg_customLine1Changed: line1Button.color = cfg_customLine1
    onCfg_customLine2Changed: line2Button.color = cfg_customLine2

    function syncGpuCombo() {
        gpuCombo.currentIndex = Math.max(0, gpuCombo.indexOfValue(cfg_gpuDevice));
    }

    function syncDiskCombo() {
        diskCombo.currentIndex = Math.max(0, diskCombo.indexOfValue(cfg_diskDevice));
    }

    // available GPUs, probed via their name sensor (numbering is not
    // guaranteed to start at 0, so probe a small range)
    ListModel {
        id: gpuModel
        ListElement { label: "All GPUs"; value: "all"; sortKey: -1 }
    }

    Instantiator {
        model: 8
        delegate: Sensors.Sensor {
            sensorId: "gpu/gpu" + index + "/name"
            onValueChanged: {
                if (value !== undefined && value !== "")
                    configRoot.registerGpu(index, String(value));
            }
        }
    }

    function registerGpu(idx, name) {
        var dev = "gpu" + idx;
        var label = dev + " — " + name;
        for (var i = 1; i < gpuModel.count; i++) {
            if (gpuModel.get(i).value === dev) {
                gpuModel.setProperty(i, "label", label);
                return;
            }
            if (gpuModel.get(i).sortKey > idx) {
                gpuModel.insert(i, { label: label, value: dev, sortKey: idx });
                syncGpuCombo();
                return;
            }
        }
        gpuModel.append({ label: label, value: dev, sortKey: idx });
        syncGpuCombo();
    }

    // available disks, enumerated via lsblk
    ListModel {
        id: diskModel
        ListElement { label: "Automatic (OS Drive)"; value: "" }
        ListElement { label: "All Disks"; value: "all" }
    }

    P5Support.DataSource {
        id: lsblkSource
        engine: "executable"
        connectedSources: []
    }

    Connections {
        target: lsblkSource
        function onNewData(sourceName, data) {
            if (data["exit code"] === 0)
                configRoot.parseLsblk(data["stdout"] || "");
            lsblkSource.disconnectSource(sourceName);
        }
    }

    Component.onCompleted: lsblkSource.connectSource("lsblk -d -J -o NAME,TYPE,MODEL")

    function parseLsblk(out) {
        try {
            var devices = JSON.parse(out).blockdevices || [];
            for (var i = 0; i < devices.length; i++) {
                var d = devices[i];
                if (d.type !== "disk" || d.name.indexOf("zram") === 0) continue;
                var label = d.name + (d.model ? " — " + String(d.model).trim() : "");
                diskModel.append({ label: label, value: d.name });
            }
        } catch (e) {}
        syncDiskCombo();
    }

    Kirigami.FormLayout {
        // widget Shape
        QQC2.ButtonGroup {
            id: shapeGroup
        }

        QQC2.RadioButton {
            id: shapeSquare
            Kirigami.FormData.label: "Shape:"
            QQC2.ButtonGroup.group: shapeGroup
            text: "Square"
            checked: cfg_widgetShape === 0
            onClicked: if (checked) cfg_widgetShape = 0
        }

        QQC2.RadioButton {
            id: shapeWide
            QQC2.ButtonGroup.group: shapeGroup
            text: "Wide"
            checked: cfg_widgetShape === 1
            onClicked: if (checked) cfg_widgetShape = 1
        }

        // spacing
        Item {
            Kirigami.FormData.isSection: true
        }

        // theme
        QQC2.ButtonGroup {
            id: themeGroup
        }

        QQC2.RadioButton {
            id: themeDark
            Kirigami.FormData.label: "Theme:"
            QQC2.ButtonGroup.group: themeGroup
            text: "Dark"
            checked: cfg_themeMode === 0
            onClicked: if (checked) cfg_themeMode = 0
        }

        QQC2.RadioButton {
            id: themeLight
            QQC2.ButtonGroup.group: themeGroup
            text: "Light"
            checked: cfg_themeMode === 1
            onClicked: if (checked) cfg_themeMode = 1
        }

        QQC2.RadioButton {
            id: themeSystem
            QQC2.ButtonGroup.group: themeGroup
            text: "Follow System"
            checked: cfg_themeMode === 2
            onClicked: if (checked) cfg_themeMode = 2
        }

        // spacing
        Item {
            Kirigami.FormData.isSection: true
        }

        // update speed
        RowLayout {
            Kirigami.FormData.label: "Update Speed:"
            QQC2.Slider {
                id: updateSlider
                from: 100
                to: 2000
                stepSize: 50
                Layout.preferredWidth: 180
            }
            QQC2.Label {
                text: Math.round(updateSlider.value) + " ms"
                Layout.preferredWidth: 55
            }
        }

        // spacing
        Item {
            Kirigami.FormData.isSection: true
        }

        // sensor data source
        QQC2.ComboBox {
            id: sensorCombo
            Kirigami.FormData.label: "Sensor Source:"
            model: ["CPU", "Memory", "GPU", "Network", "Disk"]
        }

        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 21
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            text: {
                switch (sensorCombo.currentIndex) {
                    case 1:  return "Draws a single orange graph showing physical memory usage. Hovering shows usage and the process using the most memory.";
                    case 2:  return "Draws GPU usage (dark blue) on top of VRAM usage (light blue). Hovering shows both values.";
                    case 3:  return "Draws download (pink) and upload (blue). Works with absolute units instead of percent, so the graph auto-scales to fit its displayed history.";
                    case 4:  return "Draws disk read (yellow) and write (dark yellow) activity. Works with absolute units instead of percent, so the graph auto-scales to fit its displayed history.";
                    default: return "Draws CPU usage in usermode (green) and kernelmode (red). Hovering shows total usage and the process currently using the most CPU.";
                }
            }
        }

        QQC2.ComboBox {
            id: gpuCombo
            Kirigami.FormData.label: "GPU Device:"
            visible: sensorCombo.currentIndex === 2
            model: gpuModel
            textRole: "label"
            valueRole: "value"
            onActivated: cfg_gpuDevice = String(currentValue)
        }

        QQC2.ComboBox {
            id: diskCombo
            Kirigami.FormData.label: "Disk Device:"
            visible: sensorCombo.currentIndex === 4
            model: diskModel
            textRole: "label"
            valueRole: "value"
            onActivated: cfg_diskDevice = String(currentValue)
        }

        // spacing
        Item {
            Kirigami.FormData.isSection: true
        }

        // graph appearance
        RowLayout {
            Kirigami.FormData.label: "Graph Size:"
            QQC2.Slider {
                id: graphSizeSlider
                from: 20
                to: 100
                stepSize: 5
                Layout.preferredWidth: 180
            }
            QQC2.Label {
                text: Math.round(graphSizeSlider.value) + "%"
                Layout.preferredWidth: 40
            }
        }

        RowLayout {
            Kirigami.FormData.label: "Fill Opacity:"
            QQC2.Slider {
                id: opacitySlider
                from: 0
                to: 100
                stepSize: 5
                Layout.preferredWidth: 180
            }
            QQC2.Label {
                text: Math.round(opacitySlider.value) + "%"
                Layout.preferredWidth: 40
            }
        }

        RowLayout {
            Kirigami.FormData.label: "Line Thickness:"
            QQC2.Slider {
                id: lineWidthSlider
                from: 1
                to: 5
                stepSize: 1
                Layout.preferredWidth: 180
            }
            QQC2.Label {
                text: Math.round(lineWidthSlider.value) + " px"
                Layout.preferredWidth: 40
            }
        }

        QQC2.CheckBox {
            id: overrideCheck
            Kirigami.FormData.label: "Custom Colors:"
            text: "Override default line colors"
        }

        KQuickControls.ColorButton {
            id: line1Button
            Kirigami.FormData.label: "Line 1 Color:"
            enabled: overrideCheck.checked
            showAlphaChannel: false
            onColorChanged: {
                var s = color.toString();
                if (s.toLowerCase() !== String(cfg_customLine1).toLowerCase())
                    cfg_customLine1 = s;
            }
        }

        KQuickControls.ColorButton {
            id: line2Button
            Kirigami.FormData.label: "Line 2 Color:"
            enabled: overrideCheck.checked
            showAlphaChannel: false
            onColorChanged: {
                var s = color.toString();
                if (s.toLowerCase() !== String(cfg_customLine2).toLowerCase())
                    cfg_customLine2 = s;
            }
        }
    }
}
