#!/bin/bash

# Program title
# Version 1.1
# English version
echo ""
echo "##########################"
echo "# MTK dumb phone checker #"
echo "##########################"
echo ""
echo "O_o Nelson Guia o_O"
echo ""

# Pause so the title is visible
sleep 2

# Function to check whether the device contains "idVendor=0e8d" or "idVendor=08ed" and report whether it is a MediaTek device
check_device() {
    local product_found=false

    # Capturing the SIGINT signal (Ctrl+c) interrupts monitoring to return to the main menu
    trap 'echo ""; echo "Monitoring interrupted. Returning to the main menu..."; sleep 1; show_menu' INT

    while read -r line; do
        if [[ "$line" =~ "idVendor=0e8d" || "$line" =~ "idVendor=08ed" ]]; then
            echo "############################################################"
            echo "The device has a MediaTek Inc. chip."
            product_found=true
        elif $product_found && [[ "$line" =~ "Product:" ]]; then
            echo "$line"
            echo "############################################################"
            break  # Stop the loop after finding the product
        fi
    done < <(journalctl -kf)
}

# Function to display the menu and start device scanning
show_menu() {
    while true; do
        clear
        echo ""
        echo "##########################"
        echo "# MTK dumb phone checker #"
        echo "##########################"
        echo ""
        echo "Select an option:"
        echo "1) Start search to check if it is a MediaTek device"
        echo "2) Force clearing of logs (if necessary) for new search (option 1)"
        echo "3) Exit"

        read -rp "Option: " choice </dev/tty

        case $choice in
            1)
                echo ""
                echo "To stop the search and return to the main menu, press the 'Ctrl+C' keys"
                echo ""
                echo "============================================================"
                echo "= Connect the cell phone to the computer using the USB     ="
                echo "= cable and wait for it to start charging... If necessary, ="
                echo "= disconnect the cable, wait a while and connect again...  ="
                echo "============================================================"
                echo ""
                check_device
                echo ""
                read -rp "Press Enter to return to the menu..."
                ;;
            2)
                echo ""
                echo "=================================="
                echo "=        Cleaning logs...        ="
                echo "=================================="
                echo ""
                sudo journalctl --rotate
                sudo journalctl --vacuum-time=1s
                echo ""
                echo "================================================"
                echo "= Logs deleted, you can perform a new search   ="
                echo "= to check if it is a MediaTek device.         ="
                echo "================================================"
                echo ""
                read -rp "Press Enter to return to the menu..."
                ;;
            3)
                echo ""
                echo "Exiting... See you soon!"
                echo ""
                exit
                ;;
            *)
                echo "Invalid option. Please choose a valid option."
                read -rp "Press Enter to continue..."
                ;;
        esac
    done
}

# Start the menu
show_menu
