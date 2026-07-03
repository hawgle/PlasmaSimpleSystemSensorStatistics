# Simple System Sensor Statistics (S4)

<img src="https://raw.githubusercontent.com/hawgle/PlasmaSimpleSystemSensorStatistics/refs/heads/master/imgs/s4-logo.png" height=100>

A simple plasmoid to display system sensor data from your CPU, RAM, GPU, Network Interface or Disk as a line graph in KDE Plasma 6. Inspired by Microsoft's Sysinternals Process Explorer, which has similar functionality on Windows.

<img src="https://github.com/hawgle/PlasmaSimpleSystemSensorStatistics/blob/master/imgs/s4-preview-taskbar.GIF?raw=true" height=100>

<img src="https://github.com/hawgle/PlasmaSimpleSystemSensorStatistics/blob/master/imgs/s4-preview-desktop.gif?raw=true" height=200>

## Installation

Make sure you're running KDE Plasma 6.

### From within Plasma

1. In edit mode, go to 'Add or manage Widgets' > 'Get New' > 'Download new Plasma Widgets'.
2. Search for 'Simple System Sensor Statistics'
3. Select 'install'. After some time or a restart of the plasma shell, S4 should be visible in your list of widgets in edit mode.

You can also install the widget from KDE Discover. In Discover, go to 'Plasma Addons' > 'Plasma Widgets' and search for 'Simple System Sensor Statistics'.

### From file

1. Download the .plasmoid file from the newest Release
2. In edit mode, under 'add Widgets', select 'Install from local file'
3. Select your downloaded .plasmoid file.

## Usage

By default, S4 will show you CPU usage in usermode (Green) and kernelmode (Red). Hovering over the widget will show you the current usage in percent and the process that is currently responsible for most of that usage.

Change to a different sensor source by right-clicking the widget and selecting <u>*Configure Simple System Sensor Statistics*.</u>

The graph behaviour changes with different sensor sources: If Memory is selected, a single orange graph showing physical memory usage will be drawn. 

For the GPU Source, a dark blue graph for GPU usage is drawn on top of a light blue graph for VRAM usage. If you have more than one GPU, you can pick which one to monitor (or all of them combined) in the settings.

The Network source will draw a pink graph for Download and a purple graph for Upload. As Network works with absolute units instead of percent, the graph will auto-scale to fit the data in its displayed history.

Lastly, the Disk source will draw a yellow graph for Read and a dark yellow graph for Write activity. By default it monitors the disk your OS drive is on, but you can pick a different disk (or all of them combined) in the settings. Like Network, it works with absolute units and auto-scales.

S4 was made for use in the plasma taskbar, but it does work on the desktop. I suggest making use of the line thickness setting to your liking when the graph is larger. If your panel is on the thicker side, the graph size setting lets you shrink the graph relative to the panel.