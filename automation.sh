#!/bin/bash

# Step 1: Update package details and package list
sudo apt update -y

# Step 2: Install apache2 if not already installed
if ! dpkg -l | grep -q apache2; then
    sudo apt install apache2 -y
fi

# Step 3: Ensure apache2 service is running
if ! systemctl is-active --quiet apache2; then
    sudo systemctl start apache2
fi

# Step 4: Ensure apache2 service is enabled
if ! systemctl is-enabled --quiet apache2; then
    sudo systemctl enable apache2
fi

# Step 5: Create a tar archive of apache2 logs
timestamp=$(date '+%d%m%Y-%H%M%S')
log_files="/var/log/apache2/*.log"
tar_file="Hashmeet-httpd-logs-$timestamp.tar"
tmp_dir="/tmp"

# Create the tar archive
tar -cvf "$tmp_dir/$tar_file" $log_files

# Step 6: Copy the archive to an S3 bucket using AWS CLI
aws s3 cp "$tmp_dir/$tar_file" s3://upgrad-hashmeet/

# Optional: Clean up the temporary tar file
rm "$tmp_dir/$tar_file"

echo "Script completed successfully."
