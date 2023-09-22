# eac3-to-ac3-converter

## Overview

The `eac3-to-ac3-converter` script is a Bash tool designed to automate the conversion of eac3 audio streams in MKV files to the AC-3 format. It scans specified directories and their subdirectories for MKV files containing eac3 audio streams and converts them to AC-3, preserving the language tags. This tool is particularly useful for managing and optimizing audio streams in video libraries.

## Features

- Batch conversion of eac3 audio streams in MKV files to AC-3.
- Preservation of language tags in the output file names.
- Automatic detection of previously converted files to avoid duplication.
- Detailed logging of converted and skipped files.

## Dependencies

Before using the `eac3-to-ac3-converter` script, ensure that you have the following dependencies installed on your system:

1. **Bash Shell**: The script is written in Bash and requires a Bash-compatible shell to run.

2. **FFmpeg**: FFmpeg is a multimedia framework that provides the tools to convert and manipulate multimedia files. You can download FFmpeg from the official website: [FFmpeg](https://www.ffmpeg.org/download.html).

3. **ffprobe**: ffprobe is a component of FFmpeg that is used to extract detailed information about multimedia files, including audio streams. It is often included with FFmpeg, so you should have it available if you have FFmpeg installed.

## Usage

1. Clone this repository to your local machine:

   ```bash
   git clone https://github.com/umetnic/EAC3_to_AC3.git
