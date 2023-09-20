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

    # Check if the filename contains 'DDP', '7.1', 'DD+', or 'eac3'
    if [[ "$input_file" =~ (DDP|7.1|\bDD\+\b|eac3) ]] && ! [[ "$input_file" =~ DTS-HD ]]; then

        # These conditions check if the filename contains specific keywords related to audio characteristics using regular expressions.

        # Get the filename and extension
        filename=$(basename "$input_file")
        extension="${filename##*.}"

        # Check if the file has been converted before
        # This checks if the file has been converted before based on the contents of 'converted_files' array.
        if [[ ! " ${converted_files[*]} " =~ " $filename " ]]; then

            # Use ffprobe to analyze the input file and get information about its audio streams
            audio_info=$(ffprobe -v error -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$input_file")

            # Check if the audio stream codec is 'eac3'
            if [[ "$audio_info" =~ eac3 ]]; then
                # Extract the language code from the audio stream
                language_code=$(ffprobe -v error -select_streams a:0 -show_entries stream_tags=language -of default=noprint_wrappers=1:nokey=1 "$input_file")

                # Generate the output file path with AC-3 extension and the language code
                output_file="$output_dir/${filename%.*}.${language_code}.ac3"

                # Check if the output file already exists before running ffmpeg
                if [ ! -f "$output_file" ]; then
                    # Extract the audio file using FFmpeg without overwriting
                    echo -e "\n"                    
					echo -e "\e[32mProcessing:\e[0m"
					ffmpeg -loglevel info -n -i "$input_file" -vn -c:a ac3 -ac 6 -ar 48000 "$output_file" 2>&1 | grep -E 'Input #0|Stream.* (Audio)|Output file #0 ->'
                    
					
                    # Add the converted file name to the list
                    converted_files+=("$filename")

                    # Add the filename to the list of files converted in this run
                    files_converted_this_run+=("$filename")

                    # Write the name of successfully converted file to the log file
                    echo "$filename" >> "$log_file"

                    # Print information about the audio stream to the terminal in yellow
                    #echo -e "\e[33mAudio stream info for $filename:\e[0m"
                    #echo -e "\e[33m$audio_info\e[0m"
                    #echo ""

                    # Increment the newly converted files count
                    newly_converted_files=$((newly_converted_files + 1))
                else
                    
                    # Print a message indicating that the file already exists and won't be overwritten
                    echo -e "Skipping existing file:\e[96m\e[1m$output_file\e[0m"
                    
                    # Log the skipped file in the skipped_files.log
                    echo "Skipped file (already exists): $filename" >> "$skipped_log_file"					
					
                fi
            fi
        fi
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

# Loop start
while :
do
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

    # Notify if no new files were converted
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

    # Wait for total time and loop
    total=50  # total wait time in seconds
    count=0  # counter

    echo -e "\n"

    while [ ${count} -lt ${total} ] ; do
        tlimit=$(( $total - $count ))
        # comment the next line if you don't want the counter and to be able to scroll the log up and down.
        echo -e "\rEnter \e[92m\e[1many key char \e[0mto break pause and continue DL, or \e[92mwait \e[93m\e[1m${tlimit} \e[0mseconds..\e[0m \c"
        read -t 1 name
        test ! -z "$name" && { break ; }
        count=$((count+1))
    done

    echo -e "\n"
    echo -e "\e[96m\e[1m"
    echo "####################################################################################"
    echo -e "\e[0m"
    echo -e "\n"

done
