#!/bin/bash

# Program title
# Version 1.3
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

# Function to check the device
check_device() {
    local product_found=false
    local non_mtk_found=false
    
    # Capturing the SIGINT signal (Ctrl+c) interrupts monitoring to return to the main menu
    trap 'echo ""; echo "Monitoring interrupted. Returning to the main menu..."; sleep 1; show_menu' INT

    # Monitor the logs
    while read -r line; do
        # Checks whether the connected device has a MediaTek chip
        if [[ "$line" =~ "idVendor=0e8d" || "$line" =~ "idVendor=08ed" ]]; then
            echo "#############################################################################################################"
            echo "The device has a MediaTek Inc. chip."
            product_found=true
        else
            # Mark as device not found if the device is not MediaTek
            if [[ "$line" =~ "idVendor" ]]; then
                non_mtk_found=true
            fi
        fi
        
        # Displays the log line that contains "idProduct"
        if [[ "$line" =~ "idProduct" ]]; then
            echo "$line"
        fi

        # If a MediaTek device is found, displays additional information
        if $product_found; then
            {
                # Monitor the kernel log for 15 seconds or until it finds the line containing "Product:"
                timeout -s 15 15 tail -f /var/log/kern.log | grep -m 1 -i "Product:" | while read -r product_line; do
                    echo "$product_line"
                    break
                done
            } &
            local tail_pid=$!
            wait $tail_pid 2>/dev/null

            # Lists connected USB devices and displays the line containing "MediaTek"
            lsusb | grep -i "MediaTek"
            echo "#############################################################################################################"
            break  # Stop the loop after finding and displaying the information
        fi

        # If it finds a non-MediaTek device, it stops scanning and displays No MediaTek devices found
        if $non_mtk_found && [ "$product_found" = false ]; then
            echo ""
            echo "##############################"
            echo "# No MediaTek devices found. #"
            echo "##############################"
            echo ""
            break
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
        echo "2) Force clearing logs for new search (option 1)"
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
