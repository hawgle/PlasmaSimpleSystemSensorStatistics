import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configRoot

    property int cfg_widgetShape
    property int cfg_themeMode
    property int cfg_updateSpeed
    property alias cfg_sensorSource: sensorCombo.currentIndex
    property alias cfg_fillOpacity: opacitySlider.value
    property alias cfg_overrideColors: overrideCheck.checked
    property alias cfg_customLine1: line1Field.text
    property alias cfg_customLine2: line2Field.text
    property alias cfg_lineWidth: lineWidthSlider.value

    property int cfg_widgetShapeDefault: 0
    property int cfg_themeModeDefault: 2
    property int cfg_updateSpeedDefault: 1
    property int cfg_sensorSourceDefault: 0
    property int cfg_fillOpacityDefault: 40
    property bool cfg_overrideColorsDefault: false
    property string cfg_customLine1Default: "#37b837"
    property string cfg_customLine2Default: "#FF0000"
    property int cfg_lineWidthDefault: 1

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
        QQC2.ButtonGroup {
            id: speedGroup
        }

        QQC2.RadioButton {
            id: speedNormal
            Kirigami.FormData.label: "Update Speed:"
            QQC2.ButtonGroup.group: speedGroup
            text: "1000ms"
            checked: cfg_updateSpeed === 0
            onClicked: if (checked) cfg_updateSpeed = 0
        }

        QQC2.RadioButton {
            id: speedFast
            QQC2.ButtonGroup.group: speedGroup
            text: "500ms"
            checked: cfg_updateSpeed === 1
            onClicked: if (checked) cfg_updateSpeed = 1
        }

        QQC2.RadioButton {
            id: speedFastest
            QQC2.ButtonGroup.group: speedGroup
            text: "250ms"
            checked: cfg_updateSpeed === 2
            onClicked: if (checked) cfg_updateSpeed = 2
        }

        // spacing
        Item {
            Kirigami.FormData.isSection: true
        }

        // sensor data source
        QQC2.ComboBox {
            id: sensorCombo
            Kirigami.FormData.label: "Sensor Source:"
            model: ["CPU", "Memory", "GPU", "Network"]
        }

        // spacing
        Item {
            Kirigami.FormData.isSection: true
        }

        // color settings
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

        QQC2.TextField {
            id: line1Field
            Kirigami.FormData.label: "Line 1 Color:"
            enabled: overrideCheck.checked
        }

        QQC2.TextField {
            id: line2Field
            Kirigami.FormData.label: "Line 2 Color:"
            enabled: overrideCheck.checked
        }
    }
}