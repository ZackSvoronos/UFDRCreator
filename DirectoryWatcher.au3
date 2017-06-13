#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ColorConstants.au3>
#include <Array.au3>
#include <File.au3>

Local $popups[5] = ['New version is available', 'Did you know…', 'Recover additional location data: Time-limited free service', 'Device time zone detected', 'Convert BSSID (wireless networks) and cell towers to locations: Time-limited free service']

Local $inputDirectory = 'C:\\'
Local $outputDirectory = 'C:\\'
Local $examinerName = 'Example Name'

; title of analyzer window (set when UFED Physical Analyzer starts up)
Local $analyzerWindowName = 'UFED Physical Analyzer 6.2.0.79'

Local $processedFiles[0]

Func Main()

   ; increase default key delay (miliseconds)
   AutoItSetOption('SendKeyDelay', 25)

   LoadConfig()

   ReadCommandLineArgs()

   LoadProcessedFilesLog()

   While True
	  $newFile = NextNewFile()
	  If Not ($newFile = Null) Then
		 ProcessFile($newFile)
	  Else
		 Sleep(1 * 1000)
	  EndIf
   WEnd

EndFunc

Func LoadConfig()

   Local $config
   _FileReadToArray('config', $config, $FRTA_INTARRAYS, '=')

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

Func ReadCommandLineArgs()

   $numArgs = $CmdLine[0]
   For $i = 1 To $numArgs
	  If $CmdLine[$i] == '-i' Then
		 $inputDirectory = $CmdLine[$i+1]
	  ElseIf $CmdLine[$i] == '-o' Then
		 $outputDirectory = $CmdLine[$i+1]
	  ElseIf $CmdLine[$i] == '-e' Then
		 $examinerName = $CmdLine[$i+1]
	  EndIf
   Next

EndFunc

Func LoadProcessedFilesLog()

   $processedFilesLogPath = $inputDirectory & '\processed'
   If FileExists($processedFilesLogPath) Then
	  _FileReadToArray($processedFilesLogPath, $processedFiles, $FRTA_NOCOUNT)
   EndIf

EndFunc

Func SaveProcessedFilesLog()

   $processedFilesLogPath = $inputDirectory & '\processed'
   _FileWriteFromArray($processedFilesLogPath, $processedFiles)

EndFunc

Func NextNewFile()

   ; recursively search for '.ufd' files in the input directory
   $ufds = _FileListToArrayRec($inputDirectory, '*.ufd', $FLTAR_FILES, $FLTAR_RECUR)
   If @error Then
	  ConsoleWrite('IO Error: Error on path ' & $inputDirectory & @CRLF)
	  Return Null
   EndIf

   ; get the first '.ufd' file that hasn't been processed (or return Null if all have been processed)
   For $i = 1 To $ufds[0]
	  If Not ArrayContainsString($processedFiles, GetFileName($ufds[$i])) Then
		 Return $ufds[$i]
	  EndIf
   Next
   Return Null

EndFunc

Func ArrayContainsString($array, $string)

   For $i = 0 To (UBound($array)-1)
	  If $array[$i] == $string Then
		 Return True
	  EndIf
   Next
   Return False

EndFunc

Func ProcessFile($path)

   ShellExecute($inputDirectory & '\' & $path)

   WaitForAnalyzerWindow()

   WaitUntilFinished()

   GenerateReport($path, $outputDirectory, $examinerName)

   ; close UFED Physical Analyzer
   WinActivate($analyzerWindowName)
   WinClose($analyzerWindowName)
   Sleep(1 * 1000)
   If WinExists('Warning') Then
	  Send('{ENTER}')
	  Sleep(1 * 1000)
   EndIf

   _ArrayAdd($processedFiles, GetFileName($path))
   SaveProcessedFilesLog()

EndFunc

Func WaitForAnalyzerWindow()

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
Func GenerateReport($path, $saveDirectory, $examinerName)
   ; File name:
   Send('{TAB 3}')
   Replace(GetFileName($path))
   ; Save to:
   Send('{TAB 2}{ENTER}')
   Sleep(1 * 1000)
   ControlClick('Select Folder', '', 1152)
   Send($saveDirectory)
   Send('{TAB}')
   Send('{ENTER}')
   ; Project
   $windowPosition = WinGetPos('Generate Report')
   $winX = $windowPosition[0]
   $winY = $windowPosition[1]
   $winWidth = $windowPosition[2]
   $winHeight = $windowPosition[3]
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
