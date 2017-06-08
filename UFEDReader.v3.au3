#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ColorConstants.au3>
#include <file.au3>

Local $popups[5] = ['New version is available', 'Did you know…', 'Recover additional location data: Time-limited free service', 'Device time zone detected', 'Convert BSSID (wireless networks) and cell towers to locations: Time-limited free service']

Local $hardcodedSaveDirectory = 'C:\Users\Zack\Documents\My Reports'

UFEDReader()
;WindowNav()

Func UFEDReader()

   $FilePath = 'C:\Users\Zack\Documents\My UFED Extractions'
   Local $ufdsInDirectory = _FileListToArrayRec($FilePath, '*.ufd', $FLTAR_FILES, $FLTAR_RECUR)
   ;_ArrayDisplay($ufdsInDirectory, "File Display")

;~    For $i = 1 To $ufdsInDirectory[0]
;~ 	  ShellExecute($FilePath & '\' & $ufdsInDirectory[$i])
;~ 	  ; Sleep to let program startup
;~ 	  If $i = 1 Then
;~ 		 Sleep(20 * 1000)
;~ 	  EndIf
;~    Next

;~    WaitUntilFinished()

   Sleep(5 * 1000)
   GenerateReport('C:\THIS_IS_A_MD5_HASH.ufd', $hardcodedSaveDirectory)

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
   While Not(WinExists('Device time zone detected'))
	  Sleep(1 * 1000)
	  CloseAllPopups()
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

;Func UFEDReader()
   ;$FilePath = 'C:\Users\Zack\Documents\My UFED Extractions'
   ;Local $ufdsInDirectory = _FileListToArrayRec($FilePath, '*.ufd', $FLTAR_FILES, $FLTAR_RECUR)
   ;Run('C:\Program Files\Cellebrite Mobile Synchronization\UFED Physical Analyzer\UFEDPhysicalAnalyzer.exe')

   ;While ProcessExists('UFEDPhysicalAnalyzer.exe')
	  ;For $i = 1 To $ufdsInDirectory[0]
		 ;ShellExecute($FilePath & '\' & $ufdsInDirectory[$i])
	  ;Next
   ;CloseWindows()
   ;WEnd
;EndFunc

;~ generate a report for the given ufd
Func GenerateReport($path, $saveDirectory)
;~ WinActivate('UFED Physical Analyzer 6.2.0.79')
   Send('^r')
   ; File name:
   Send('{TAB 3}')
   Replace(GetFileName($path))
   ; Save to:
   Send('{TAB}')
   Replace($saveDirectory)
   ; Format
   $windowPosition = WinGetPos('Generate Report')
   MouseClick("left", $windowPosition[0] + 600, $windowPosition[1] + 230, 1, 0)
   Send('{HOME}{SPACE}')
   Send('{END}{DOWN}{ENTER}')
EndFunc

Func Replace($str)
   Send('^a')
   Send($str)
EndFunc
