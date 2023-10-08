#!/bin/bash

# Variables
s3_bucket="upgrad-hashmeet"
your_name="Hashmeet"

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
tar_file="$your_name-httpd-logs-$timestamp.tar"
tmp_dir="/tmp"

# Create the tar archive
tar -cvf "$tmp_dir/$tar_file" $log_files

# Step 6: Copy the archive to the S3 bucket using AWS CLI
aws s3 cp "$tmp_dir/$tar_file" "s3://$s3_bucket/"

# Clean up the temporary tar file
rm "$tmp_dir/$tar_file"

echo "Script completed successfully."