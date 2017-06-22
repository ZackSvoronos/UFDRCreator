# Cellebrite UFDR Creator Script

## Example Usage:
`"C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" .\DirectoryWatcher.au3 -i "C:\Users\...\input" -o "C:\Users\...\output" -f "C:\Users\...\final" -e "Examiner Name"`

## Config:
* Input Directory: path to continuously watch for new '.ufd' files
* Ouput Directory: path to save extractions (in UFED Physical Analyzer default report structure, i.e. a timestamped directory containing the '.ufdr' and 'UFEDReader.exe')
* Final Directory: path to save a copy of each '.ufdr' file
* Examiner Name: required by UFED Physical Analyzer

Command line arguments are optional and override the values in `config`.

Successful extractions are recorded in the `processed` file, created in the input directory.
Failed extractions are recorded in the `failed` file.
Extractions currently running are recorded in the `inprogress` file.

## Dependencies:
UFED Physical Analyzer must be installed and '.ufd' files must be associated with it.
'.ufd' files must have unique names, '.ufd' files with duplicate names are ignored.
