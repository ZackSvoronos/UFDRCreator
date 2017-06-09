#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ColorConstants.au3>
#include <Array.au3>
#include <File.au3>

Local $popups[5] = ['New version is available', 'Did you know…', 'Recover additional location data: Time-limited free service', 'Device time zone detected', 'Convert BSSID (wireless networks) and cell towers to locations: Time-limited free service']

Local $examinerName = ''
Local $outputDirectory = 'C:\\'

Local $config
Local $fileName = 'config'

_FileReadToArray($fileName, $config, 2, '=')

$numLines = UBound($config)
For $i = 0 To ($numLines-1)
   $param = StringStripWS(($config[$i])[0], BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING))
   $value = StringStripWS(($config[$i])[1], BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING))
   If $param == 'Examiner Name' Then
	  $examinerName = $value
   ElseIf $param == 'Output Directory' Then
	  $fileName = $value
   EndIf
Next

UFEDReader()

Func UFEDReader()

   $FilePath = 'C:\Users\Zack\Documents\My UFED Extractions'
   Local $ufdsInDirectory = _FileListToArrayRec($FilePath, '*.ufd', $FLTAR_FILES, $FLTAR_RECUR)
   ;_ArrayDisplay($ufdsInDirectory, "File Display")

   For $i = 1 To $ufdsInDirectory[0]
	  ShellExecute($FilePath & '\' & $ufdsInDirectory[$i])
	  ; Sleep to let program startup
	  If $i = 1 Then
		 Sleep(20 * 1000)
	  EndIf
   Next

   WaitUntilFinished()

   WinClose('Device time zone detected')
   Sleep(1000)
   WinClose('Convert BSSID (wireless networks) and cell towers to locations: Time-limited free service')
   Sleep(1000)

   For $i = 0 To ($ufdsInDirectory[0]-1)
	  GenerateReport($ufdsInDirectory, $i, $outputDirectory, $examinerName)
	  Sleep(1000)
   Next

WinActivate('UFED Physical Analyzer 6.2.0.79')
WinClose('UFED Physical Analyzer 6.2.0.79')

EndFunc

Func CloseAllPopups()
   While PopupsExist()
	  ClosePopups()
	  Sleep(1000)
   Wend
EndFunc

Func PopupsExist()
   $popups_len = (UBound($popups)-1)
   For $i = 0 to $popups_len
	  if WinExists($popups[$i]) Then
		 return True
	  EndIf
   Next
   return False
EndFunc

Func ClosePopups()
   $popups_len = (UBound($popups)-1)
   For $i = 0 to $popups_len
	  if WinExists($popups[$i]) Then
		 WinClose($popups[$i])
	  EndIf
   Next
EndFunc

Func WaitUntilFinished()
   While Not(WinExists('Generate Report'))
	  Sleep(1 * 1000)
	  CloseAllPopups()
	  Send('^r')
   WEnd
   WinClose('Generate Report')
EndFunc

Func GetFileName($path)
   $sDrive = ''
   $sDir = ''
   $sFileName = ''
   $sExtension = ''
   $aPathSplit = _PathSplit($path, $sDrive, $sDir, $sFileName, $sExtension)
   return $sFileName
EndFunc

;~ generate a report for the given ufd
Func GenerateReport($ufds, $index, $saveDirectory, $examinerName)
   WinActivate('UFED Physical Analyzer 6.2.0.79')
   Send('^r')
   ; File name:
   Send('{TAB 3}')
   Replace(GetFileName($ufds[$index+1]))
   ; Save to:
   Send('{TAB}')
   Replace($saveDirectory)
   ; Project
   $windowPosition = WinGetPos('Generate Report')
   If Not ($ufds[0] = 1) Then
	  MouseClick("left", $windowPosition[0] + 600, $windowPosition[1] + 200, 1, 0)
	  Send('{HOME}{DOWN ' & $index & '}{SPACE}')
	  Send('{END}{DOWN}{ENTER}')
   EndIf
   ; Format
   MouseClick("left", $windowPosition[0] + 600, $windowPosition[1] + 230, 1, 0)
   Send('{HOME}{SPACE}')
   Send('{END}{DOWN}{ENTER}')
   ; Examiner Name
   MouseClick('left', $windowPosition[0] + 600, $windowPosition[1] + 390, 1, 0)
   Send($examinerName)
   ; Finish
   Send('{TAB 4}')
   Send('{ENTER}')
   Sleep(100)
   Send('{TAB}')
   Send('{ENTER}')
   ; wait for report to run
   WinWait('Generated report')
   WinActivate('Generated report')
   Send('{TAB}')
   Send('{ENTER}')
EndFunc


Func Replace($str)
   Send('^a')
   Send($str)
EndFunc



