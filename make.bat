@echo off
setlocal
rem Makefile.mk defaults PYTHON2 to Python 2.7; the asset scripts now run on Python 3.
if not defined PYTHON2 set PYTHON2=py -3
bin\snmake.exe -f Makefile.mk %1 %2 %3 %4 %5 %6 %7 %8 %9