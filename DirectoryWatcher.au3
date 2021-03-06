#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ColorConstants.au3>
#include <Array.au3>
#include <File.au3>
#include <WinAPI.au3>

Local $popups[6] = ['[CLASS:#32770]', 'New version is available', 'Did you know�', 'Recover additional location data: Time-limited free service', 'Device time zone detected', 'Convert BSSID (wireless networks) and cell towers to locations: Time-limited free service']

; these are read from the config file or overwritten by command line arguments
Local $inputDirectory = ''
Local $outputDirectory = ''
Local $finalLocation = ''
Local $examinerName = ''

; title of analyzer window (this is just an example, variable is set when program starts up)
Local $analyzerWindowName = 'UFED Physical Analyzer 6.2.0.79'

Func Main()
   ; increase default key delay (miliseconds)
   AutoItSetOption('SendKeyDelay', 25)

   LoadConfig()

   ReadCommandLineArgs()

   ; check that all directories are valid
   CheckDirIsValid($inputDirectory)
   CheckDirIsValid($outputDirectory)
   CheckDirIsValid($finalLocation)

   ; look for new '.ufd' files in the input directory to process
   ; if none are found, wait and retry
   While True
	  $newFile = NextNewFile()
	  If Not ($newFile = Null) Then
		 ProcessFile($newFile)
	  Else
		 Sleep(10 * 1000)
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

Func NextNewFile()
   ; recursively search for '.ufd' files in the input directory
   $ufds = _FileListToArrayRec($inputDirectory, '*.ufd', $FLTAR_FILES, $FLTAR_RECUR)
   If @error Then
	  ConsoleWrite('IO Error: Error on path ' & $inputDirectory & @CRLF)
	  Return Null
   EndIf

   $processedFiles = LoadFileLog('processed')
   $failedFiles = LoadFileLog('failed')
   $inProgressFiles = LoadFileLog('inprogress')
   ; get the first '.ufd' file that hasn't been processed (or return Null if all have been processed)
   For $i = 1 To $ufds[0]
	  $filename = GetFileName($ufds[$i])
	  If (Not ArrayContainsString($processedFiles, $filename)) And (Not ArrayContainsString($failedFiles, $filename)) And (Not ArrayContainsString($inProgressFiles, $filename)) Then
		 Return $ufds[$i]
	  EndIf
   Next
   Return Null
EndFunc

Func ArrayContainsString($array, $string)
   Return (ArrayIndexOfString($array, $string) <> -1)
EndFunc

Func ArrayIndexOfString($array, $string)
   For $i = 0 To (UBound($array)-1)
	  If $array[$i] == $string Then
		 Return $i
	  EndIf
   Next
   Return -1
EndFunc

Func ProcessFile($path)
   AddToLog('inprogress', GetFileName($path))

   ShellExecute($inputDirectory & '\' & $path)

   WaitForAnalyzerWindow()

   WaitUntilFinished()

   ; if UFED Physical Analyzer closed while waiting for the extraction to finish, mark it as failed and move on (should only happen if program is manually closed)
   If Not WinExists($analyzerWindowName) Then
	  AddToLog('failed', GetFileName($path))
	  RemoveFromLog('inprogress', GetFileName($path))
	  Return
   EndIf

   GenerateReport($path)

   CloseAnalyzer()

   RemoveFromLog('inprogress', GetFileName($path))
EndFunc

Func LoadFileLog($filename)
   $path = $inputDirectory & '\' & $filename
   Local $array[0]
   If FileExists($path) Then
	  _FileReadToArray($path, $array, $FRTA_NOCOUNT)
   EndIf
   Return $array
EndFunc

Func SaveFileLog($array, $filename)
   $path = $inputDirectory & '\' & $filename
   If UBound($array) = 0 Then
	  ; _FileWriteFromArray does nothing if the array is empty, so delete the file (easier than creating a new file handle and overwriting the file with an empty one)
	  FileDelete($path)
   Else
	  _FileWriteFromArray($path, $array)
   EndIf
EndFunc

Func AddToLog($log, $filename)
   $array = LoadFileLog($log)
   _ArrayAdd($array, $filename)
   SaveFileLog($array, $log)
EndFunc

Func RemoveFromLog($log, $filename)
   $array = LoadFileLog($log)
   _ArrayDelete($array, ArrayIndexOfString($array, $filename))
   SaveFileLog($array, $log)
EndFunc

Func WaitForAnalyzerWindow()
   While True
	  $windows = WinList()

	  For $i = 1 To $windows[0][0]
		 ; find the first window with 'UFED Physical Analyzer' in the title and 'UFEDPhysicalAnalyzer.exe' in the handle class name (e.g. "HwndWrapper[UFEDPhysicalAnalyzer.exe;;a343e3b1-a32b-4e01-8da4-5379e002e962]")
		 If StringInStr($windows[$i][0], 'UFED Physical Analyzer') And StringInStr(_WinAPI_GetClassName($windows[$i][1]), 'UFEDPhysicalAnalyzer.exe') Then
			$analyzerWindowName = $windows[$i][0]
			Return
		 EndIf
	  Next

	  Sleep(1 * 1000)
   WEnd
EndFunc

Func CloseAllPopups()
   While PopupsExist()
	  ClosePopups()
	  Sleep(1 * 1000)
   Wend
EndFunc

Func PopupsExist()
   For $i = 0 to (UBound($popups)-1)
	  if WinExists($popups[$i]) Then
		 return True
	  EndIf
   Next
   return False
EndFunc

Func ClosePopups()
   For $i = 0 to (UBound($popups)-1)
	  if WinExists($popups[$i]) Then
		 WinClose($popups[$i])
	  EndIf
   Next
EndFunc

Func WaitUntilFinished()
   While Not (WinExists('Generate Report'))
	  Sleep(9 * 1000)
	  CloseAllPopups()
	  ; check if the program has been closed, and if so, stop waiting (should only happen if program is manually closed)
	  If Not WinExists($analyzerWindowName) Then
		 Return
	  EndIf
	  ; try to generate a report (only succeeds when '.ufd' is finished processing)
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
   CloseAllPopups()
   WinActivate('Generate Report')
   ; File name:
   Send('{TAB 3}')
   Replace(GetFileName($path))
   ; Save to:
   Send('{TAB 2}{ENTER}')
   Sleep(1 * 1000)
   ControlClick('Select Folder', '', 1152)
   Replace($outputDirectory)
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
   Sleep(1 * 1000)
   ; click Next
   MouseClick('left', $winX + $winWidth - 300, $winY + $winHeight - 30, 1, 0)
   Sleep(1 * 1000)
   ; click Finish
   MouseClick('left', $winX + $winWidth - 180, $winY + $winHeight - 30, 1, 0)
   ; if 'Generated report' window doesn't close, then 'Finish' button didn't work, so extraction failed
   Sleep(5 * 1000)
   If WinExists('Generate Report') Then
	  WinClose('Generate Report')
	  ; log as failed
	  AddToLog('failed', GetFileName($path))
	  Return
   EndIf
   ; wait for report to run
   WinWait('Generated report')
   WinActivate('Generated report')
   Send('{TAB}')
   Send('{ENTER}')

   ; copy '.ufdr' file to final location
   $ufdrPath = NewestUfdrFile($outputDirectory)
   $copySrc = $outputDirectory & '\' & $ufdrPath
   $copyDst = $finalLocation & '\' & GetFileName($path) & '.ufdr'
   FileCopy($copySrc, $copyDst, $FC_OVERWRITE)

   ; log as processed
   AddToLog('processed', GetFileName($path))
EndFunc

Func NewestUfdrFile($directory)
   $ufdrs = _FileListToArrayRec($directory, '*.ufdr', $FLTAR_FILES, $FLTAR_RECUR)
   $newestUfdrPath = $ufdrs[1]
   $newestUfdrTimestamp = FileGetTime($directory & '\' & $newestUfdrPath, $FT_CREATED, $FT_STRING)
   For $i = 2 To $ufdrs[0]
	  $path = $ufdrs[$i]
	  $timestamp = FileGetTime($directory & '\' & $path, $FT_CREATED, $FT_STRING)
	  If StringCompare($timestamp, $newestUfdrTimestamp) > 0 Then
		 $newestUfdrPath = $path
		 $newestUfdrTimestamp = $timestamp
	  EndIf
   Next
   return $newestUfdrPath
EndFunc

Func Replace($str)
   Send('^a')
   Send($str)
EndFunc

Func CloseAnalyzer()
   WinActivate($analyzerWindowName)
   WinClose($analyzerWindowName)
   Sleep(1 * 1000)
   If WinExists('Warning') Then
	  Send('{ENTER}')
	  Sleep(1 * 1000)
   EndIf
   ; make sure UFED Physical Analyzer exited cleanly
   Do
	  Sleep(5 * 1000)
   Until Not WinExists($analyzerWindowName)
EndFunc

Main()
