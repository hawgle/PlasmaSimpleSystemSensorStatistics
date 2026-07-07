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

    property alias cfg_widgetShape: shapeCombo.currentIndex
    property alias cfg_themeMode: themeCombo.currentIndex
    property alias cfg_updateInterval: updateRow.value
    property alias cfg_sensorSource: sensorCombo.currentIndex
    property string cfg_diskDevice
    property string cfg_gpuDevice
    property alias cfg_graphSize: graphSizeRow.value
    property alias cfg_fillOpacity: opacityRow.value
    property alias cfg_overrideColors: overrideCheck.checked
    property string cfg_customLine1
    property string cfg_customLine2
    property alias cfg_lineWidth: lineWidthRow.value

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

    // sync
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

    // gpu probe
    property var gpuNames: ({})

    ListModel { id: gpuModel }

    Instantiator {
        model: 8
        delegate: Sensors.Sensor {
            sensorId: "gpu/gpu" + index + "/name"
            onValueChanged: if (value) {
                configRoot.gpuNames[index] = String(value);
                configRoot.rebuildGpuModel();
            }
        }
    }

    function rebuildGpuModel() {
        gpuModel.clear();
        gpuModel.append({ label: i18n("All GPUs"), value: "all" });
        for (var i = 0; i < 8; i++)
            if (gpuNames[i]) gpuModel.append({ label: "gpu" + i + " — " + gpuNames[i], value: "gpu" + i });
        syncGpuCombo();
    }

    // disk list
    ListModel { id: diskModel }

    P5Support.DataSource {
        id: lsblkSource
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            if (data["exit code"] === 0) configRoot.parseLsblk(data.stdout || "");
            disconnectSource(sourceName);
        }
    }

    function parseLsblk(out) {
        try {
            for (const d of JSON.parse(out).blockdevices) {
                if (d.type !== "disk" || d.name.indexOf("zram") === 0) continue;
                diskModel.append({ label: d.name + (d.model ? " — " + String(d.model).trim() : ""), value: d.name });
            }
        } catch (e) {}
        syncDiskCombo();
    }

    Component.onCompleted: {
        rebuildGpuModel();
        diskModel.append({ label: i18n("System Boot drive"), value: "" });
        diskModel.append({ label: i18n("All Disks"), value: "all" });
        lsblkSource.connectSource("lsblk -d -J -o NAME,TYPE,MODEL");
    }

    // slider row
    component SliderRow: RowLayout {
        id: row
        property alias from: control.from
        property alias to: control.to
        property alias stepSize: control.stepSize
        property alias value: control.value
        property string suffix

        QQC2.Slider {
            id: control
            Layout.preferredWidth: 180
        }
        QQC2.Label {
            text: Math.round(control.value) + row.suffix
            Layout.preferredWidth: 55
        }
    }

    Kirigami.FormLayout {
        // appearance
        QQC2.ComboBox {
            id: shapeCombo
            Kirigami.FormData.label: i18n("Shape:")
            model: [i18n("Square"), i18n("Wide")]
        }

        QQC2.ComboBox {
            id: themeCombo
            Kirigami.FormData.label: i18n("Theme:")
            model: [i18n("Dark"), i18n("Light"), i18n("Follow System")]
        }

        SliderRow {
            id: updateRow
            Kirigami.FormData.label: i18n("Update Speed:")
            from: 100
            to: 2000
            stepSize: 50
            suffix: " ms"
        }

        Item { Kirigami.FormData.isSection: true }

        // sensor
        QQC2.ComboBox {
            id: sensorCombo
            Kirigami.FormData.label: i18n("Sensor:")
            model: [i18n("CPU"), i18n("Memory"), i18n("GPU"), i18n("Network"), i18n("Disk")]
        }

        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 21
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            text: {
                switch (sensorCombo.currentIndex) {
                    case 1:  return i18n("Draws a single orange graph showing physical memory usage. Hovering shows usage and the process using the most memory.");
                    case 2:  return i18n("Draws GPU usage (dark blue) on top of VRAM usage (light blue). Hovering shows both values.");
                    case 3:  return i18n("Draws download (pink) and upload (blue). Works with absolute units instead of percent, so the graph auto-scales to fit its displayed history.");
                    case 4:  return i18n("Draws disk read (yellow) and write (dark yellow) activity. Works with absolute units instead of percent, so the graph auto-scales to fit its displayed history.");
                    default: return i18n("Draws CPU usage in usermode (green) and kernelmode (red). Hovering shows total usage and the process currently using the most CPU.");
                }
            }
        }

        QQC2.ComboBox {
            id: gpuCombo
            Kirigami.FormData.label: i18n("Device:")
            visible: sensorCombo.currentIndex === 2
            model: gpuModel
            textRole: "label"
            valueRole: "value"
            onActivated: cfg_gpuDevice = String(currentValue)
        }

        QQC2.ComboBox {
            id: diskCombo
            Kirigami.FormData.label: i18n("Device:")
            visible: sensorCombo.currentIndex === 4
            model: diskModel
            textRole: "label"
            valueRole: "value"
            onActivated: cfg_diskDevice = String(currentValue)
        }

        Item { Kirigami.FormData.isSection: true }

        // graph style
        SliderRow {
            id: graphSizeRow
            Kirigami.FormData.label: i18n("Graph Size:")
            from: 20
            to: 100
            stepSize: 5
            suffix: "%"
        }

        SliderRow {
            id: opacityRow
            Kirigami.FormData.label: i18n("Fill Opacity:")
            from: 0
            to: 100
            stepSize: 5
            suffix: "%"
        }

        SliderRow {
            id: lineWidthRow
            Kirigami.FormData.label: i18n("Line Thickness:")
            from: 1
            to: 5
            stepSize: 1
            suffix: " px"
        }

        QQC2.CheckBox {
            id: overrideCheck
            Kirigami.FormData.label: i18n("Custom Colors:")
            text: i18n("Override default line colors")
        }

        KQuickControls.ColorButton {
            id: line1Button
            Kirigami.FormData.label: i18n("Line 1 Color:")
            enabled: overrideCheck.checked
            showAlphaChannel: false
            onColorChanged: {
                var s = color.toString();
                if (s.toLowerCase() !== String(cfg_customLine1).toLowerCase()) cfg_customLine1 = s;
            }
        }

        KQuickControls.ColorButton {
            id: line2Button
            Kirigami.FormData.label: i18n("Line 2 Color:")
            enabled: overrideCheck.checked
            showAlphaChannel: false
            onColorChanged: {
                var s = color.toString();
                if (s.toLowerCase() !== String(cfg_customLine2).toLowerCase()) cfg_customLine2 = s;
            }
        }
    }
}
