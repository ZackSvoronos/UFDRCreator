#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ColorConstants.au3>
#include <file.au3>

Local $popups[5] = ['New version is available', 'Did you know…', 'Recover additional location data: Time-limited free service', 'Device time zone detected', 'Convert BSSID (wireless networks) and cell towers to locations: Time-limited free service']

UFEDReader()
;WindowNav()

Func UFEDReader()

   $FilePath = 'C:\Users\Zack\Documents\My UFED Extractions'
   Local $ufdsInDirectory = _FileListToArrayRec($FilePath, '*.ufd', $FLTAR_FILES, $FLTAR_RECUR)
   ;_ArrayDisplay($ufdsInDirectory, "File Display")

   For $i = 1 To $ufdsInDirectory[0]
	  ShellExecute($FilePath & '\' & $ufdsInDirectory[$i])
	  ; Sleep 1 min for the first file to start up
	  If $i = 1 Then
		 Sleep(20 * 1000)
	  EndIf
   Next

   WaitUntilFinished()



EndFunc

Func CloseAllPopups()
   ConsoleWrite('In ClosePopups' & @CRLF)
   While PopupsExist()
	  ConsoleWrite('Popups Found' & @CRLF)
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

Func WindowNav()
   While ProcessExists('UFEDPhysicalAnalyzer.exe')
	  CloseWindows()
   WEnd
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

Func CloseWindows()
   If WinExists('Open') Then
	  WinActivate('Open')
	  Send('{TAB 4}')
	  Send('{ENTER}')
   EndIf

   ;If WinExists('UFED Physical Analyzer 6.2.0.79') Then
	  ;WinActivate('UFED Physical Analyzer 6.2.0.79')
   ;EndIf

   If WinExists('New version is available') Then
	  WinClose('New version is available')
   EndIf

   If WinExists('Did you know…') Then
	  WinClose('Did you know…')
   EndIf

   If WinExists('Recover additional location data: Time-limited free service') Then
	  WinClose('Recover additional location data: Time-limited free service')
   EndIf

   If WinExists('Device time zone detected') Then
	  WinClose('Device time zone detected')
   EndIf

   If WinExists('Convert BSSID (wireless networks) and cell towers to locations: Time-limited free service') Then
	  WinClose('Convert BSSID (wireless networks) and cell towers to locations: Time-limited free service')
   EndIf

EndFunc

   ;5 tabs to 'Generate Report' on 'UFED Physical Analyzer 6.2.0.79'
   ;WinActivate('UFED Physical Analyzer 6.2.0.79')
   ;Send('{TAB 5}')
   ;Send('{ENTER}')
