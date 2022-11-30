#!/bin/bash

# while-menu-dialog: a menu driven system information program

DIALOG_CANCEL=1
DIALOG_ESC=255
HEIGHT=16
WIDTH=50
ISRUNNING="False"
ISMINING="False"

while true; do
    arr=("$HOME/quainetwork/go-quai" "$HOME/quainetwork/quai-manager")
    for i in "${arr[@]}"; do
        if [ -d "$i" ]; then
            INSTALLED="True"
            INSTALL_DISPLAY="Installed ✔"
        else
            INSTALLED=Install
            INSTALL_DISPLAY="Install"
        fi
    done

    if $ISRUNNING; then
        STARTFULLNODE="Full Node - Running ✔"
        STARTMINING="Manager - Stopped x"
    elif $ISMINING; then
        STARTFULLNODE="Full Node - Running ✔"
        STARTMINING="Manager - Running ✔"
    else
        STARTFULLNODE="Start Full Node"
        STARTMINING="Start Full Node and Manager"
    fi

  exec 3>&1
  selection=$(dialog \
    --backtitle "Quai Hardware Manager" \
    --title "Menu" \
    --clear \
    --cancel-label "EXIT" \
    --menu "Please select:" $HEIGHT $WIDTH 10 \
    "1" "$INSTALL_DISPLAY" \
    "2" "Update" \
    "3" "$STARTFULLNODE" \
    "4" "$STARTMINING" \
    "5" "Stop" \
    "6" "Print Node Logs" \
    "7" "Print Miner Logs" \
    2>&1 1>&3)
  exit_status=$?
  exec 3>&-
  case $exit_status in
    $DIALOG_CANCEL)
      clear
      echo "Program terminated."
      exit
      ;;
    $DIALOG_ESC)
      clear
      echo "Program aborted." >&2
      exit 1
      ;;
  esac
  case $selection in
    1 )
      #If installed, redirect back to menu
      if $INSTALLED; then
        dialog --title "Alert" \
        --no-collapse \
        --msgbox  "\ngo-quai and quai-manager have already been installed." 0 0
      else
        # Move to home directory
        cd
        MAIN_DIR="quainetwork"
        mkdir $MAIN_DIR

        # Clone into go-quai
        cd $MAIN_DIR
        git clone https://github.com/dominant-strategies/go-quai>/dev/null 2>&1 | \
        dialog --title "Installation" \
        --no-collapse \
        --infobox "\nInstalling Full-Node. Please wait."  7 28

        dialog --title "Installation" \
        --no-collapse \
        --msgbox "\nFull-Node installed. Press OK to continue." 7 28

        #Configure go-quai
        cd $HOME/$MAIN_DIR/go-quai
        cp network.env.dist network.env
        make go-quai>/dev/null 2>&1 | 
        dialog --title "Installation" \
        --no-collapse \
        --infobox "\nGenerating binaries. Please wait. " 7 28

        dialog --title "Installation" \
        --no-collapse \
        --msgbox "\nFull-Node configured. Press OK to continue." 7 28

        # Clone into quai-manager
        cd $HOME/$MAIN_DIR
        git clone https://github.com/dominant-strategies/quai-manager>/dev/null 2>&1 | \
        dialog --title "Installation" \
        --no-collapse \
        --infobox "\nInstalling Manager. Please wait."  7 28

        dialog --title "Installation" \
        --no-collapse \
        --msgbox "\nManager installed. Press OK to continue." 7 28

        #Configure quai-manager
        cd $HOME/$MAIN_DIR/quai-manager
        make quai-manager>/dev/null 2>&1 | \
        dialog --title "Installation" 
        --no-collapse \
        --infobox "\nGenerating binaries. Please wait. " 7 28

        dialog --title "Installation" \
        --no-collapse \
        --msgbox "\nManager configured. Installation complete. Press OK to return to the menu." 0 0
      fi
      ;;
    2 )
        # Update go-quai
        cd $HOME/quainetwork/go-quai
        git pull>/dev/null 2>&1 && make go-quai>/dev/null 2>&1 | \
        dialog --title "Update" \
        --no-collapse \
        --infobox "\nUpdating Full-Node. Please wait."  7 28
        
        dialog --title "Update" \
        --no-collapse \
        --msgbox "\nFull-Node updated. Press OK to continue." 7 28

        # Update quai-manager
        cd $HOME/quainetwork/quai-manager
        git pull>/dev/null 2>&1 && make quai-manager>/dev/null 2>&1 | \
        dialog --title "Update" \
        --no-collapse \
        --infobox "\nUpdating Manager. Please wait."  7 28

        dialog --title "Alert" \
        --no-collapse \
        --msgbox "\nManager updated. Press OK to return to the menu." 0 0
      ;;
    3 )
        #If node is running, redirect back to menu
        if $ISRUNNING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nFull-Node is already running." 0 0
        else
            # Start go-quai
            cd $HOME/quainetwork/go-quai && make run-full-node
            ISRUNNING="True"
            dialog --title "Alert" \
            --no-collapse \

            # Ask the user if they would like to view nodelogs
            --yesno  "\nFull-Node started. Would you like to view nodelogs?" 0 0
            response=$?
            case $response in
                0) 
                    # Print nodelogs
                    cd
                    FILE=`dialog --stdout --title "Nodelog select" --fselect quainetwork/go-quai/nodelogs/ 14 48`
                    dialog --title "$FILE" --tailbox $FILE 0 0
                    ;;
                1) clear;;
                255) clear;;
            esac
        fi
      ;;
    4 )
        #If node is running, redirect back to menu
        if $ISMINING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nManager is already running." 0 0
        else
            REGION=`dialog --title "Region Select" --rangebox "Which region would you like to mine in?" 0 0 1 3`
            ZONE=`dialog --title "Zone Select" --rangebox "Which zone would you like to mine in?" 0 0 1 3`

            # Start go-quai
            cd $HOME/quainetwork/quai-manager && make run-full-mining region=$REGION zone=$ZONE
            ISMINING="True"
            dialog --title "Alert" \
            --no-collapse \

            # Ask the user if they would like to view nodelogs
            --yesno  "\nManager started. Would you like to view miner logs?" 0 0
            response=$?
            case $response in
                0) 
                    # Print nodelogs
                    cd
                    dialog --title "quainetwork/quai-manger/logs/quai-manager.log" --tailbox quainetwork/quai-manager/logs/quai-manager.log 0 0
                    ;;
                1) clear;;
                255) clear;;
            esac
        fi
      ;;
    5 )
        # Verify the user wants to stop their node and manager
        dialog --yesno "\nAre you sure you want to stop the Full Node and Manager?" 0 0
        response=$?
        STOP="False"
        case $response in
            0) STOP="True";;
            1) STOP="False";;
            255) STOP="False";;
        esac
        if $STOP; then
            #If user chooses stop, kill full node
            cd $HOME/quainetwork/quai-manager && make stop>/dev/null 2>&1 && cd $HOME/quainetwork/go-quai && make stop>/dev/null 2>&1 | \
            dialog --title "Stop" \
            --no-collapse \
            --infobox "\nStopping Full-Node and Manager. Please wait."  0 0
            ISMINING="False"
            ISRUNNING="False"
            
            dialog --title "Stop" \
            --no-collapse \
            --msgbox "\nFull-Node and Manager stopped. Press OK to return to the menu." 0 0
        fi
      ;;
    6 )
        #Print nodelogs
        cd
        FILE=`dialog --stdout --title "Nodelog select" --fselect quainetwork/go-quai/nodelogs/ 14 48`
        dialog --title "$FILE" --tailbox $FILE 0 0
      ;;
    7 )
        # Print Miner Logs
        cd
        dialog --title "quainetwork/quai-manger/logs/quai-manager.log" --tailbox quainetwork/quai-manager/logs/quai-manager.log 0 0
      ;;
  esac
done