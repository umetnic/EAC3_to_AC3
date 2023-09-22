
#!/bin/bash

# This line specifies that the script should be executed using the Bash shell.

# Change working directory to the script directory
cd "$(dirname "$0")"
# This line changes the working directory of the script to the directory where the script itself is located.

# Read the input folder from eac3_to_ac3.ini
input_folder=$(cat eac3_to_ac3.ini)
# This line reads the input folder path from the input_folder.log file.

# Specify the output folder as the same as the input folder
output_folder="$input_folder"
log_file="$output_folder/converted_files.log"
skipped_log_file="$output_folder/skipped_files.log"
# These lines set variables for the output directories and the log files location.

 echo -e "\n" # Just a new line to make things clearer to see

# Function to convert an MKV file
convert_mkv_file() {
    input_file="$1"
    output_dir="$2"

    # Get the filename and extension
    filename=$(basename "$input_file")
    extension="${filename##*.}"

    # Check if the file has been converted before
    if [[ ! " ${converted_files[*]} " =~ " $filename " ]]; then

        # Use ffprobe to analyze the input file and get detailed audio stream information
        audio_info=$(ffprobe -v error -select_streams a -show_entries stream=index,codec_name,channels:stream_tags=language -of csv=p=0 "$input_file")

        # Read audio stream information into an array
        IFS=$'\n' read -d '' -r -a audio_info_array <<< "$audio_info"

        for stream_info in "${audio_info_array[@]}"; do
            # Split the stream information into variables
            IFS=',' read -r -a stream_info_array <<< "$stream_info"
            stream_index="${stream_info_array[0]}"
            codec_name="${stream_info_array[1]}"
            num_channels="${stream_info_array[2]}"
            language_tag="${stream_info_array[3]}"

            # Check if the audio stream codec is 'eac3'
            if [[ "$codec_name" =~ eac3 ]]; then
                # Generate the output file path with AC-3 extension and the language code
                output_file="$output_dir/${filename%.*}.${language_tag}.ac3"

                # Check if the output file already exists before running ffmpeg
                if [ ! -f "$output_file" ]; then
                    # Extract the audio stream using FFmpeg without overwriting
						# Print the current file being processed
						echo -e "\n" 
						echo -e "Processing file: \e[32m$filename\e[0m"
                    ffmpeg -loglevel info -n -i "$input_file" -map "0:${stream_index}" -c:a ac3 -ac "$num_channels" -ar 48000 "$output_file" 2>&1 | grep -E 'Input #0|Stream.* (Audio)|Output file #0 ->'

                    # Add the converted file name to the list
                    converted_files+=("$filename")

                    # Add the filename to the list of files converted in this run
                    files_converted_this_run+=("$filename")

                    # Write the name of the successfully converted file to the log file
                    echo "$filename" >> "$log_file"

                    # Print information about the audio stream to the terminal in yellow
                    echo -e "\e[33mAudio stream info for $filename:\e[0m"
                    echo -e "\e[33mStream Index: $stream_index\e[0m"
                    echo -e "\e[33mCodec Name: $codec_name\e[0m"
                    echo -e "\e[33mNumber of Channels: $num_channels\e[0m"
                    echo -e "\e[33mLanguage Tag: $language_tag\e[0m"
                    echo ""

                    # Increment the newly converted files count
                    newly_converted_files=$((newly_converted_files + 1))
                else
                    # Print a message indicating that the file already exists and won't be overwritten
                    echo -e "Skipping existing file:\e[96m\e[1m$output_file\e[0m"

                    # Log the skipped file in the skipped_files.log
                    echo "Skipped file (already exists): $filename" >> "$skipped_log_file"
                fi
            fi
        done
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

    # Create the log file if it doesn't exist
    touch "$log_file"
    # This line ensures that the log file exists; if it doesn't, it creates an empty one.

    # Read the list of previously converted files if it exists
    if [[ -f "$log_file" ]]; then
        mapfile -t converted_files < "$log_file"
    else
        declare -a converted_files
    fi
    # These lines read the list of previously converted files from the log file into an array called 'converted_files'.
    # If the log file doesn't exist, it initializes an empty array.

    # Variable to track if any files were converted
    newly_converted_files=0

    # Array to store the filenames converted in this run
    files_converted_this_run=()

    # Process files in the input folder and its subfolders
    process_files_in_directory "$input_folder" "$output_folder"

    # Notify of new files conversions
    if [[ $newly_converted_files -eq 0 ]]; then
        # Print in green color
		echo -e "\n"
        echo -e "\e[32mNo new files to convert.\e[0m"
        # You can also add additional notification methods here, like sending an email or using a system notification.
    else
        # Print in green color
		echo -e "\n"
        echo -e "\e[32mConverted files on this run:\e[0m"
        for converted_filename in "${files_converted_this_run[@]}"; do
            # Print in yellow color
            echo -e "\e[33m$converted_filename\e[0m"
        done
    fi 
