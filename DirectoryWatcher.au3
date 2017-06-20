#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ColorConstants.au3>
#include <Array.au3>
#include <File.au3>

Local $popups[5] = ['New version is available', 'Did you know…', 'Recover additional location data: Time-limited free service', 'Device time zone detected', 'Convert BSSID (wireless networks) and cell towers to locations: Time-limited free service']

; these are read from the config file or overwritten by command line arguments
Local $inputDirectory = ''
Local $outputDirectory = ''
Local $finalLocation = ''
Local $examinerName = ''

; title of analyzer window (this is just an example, variable is set when program starts up)
Local $analyzerWindowName = 'UFED Physical Analyzer 6.2.0.79'

; list of '.ufd' files that have been successfully processed or failed to process (will not be retried)
Local $processedFiles[0]
Local $failedFiles[0]

Func Main()
   ; increase default key delay (miliseconds)
   AutoItSetOption('SendKeyDelay', 25)

   LoadConfig()

   ReadCommandLineArgs()

   ; check that all directories are valid
   CheckDirIsValid($inputDirectory)
   CheckDirIsValid($outputDirectory)
   CheckDirIsValid($finalLocation)

   LoadFileLogs()

   ; look for new '.ufd' files in the input directory to process
   ; if none are found, wait and retry
   While True
	  $newFile = NextNewFile()
	  If Not ($newFile = Null) Then
		 ProcessFile($newFile)
	  Else
		 Sleep(1 * 1000)
	  EndIf
   WEnd
EndFunc

Func CheckDirIsValid($path)
   If (Not FileExists($path)) Or (Not StringInStr(FileGetAttrib($path), 'D')) Then
	  ConsoleWrite('Error: ' & $path & ' is not a valid directory' & @CRLF)
	  Exit 1
   EndIf
EndFunc

Func LoadConfig()
   Local $config
   _FileReadToArray('config', $config, $FRTA_INTARRAYS, '=')

   For $i = 0 To (UBound($config)-1)
	  $param = StringStripWS(($config[$i])[0], BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING))
	  $value = StringStripWS(($config[$i])[1], BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING))
	  If $param == 'Input Directory' Then
		 $inputDirectory = $value
	  ElseIf $param == 'Output Directory' Then
		 $outputDirectory = $value
	  ElseIf $param == 'Final Location' Then
		 $finalLocation = $value
	  ElseIf $param == 'Examiner Name' Then
		 $examinerName = $value
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
	  ElseIf $CmdLine[$i] == '-f' Then
		 $finalLocation = $CmdLine[$i+1]
	  ElseIf $CmdLine[$i] == '-e' Then
		 $examinerName = $CmdLine[$i+1]
	  EndIf
   Next
EndFunc

Func LoadFileLogs()
   LoadFileLog('processed', $processedFiles)
   LoadFileLog('failed', $failedFiles)
EndFunc

Func LoadFileLog($filename, $array)
   $path = $inputDirectory & '\' & $filename
   If FileExists($path) Then
	  _FileReadToArray($path, $array, $FRTA_NOCOUNT)
   EndIf
EndFunc

Func SaveFileLog($array, $filename)
   $path = $inputDirectory & '\' & $filename
   _FileWriteFromArray($path, $array)
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
	  $filename = GetFileName($ufds[$i])
	  If (Not ArrayContainsString($processedFiles, $filename)) And (Not ArrayContainsString($failedFiles, $filename)) Then
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

   GenerateReport($path)

   ; close UFED Physical Analyzer
   WinActivate($analyzerWindowName)
   WinClose($analyzerWindowName)
   Sleep(1 * 1000)
   If WinExists('Warning') Then
	  Send('{ENTER}')
	  Sleep(1 * 1000)
   EndIf
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
Func GenerateReport($path)
   $previousDirectoriesInOutput = _FileListToArray($outputDirectory, '*', $FLTA_FOLDERS)
   $noPreviousDirectoriesInOutput = False
   If @error Then
	  $noPreviousDirectoriesInOutput = True
   EndIf

   ; File name:
   Send('{TAB 3}')
   Replace(GetFileName($path))
   ; Save to:
   Send('{TAB 2}{ENTER}')
   Sleep(1 * 1000)
   ControlClick('Select Folder', '', 1152)
   Send($outputDirectory)
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
   ; if 'Generated report' window doesn't close, then 'Finish' button didn't work, so extraction failed
   Sleep(5 * 1000)
   If WinExists('Generate Report') Then
	  WinClose('Generate Report')
	  ; log as failed
	  _ArrayAdd($failedFiles, GetFileName($path))
	  SaveFileLog($failedFiles, 'failed')
	  Return
   EndIf
   ; wait for report to run
   WinWait('Generated report')
   WinActivate('Generated report')
   Send('{TAB}')
   Send('{ENTER}')

   ; copy '.ufdr' file to final location
   $currentDirectoriesInOutput = _FileListToArray($outputDirectory, '*', $FLTA_FOLDERS)
   If Not @error Then
	  Local $newDirectory = Null
	  If $noPreviousDirectoriesInOutput Then
		 $newDirectory = $currentDirectoriesInOutput[1]
	  Else
		 $newDirectory = FindNewDirectory($previousDirectoriesInOutput, $currentDirectoriesInOutput)
	  EndIf
	  If Not ($newDirectory = Null) Then
		 $ufdrs = _FileListToArrayRec($outputDirectory & '\' & $newDirectory, '*.ufdr', $FLTAR_FILES, $FLTAR_RECUR)
		 If Not @error Then
			$copySrc = $outputDirectory & '\' & $newDirectory & '\' & $ufdrs[1]
			$copyDst = $finalLocation & '\' & GetFileName($path) & '.ufdr'
			FileCopy($copySrc, $copyDst, $FC_OVERWRITE)
		 EndIf
	  EndIf
   EndIf

   ; log as processed
   _ArrayAdd($processedFiles, GetFileName($path))
   SaveFileLog($processedFiles, 'processed')
EndFunc

Func Replace($str)
   Send('^a')
   Send($str)
EndFunc

Func FindNewDirectory($previousDirs, $currentDirs)
   For $curIndex = 1 To $currentDirs[0]
	  $found = False
	  For $prevIndex = 1 To $previousDirs[0]
		 If $currentDirs[$curIndex] == $previousDirs[$prevIndex] Then
			$found = True
		 EndIf
	  Next
	  If Not $found Then
		 Return $currentDirs[$curIndex]
	  EndIf
   Next
   Return Null
EndFunc

;~ Func TestMain()
;~    LoadConfig()

;~    WinActivate($analyzerWindowName)
;~    Send('^r')
;~    Sleep(1 * 1000)
;~    GenerateReport('Samsung GSM GT-I9250 Galaxy Nexus 2017_06_02 (001)\Physical ADB 01\Samsung GSM_GT-I9250 Galaxy Nexus.ufd')
;~ EndFunc

Main()
