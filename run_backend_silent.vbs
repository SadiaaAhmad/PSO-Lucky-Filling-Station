Set WshShell = CreateObject("WScript.Shell")
WshShell.CurrentDirectory = "c:\Users\Sadia Ahmad\FuelStationAccounting"
WshShell.Run "cmd /c set PYTHONPATH=c:\Users\Sadia Ahmad\FuelStationAccounting && C:\Python314\python.exe -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000", 0, False
