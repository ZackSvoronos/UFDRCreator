# Cellebrite UFDR Creator Script

Example Usage:
`"C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" .\DirectoryWatcher.au3 -i "C:\Users\...\input" -o "C:\Users\...\output" -e "Examiner Name"`

Config:
* Input Directory: path to continuously watch for new '.ufd' files
* Ouput Directory: path to save processed '.ufdr' files
* Examiner Name: required by UFED Physical Analyzer

UFED Physical Analyzer must be installed and '.ufd' files must be associated with this program. '.ufd' files must have unique names, '.ufd' files with duplicate names are ignored.

Command line arguments override the values in `config`.