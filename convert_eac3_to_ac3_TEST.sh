#!/bin/bash

# This script converts EAC3 audio streams in MKV files to AC-3 format.

# Change working directory to the script directory
cd "$(dirname "$0")"

# Define the section name you want to read from the settings file
section_name="[Settings]"

# Flag to indicate when we are inside the [Settings] section
inside_section=0

# Read the settings file and populate variables
while IFS= read -r line; do
    # Check if the line contains the section name
    if [[ "$line" == "$section_name" ]]; then
        echo -e "\n[Settings]"
        inside_section=1
        continue
    fi

    # If we are inside the [Settings] section
    if [[ $inside_section -eq 1 ]]; then
        # Exit the loop when we encounter another section
        if [[ "$line" =~ ^\[[^\]]+\] ]]; then
            inside_section=0
            continue
        fi

        # Remove leading and trailing whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        # Check if the line is not empty and does not start with a comment
        if [[ -n "$line" && "$line" != \#* ]]; then
            # Split the line into a variable name and value using the equal sign (=)
            var_name="${line%%=*}"
            var_value="${line#*=}"

            # Remove leading and trailing whitespace from the variable value
            var_value="${var_value#"${var_value%%[![:space:]]*}"}"
            var_value="${var_value%"${var_value##*[![:space:]]}"}"

            # Define the variable with the specified name and value
            declare "$var_name=$var_value"
            echo "$var_name=$var_value"
        fi
    fi
done < "eac3_to_ac3.ini"

# Overwrite existing variable sets overwrite_option for ffmpeg
if [ "$overwrite_existing" = "yes" ]; then
    overwrite_option="-overwrite"
elif [ "$overwrite_existing" = "no" ]; then
    overwrite_option="-nooverwrite"
elif [ "$overwrite_existing" = "ask" ]; then
    overwrite_option="ask"
fi

# Define the section name you want to read from the settings file
section_name="[MediaPaths]"

# Initialize the input_folders array
input_folders=()

# Read the [MediaPaths] section, ignore comment lines, and populate the input_folders array
while IFS= read -r line; do
    # Check if the line contains the section name
    if [[ "$line" == "$section_name" ]]; then
        # Start reading lines within the section
        while IFS= read -r inner_line && [[ ! "$inner_line" =~ ^\[.* ]]; do
            # Remove leading and trailing whitespace
            inner_line="${inner_line#"${inner_line%%[![:space:]]*}"}"
            inner_line="${inner_line%"${inner_line##*[![:space:]]}"}"

            # Add non-empty lines to the input_folders array
            if [ -n "$inner_line" ]; then
                input_folders+=("$inner_line")
            fi
        done
    fi
done < <(grep -v '^#' "eac3_to_ac3.ini")

# Loop through each input folder path and process it
for input_folder in "${input_folders[@]}"; do
    # Verify that the input_folder variable contains the correct value
    echo -e "\nInput Folder: \e[1;33m$input_folder\e[0m"

    # Specify the output folder as the same as the input folder
    output_folder="$input_folder"
    log_file="$output_folder/converted_files.log"
    skipped_log_file="$output_folder/skipped_files.log"

    # Function to convert an MKV file
    convert_mkv_file() {
        input_file="$1"
        output_dir="$2"

        # Get the filename and extension
        filename=$(basename "$input_file")
        extension="${filename##*.}"

        # Check if the file size is zero
        if [ -s "$input_file" ]; then
            # Check if the file has been converted before
            if [[ ! " ${converted_files[*]} " =~ " $input_file " ]]; then
                # Use ffprobe to analyze the input file and get detailed audio stream information
                audio_info=$(ffprobe -v error -select_streams a -show_entries stream=index,codec_name,channels,bit_rate:stream_tags=language -of csv=p=0 "$input_file")

                # Read audio stream information into an array
                IFS=$'\n' read -d '' -r -a audio_info_array <<< "$audio_info"

                for stream_info in "${audio_info_array[@]}"; do
                    # Split the stream information into variables
                    IFS=',' read -r -a stream_info_array <<< "$stream_info"
                    stream_index="${stream_info_array[0]}"
                    codec_name="${stream_info_array[1]}"
                    num_channels="${stream_info_array[2]}"
                    bit_rate_bps="${stream_info_array[3]}"  # Bitrate in bps
                    language_tag="${stream_info_array[4]}"

                    # Check if bit_rate_bps is a valid numeric value
                    if [[ "$bit_rate_bps" =~ ^[0-9]+$ ]]; then
                        # Convert the bitrate from bps to kb/s
                        bit_rate_kbps=$((bit_rate_bps / 1000))
                    else
                        # Handle the case where bit_rate_bps is not a valid numeric value
                        bit_rate_kbps="N/A"
                    fi

                    # Check if the audio stream codec is 'eac3'
                    if [[ "$codec_name" =~ eac3 ]]; then
                        # Determine the desired number of output audio channels
                        if [ "$num_channels" -gt 6 ]; then
                            # If input has more than 5.1 channels, convert to 5.1 (6 channels)
                            output_channels=6
                        else
                            # Keep the same number of channels
                            output_channels="$num_channels"
                        fi

                        # Generate the output file path with AC-3 extension and the language code
                        output_file="$output_dir/${filename%.*}.${language_tag}.ac3"

                        # Check if the output AC-3 file exists (regular file)
                        if [ -f "$output_file" ]; then
                            #echo "File exists, proceeding based on overwrite setting"

                            if [ "$overwrite_existing" = "yes" ]; then
                                echo "File exists, and overwrite = yes"
                                # Extract the audio stream using FFmpeg and overwrite existing
                                echo -e "\nProcessing file: \e[32m$input_file\e[0m"
                                echo -e "\e[33mStream Index: $stream_index\e[0m"
                                echo -e "\e[33mCodec Name: $codec_name\e[0m"
                                echo -e "\e[33mNumber of Channels: $num_channels\e[0m"
                                echo -e "\e[33mBitrate: $bit_rate_kbps kb/s\e[0m"
                                echo -e "\e[33mLanguage Tag: $language_tag\e[0m"
                                echo ""

                                ffmpeg "$overwrite_option" -loglevel "$ffmpeg_loglevel" -i "$input_file" -map "0:${stream_index}" -c:a ac3 -b:a "${bit_rate_kbps}k" -ac "$output_channels" -ar 48000 "$output_file" 2>&1 | grep -E 'Stream.* (Audio)|Output file #0 ->'

                                # Write the complete path of the successfully converted file to the log file
                                echo "$input_file" >> "$log_file"

                                # Add the converted file name to the list
                                converted_files+=("$input_file")

                                # Add the filename to the list of files converted in this run
                                files_converted_this_run+=("$input_file")

                                # Increment the newly converted files count
                                newly_converted_files=$((newly_converted_files + 1))
                            elif [ "$overwrite_existing" = "ask" ]; then
                                echo "File exists, and overwrite = ask"
                                # Extract the audio stream using FFmpeg and ask if the existing file should be overwritten
                                echo -e "\nProcessing file: \e[32m$input_file\e[0m"
                                echo -e "\e[33mStream Index: $stream_index\e[0m"
                                echo -e "\e[33mCodec Name: $codec_name\e[0m"
                                echo -e "\e[33mNumber of Channels: $num_channels\e[0m"
                                echo -e "\e[33mBitrate: $bit_rate_kbps kb/s\e[0m"
                                echo -e "\e[33mLanguage Tag: $language_tag\e[0m"
                                echo ""
                                read -p "File '$output_file' already exists. Overwrite? (y/N) " overwrite_response
                                if [[ $overwrite_response =~ ^[Yy]$ ]]; then
                                    # User chose to overwrite
                                    ffmpeg -y -loglevel "$ffmpeg_loglevel" -i "$input_file" -map "0:${stream_index}" -c:a ac3 -b:a "${bit_rate_kbps}k" -ac "$output_channels" -ar 48000 "$output_file"

                                    # Write the complete path of the successfully converted file to the log file
                                    echo "$input_file" >> "$log_file"

                                    # Add the converted file name to the list
                                    converted_files+=("$input_file")

                                    # Add the filename to the list of files converted in this run
                                    files_converted_this_run+=("$input_file")

                                    # Increment the newly converted files count
                                    newly_converted_files=$((newly_converted_files + 1))
                                else
                                    # User chose not to overwrite
                                    echo "Ffmpeg operation canceled. File was not overwritten."
                                fi
                            else
                                # Print a message indicating that the file already exists and won't be overwritten
                                echo -e "\nSkipping existing file: \e[96m\e[1m$output_file\e[0m"
                                echo -e "Output file already exists, but overwrite_option is set to \e[38;5;206m$overwrite_option\e[0m"
								

                                # Log the skipped file in the skipped_files.log with the complete path
                                echo "$input_file" >> "$skipped_log_file"
                            fi
                        else
                            #echo "File does not exist, creating it now"
                            # Extract the audio stream using FFmpeg and create a new AC-3 file
                            echo -e "\nProcessing file: \e[32m$input_file\e[0m"
                            echo -e "\e[33mStream Index: $stream_index\e[0m"
                            echo -e "\e[33mCodec Name: $codec_name\e[0m"
                            echo -e "\e[33mNumber of Channels: $num_channels\e[0m"
                            echo -e "\e[33mBitrate: $bit_rate_kbps kb/s\e[0m"
                            echo -e "\e[33mLanguage Tag: $language_tag\e[0m"
                            echo ""

                            ffmpeg -loglevel "$ffmpeg_loglevel" -i "$input_file" -map "0:${stream_index}" -c:a ac3 -b:a "${bit_rate_kbps}k" -ac "$output_channels" -ar 48000 "$output_file" 2>&1 | grep -E 'Stream.* (Audio)|Output file #0 ->'

                            # Write the complete path of the successfully converted file to the log file
                            echo "$input_file" >> "$log_file"

                            # Add the converted file name to the list
                            converted_files+=("$input_file")

                            # Add the filename to the list of files converted in this run
                            files_converted_this_run+=("$input_file")

                            # Increment the newly converted files count
                            newly_converted_files=$((newly_converted_files + 1))
                        fi
                    fi
                done
            fi
        else
            # Log the zero-sized file to errors.log
            echo "Zero-sized file: $input_file" >> "$output_dir/errors.log"
            echo -e "\nZero-sized file: \e[91;1m$input_file\e[0m"
        fi
    }

    # Function to process files in a directory (including subdirectories)
    process_files_in_directory() {
        local input_dir="$1"
        local output_dir="$2"

        # Create the output directory if it doesn't exist
        mkdir -p "$output_dir"

        # Loop through all files and directories in the specified directory
        for entry in "$input_dir"/*; do
            if [[ -d "$entry" ]]; then
                # If it's a directory, recursively process its contents
                local subdirectory_name=$(basename "$entry")
                process_files_in_directory "$entry" "$output_dir/$subdirectory_name"
            elif [[ -f "$entry" ]]; then
                # If it's a file, check if it's an MKV file and convert if eligible
                if [[ "$entry" =~ \.mkv$ ]]; then
                    convert_mkv_file "$entry" "$output_dir"
                fi
            fi
        done
    }

	# Determine the log file based on the skip_converted_files_log setting
	if [ "$skip_converted_files_log" = "yes" ]; then
		log_file="$output_folder/second_log.log"
	else
		log_file="$output_folder/converted_files.log"
	fi

	# Create the log file if it doesn't exist
	touch "$log_file"

	# Read the list of previously converted files if it exists
	if [[ -f "$log_file" ]]; then
		mapfile -t converted_files < "$log_file"
	else
		declare -a converted_files
	fi

    # Variable to track if any files were converted
    newly_converted_files=0

    # Array to store the filenames converted in this run
    files_converted_this_run=()

    # Process files in the input folder and its subfolders
    process_files_in_directory "$input_folder" "$output_folder"

    # Notify of new files conversions
    if [[ $newly_converted_files -eq 0 ]]; then
        # Print in green color
        echo -e "\n\e[32mNo new files to convert.\e[0m"
        # You can also add additional notification methods here, like sending an email or using a system notification.
    else
        # Print in green color
        echo -e "\n\e[32mConverted files on this run:\e[0m"
        for converted_filename in "${files_converted_this_run[@]}"; do
            # Print in yellow color
            echo -e "\e[33m$converted_filename\e[0m"
        done
    fi
done
