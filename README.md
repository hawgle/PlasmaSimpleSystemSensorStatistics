# Simple System Sensor Statistics (S4)

<img src="" width=100>

A simple plasmoid to display system sensor data from your CPU, RAM, GPU or Network Interface as a line graph in KDE Plasma 6. Inspired by Microsoft's Sysinternals Process Explorer, which has similar functionality on Windows.

## Installation

### 

## Use

By default, S4 will show you CPU usage in usermode (Green) and kernelmode (Red). Hovering over the widget will show you the current usage in percent and the process that is currently responsible for most of that usage.

Change to a different sensor source by right-clicking the widget and selecting <u>*Configure Simple System Sensor Statistics*.</u>

The graph behaviour changes with different sensor sources: If Memory is selected, a single orange graph showing physical memory usage will be drawn. 

For the GPU Source, a dark blue graph for GPU usage and a light blue graph for VRAM usage will be drawn.

Lastly, the Network source will draw a pink graph for Download and a purple graph for Upload. As the Network source is the only Source that works with absolute units instead of percent, the graph will auto-scale to fit the data in its displayed history.

S4 was made for use in the plasma taskbar, but it does work on the desktop. I suggest making use of the line thickness setting to your liking when the graph is larger.