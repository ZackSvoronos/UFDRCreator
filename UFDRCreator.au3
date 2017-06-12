#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ColorConstants.au3>
#include <Array.au3>
#include <File.au3>

Local $popups[5] = ['New version is available', 'Did you know…', 'Recover additional location data: Time-limited free service', 'Device time zone detected', 'Convert BSSID (wireless networks) and cell towers to locations: Time-limited free service']

Local $examinerName = 'Example Name'
Local $inputDirectory = 'C;\\'
Local $outputDirectory = 'C:\\'

Local $config
Local $fileName = 'config'

; title of analyzer window
Local $analyzerWindowName = 'UFED Physical Analyzer 6.2.0.79'

Func Main()

   ; increase default key delay (miliseconds)
   AutoItSetOption('SendKeyDelay', 25)

   LoadConfig()

   ; recursively search for '.ufd' files in the input directory
   $ufdsInDirectory = _FileListToArrayRec($inputDirectory, '*.ufd', $FLTAR_FILES, $FLTAR_RECUR)
   If @error Then
	  ConsoleWrite('IO Error: Error on path ' & $inputDirectory & @CRLF)
	  return
   EndIf

   $numUfds = $ufdsInDirectory[0]
   For $i = 1 To $numUfds
	  ShellExecute($inputDirectory & '\' & $ufdsInDirectory[$i])
	  ; sleep after the first '.ufd' to let program start up
	  If $i = 1 Then
		 WaitForAnalyzerWindow()
	  EndIf
   Next

   WaitUntilFinished()

   For $i = 0 To ($numUfds-1)
	  GenerateReport($ufdsInDirectory, $i, $outputDirectory, $examinerName)
	  Sleep(1 * 1000)
   Next

   WinActivate($analyzerWindowName)
   WinClose($analyzerWindowName)
   Sleep(1 * 1000)
   If WinExists('Warning') Then
	  Send('{ENTER}')
   EndIf

EndFunc

; load configuration file
Func LoadConfig()

   _FileReadToArray($fileName, $config, 2, '=')

   $numLines = UBound($config)
   For $i = 0 To ($numLines-1)
	  $param = StringStripWS(($config[$i])[0], BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING))
	  $value = StringStripWS(($config[$i])[1], BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING))
	  If $param == 'Examiner Name' Then
		 $examinerName = $value
	  ElseIf $param == 'Input Directory' Then
		 $inputDirectory = $value
	  ElseIf $param == 'Output Directory' Then
		 $outputDirectory = $value
	  EndIf
   Next

EndFunc

func WaitForAnalyzerWindow()

   While True
	  $windows = WinList()

	  For $i = 1 To $windows[0][0]
		 If StringInStr($windows[$i][0], 'UFED Physical Analyzer') Then
			$analyzerWindowName = $windows[$i][0]
			Sleep(10 * 1000)
			return
		 EndIf
	  Next

	  Sleep(10 * 1000)
   WEnd

EndFunc

Func CloseAllPopups()
   While PopupsExist()
	  ClosePopups()
	  Sleep(1000)
   Wend
EndFunc

Func PopupsExist()
   $popups_len = UBound($popups)
   For $i = 0 to ($popups_len-1)
	  if WinExists($popups[$i]) Then
		 return True
	  EndIf
   Next
   return False
EndFunc

Func ClosePopups()
   $popups_len = UBound($popups)
   For $i = 0 to ($popups_len-1)
	  if WinExists($popups[$i]) Then
		 WinClose($popups[$i])
	  EndIf
   Next
EndFunc

Func WaitUntilFinished()
   While Not (WinExists('Generate Report'))
	  Sleep(9 * 1000)
	  CloseAllPopups()
	  ; try to generate a report (only succeeds when all '.ufds' are finished processing)
	  WinActivate($analyzerWindowName)
	  Send('^r')
	  Sleep(1 * 1000)
   WEnd
EndFunc

Func GetFileName($path)
   $sDrive = ''
   $sDir = ''
   $sFileName = ''
   $sExtension = ''
   $aPathSplit = _PathSplit($path, $sDrive, $sDir, $sFileName, $sExtension)
   return $sFileName
EndFunc

; generate a report for the given ufd
Func GenerateReport($ufds, $index, $saveDirectory, $examinerName)
   ; open generate report window (already open for first report)
   If Not ($index = 0) Then
	  WinActivate($analyzerWindowName)
	  Send('^r')
	  Sleep(1 * 1000)
   EndIf
   ; File name:
   Send('{TAB 3}')
   Replace(GetFileName($ufds[$index+1]))
   ; Save to:
   Send('{TAB 2}{ENTER}')
   Send($saveDirectory)
   Send('{TAB}')
   Send('{ENTER}')
   ; Project
   $windowPosition = WinGetPos('Generate Report')
   $winX = $windowPosition[0]
   $winY = $windowPosition[1]
   $winWidth = $windowPosition[2]
   $winHeight = $windowPosition[3]
   ; if there is more than one '.ufd' file, select the right one from the drop down menu
   If Not ($ufds[0] = 1) Then
	  MouseClick("left", $winX + 600, $winY + 200, 1, 0)
	  Send('{HOME}{DOWN ' & $index & '}{SPACE}')
	  Send('{END}{DOWN}{ENTER}')
   EndIf
   Sleep(1000)
   ; Format
   MouseClick("left", $winX + 600, $winY + 230, 1, 0)
   Send('{HOME}{SPACE}')
   Send('{END}{DOWN}{ENTER}')
   ; Examiner Name
   MouseClick('left', $winX + 600, $winY + 390, 1, 0)
   Send($examinerName)
   Sleep(1000)
   ; click Next
   MouseClick('left', $winX + $winWidth - 300, $winY + $winHeight - 30, 1, 0)
   Sleep(1000)
   ; click Finish
   MouseClick('left', $winX + $winWidth - 180, $winY + $winHeight - 30, 1, 0)
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

Main()
