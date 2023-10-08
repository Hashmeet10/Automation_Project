#!/bin/bash

# Variables
s3_bucket="upgrad-hashmeet"
your_name="Hashmeet"
web_dir="/var/www/html"
inventory_file="$web_dir/inventory.html"
log_type="httpd-logs"
cron_job_file="/etc/cron.d/automation"
script_path="/root/$(basename $(pwd))/automation.sh"

# Function to check if a cron job is already scheduled
is_cron_job_scheduled() {
    [[ -f "$cron_job_file" ]]
}

# Function to create a cron job
create_cron_job() {
    echo "Creating a daily cron job to run the script..."
    echo "0 0 * * * root $script_path" | sudo tee "$cron_job_file" > /dev/null
    sudo chmod 0644 "$cron_job_file"
}

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

# Step 7: Check for the presence of inventory.html and create it if not found
if [ ! -f "$inventory_file" ]; then
    echo -e "Log Type\tDate Created\tType\tSize" | sudo tee "$inventory_file" > /dev/null
fi
e
# Step 8: Append entry to the inventory.html file
archive_type="tar"
archive_size=$(du -sh "$tmp_dir/$tar_file" | cut -f1)
archive_date=$(date '+%d%m%Y-%H%M%S')
echo -e "$log_type\t$archive_date\t$archive_type\t$archive_size" | sudo tee -a "$inventory_file" > /dev/null

# Step 9: Check and create the cron job if not scheduled
if ! is_cron_job_scheduled; then
    create_cron_job
fi

# Clean up the temporary tar file
rm "$tmp_dir/$tar_file"

echo "Script completed successfully."