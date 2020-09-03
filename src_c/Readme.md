# Usage
## Windows
C++ Win toolchains
1. Download and run VS Community Installer from https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=Community&rel=16
1. In the installer wizard's Available tab choose "Desktop development with C++" option
1. On the right select (if not already selected): MSVC v142, Windows 10 SDK, C++ profiling tools, C++ CMake tools for windows till C++ Address sanitizer (default selected for clean installtion)
1. Download and install Git - https://git-scm.com/download/win

Oracle Instant Client Installation
1. Download Basic Light zip from https://www.oracle.com/database/technologies/instant-client/winx64-64-downloads.html
1. Unzip at C:/Oracle (create the directory if it doesn't exit). You can also choose a different instal folder. The folloing instructions assumes you choose C:/Oracle
1. Add C:\Oracle\instantclient_v...v_v...v to PATH environment variable

```cmd
ora_bench\src_c> nmake -f Makefile.win32
ora_bench\src_c> ./OraBench.exe ../priv/properties/ora_bench.properties 
```
## Linux
_TBD_
