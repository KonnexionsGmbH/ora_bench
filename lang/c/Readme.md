# Usage
## Windows
C++ Win toolchains
1. Download and run VS Community Installer from https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=Community&rel=16
2. In the installer wizard's Available tab choose "Desktop development with C++" option
3. On the right select (if not already selected): MSVC v142, Windows 10 SDK, C++ profiling tools, C++ CMake tools for windows till C++ Address sanitizer (default selected for clean installtion)
4. Download and install Git - https://git-scm.com/download/win

```cmd
ora_bench\lang\c> call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
ora_bench\lang\c> nmake -f Makefile.win32
ora_bench\lang\c> ./OraBench.exe ../priv/properties/ora_bench.properties 
```
## Linux
_TBD_
