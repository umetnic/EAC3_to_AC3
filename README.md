# EAC3 to AC3 Converter

## Overview

The **EAC3 to AC3 Converter** script is a Bash tool designed to automate the conversion of eac3 audio streams in MKV files to the AC-3 format. It scans specified directories and their subdirectories for MKV files containing eac3 audio streams and converts them to AC-3, preserving the language tags. This tool is particularly useful for managing and optimizing audio streams in video libraries.

## Features

- Batch conversion of eac3 audio streams in MKV files to AC-3.
- Preservation of language tags in the output file names.
- Automatic detection of previously converted files to avoid duplication.
- Detailed logging of converted and skipped files.

**2Do**
1. automatically run the script when new files are detected.
  Some ideas:
   - rtorrent invokes the script when download is finished
   - when system finishes copying/moving files to the watched folders, script is notified and extracts the audio...look into inotifywait.
2. decide how to process/(notify user?) problematic files like zero size, etc... Done
3. properly handle partial ac3 files from unfinished conversions. Now these are just skipped. For now I added a setting to skip original log file.
4. stuff in 2do section of ini fali...  

## Dependencies

Before using the **EAC3 to AC3 Converter** script, ensure that you have the following dependencies installed on your system:

1. **Bash Shell**: The script is written in Bash and requires a Bash-compatible shell to run.

2. **FFmpeg**: FFmpeg is a multimedia framework that provides the tools to convert and manipulate multimedia files. You can download FFmpeg from the official website: [FFmpeg Download](https://www.ffmpeg.org/download.html).

3. **ffprobe**: ffprobe is a component of FFmpeg that is used to extract detailed information about multimedia files, including audio streams. It is often included with FFmpeg, so you should have it available if you have FFmpeg installed.

## Usage

1. Clone this repository to your local machine:

   ```bash
   git clone https://github.com/umetnic/EAC3_to_AC3.git


2. Navigate to the script's directory:
   ```bash
   cd eac3-to-ac3-converter

3. Make the script executable:
   ```bash
   chmod +x eac3_to_ac3.sh

4. Edit the **eac3_to_ac3.ini** file to specify the input folders. Add the absolute paths of the directories you want to scan, one per line. You can exclude comments by prefixing lines with #.

5. Run the script:
   ```bash
   ./eac3_to_ac3.sh

The script will process the specified folders and their subfolders, converting eac3 audio streams in MKV files to AC-3 format. Converted files will be saved in the same directories with language tags appended to their names.

## Configuration

Edit the **eac3_to_ac3.ini** file to specify the input folders. Add the absolute paths of the directories you want to scan, one per line. You can exclude comments by prefixing lines with #.

## Logging

The script creates two log files in each input folder:

**converted_files.log** - Lists the paths of successfully converted files.

**skipped_files.log** - Lists the paths of files that were skipped because they already had AC-3 audio streams.

## License

This script is licensed under the MIT License.
## Acknowledgments

The script uses FFmpeg, an open-source multimedia framework.
## Issues and Contributions

If you encounter any issues or have suggestions for improvements, please create an issue on the GitHub repository. Contributions and pull requests are welcome!
