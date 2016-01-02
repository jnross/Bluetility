#Bluetility

Bluetility is a general-purpose Bluetooth Low-Energy utility for Mac OS X.  It scans for advertising peripherals, provides a interface to browse a connected peripheral's services and characteristics, and allows characteristic values to be read, written, and subscribed.
<img src="bluetility_screenshot.png" alt="Bluetility Screenshot" width="1085"/>

##Features

* Scan for nearby advertising peripherals
* Sort peripherals by received signal strength
* View advertising data via tooltip on Devices list
* Browse services and characteristics of connected peripheral
* Subscribe to characteristic notifications
* Read/Write characteristic values
* View log of characteristic read/writes, logs may be saved as CSV

##Motivation
Bluetility is inspired by [LightBlue](https://itunes.apple.com/us/app/lightblue/id639944780?mt=12), a free bluetooth utility published by [Punch Through Design](https://punchthrough.com/).  Bluetility was created to resolved issues in this tool, and add missing features:

* Support copy/paste via Cmd+C and Cmd+V
* Sort peripherals by received signal strength
* View advertising data

Bluetility is published as open-source so that anyone can tweak or improve its functionality to meet their own needs.