#!/bin/bash

set -e

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit 1
    fi
}

# Function to get device name
get_device() {
    read -p "Enter the device name (e.g., /dev/sdb1): " DEVICE
    if [ ! -b "$DEVICE" ]; then
        echo "Error: $DEVICE is not a valid block device."
        exit 1
    fi
}

# Function to get mapper name
get_mapper_name() {
    read -p "Enter the mapper name for the encrypted device: " MAPPER_NAME
}

# Function to get mount point
get_mount_point() {
    read -p "Enter the mount point (e.g., /mnt): " MOUNT_POINT
    if [ ! -d "$MOUNT_POINT" ]; then
        read -p "$MOUNT_POINT does not exist. Create it? (y/n): " CREATE_DIR
        if [ "$CREATE_DIR" = "y" ]; then
            mkdir -p "$MOUNT_POINT"
        else
            echo "Mount point does not exist. Exiting."
            exit 1
        fi
    fi
}

# Function to initialize LUKS
init_luks() {
    echo "Initializing LUKS on $DEVICE"
    cryptsetup luksFormat "$DEVICE"
}

# Function to open LUKS device
open_luks() {
    echo "Opening LUKS device"
    cryptsetup open "$DEVICE" "$MAPPER_NAME"
}

# Function to format device
format_device() {
    echo "Formatting /dev/mapper/$MAPPER_NAME with ext4"
    mkfs.ext4 "/dev/mapper/$MAPPER_NAME"
}

# Function to mount device
mount_device() {
    echo "Mounting /dev/mapper/$MAPPER_NAME to $MOUNT_POINT"
    mount "/dev/mapper/$MAPPER_NAME" "$MOUNT_POINT"
}

# Main script
check_root
get_device
get_mapper_name
get_mount_point

read -p "Is this a new device that needs to be encrypted? (y/n): " NEW_DEVICE

if [ "$NEW_DEVICE" = "y" ]; then
    init_luks
    open_luks
    format_device
else
    open_luks
fi

mount_device

echo "Device successfully encrypted, formatted, and mounted."
echo "To unmount and close the LUKS device, run:"
echo "sudo umount $MOUNT_POINT"
echo "sudo cryptsetup close $MAPPER_NAME"
