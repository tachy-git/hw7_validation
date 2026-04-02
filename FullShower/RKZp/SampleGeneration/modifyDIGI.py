def substitute_file_names_in_place(config_file, replacement_file):
    """
    Modify the config file in place by replacing the line that starts with
    'process.mixData.input.fileNames' with content from the replacement file.

    Parameters:
    - config_file: Path to the configuration file to modify.
    - replacement_file: Path to the file containing replacement content.
    """
    # Read the replacement content from the replacement file
    with open(replacement_file, 'r') as infile:
        replacement_content = infile.read().strip()

    # Read the configuration file
    with open(config_file, 'r') as infile:
        lines = infile.readlines()

    # Modify the lines
    for i, line in enumerate(lines):
        if line.strip().startswith("process.mixData.input.fileNames"):
            # Replace the line with the content from the replacement file
            lines[i] = f"process.mixData.input.fileNames = {replacement_content}\n"
            break  # Since there's only one matching line, we can stop here

    # Overwrite the configuration file with modified content
    with open(config_file, 'w') as outfile:
        outfile.writelines(lines)

    print(f"File {config_file} updated successfully.")

# Example usage
if __name__ == "__main__":
    config_file = "files_cfg/RunIISummer20UL18DIGIPremix_cfg.py"  # Replace with your config file path
    replacement_file = "PUfilelist_accessible_18.txt"  # Replace with your config file path

    substitute_file_names_in_place(config_file, replacement_file)
