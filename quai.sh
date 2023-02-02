#!/bin/bash

DIALOG_CANCEL=1
DIALOG_ESC=255
DIALOGRC=~/.dialogrc

STYLECONFIG=~/.dialogrc
if [ -f "$STYLECONFIG" ]; then
    echo "Styling config found."
else
    dialog --create-rc $STYLECONFIG
    cp .dialogrc ~/.dialogrc
fi

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

    if [ -d "$HOME/quainetwork/go-quai/nodelogs" ]; then
        NODELOGS="True"
    else
        NODELOGS="False"
    fi

    if [ -d "$HOME/quainetwork/quai-manager/logs" ]; then
        MININGLOGS="True"
    else
        MININGLOGS="False"
    fi

    node_process_name="go-quai"
    manager_process_name="quai-manager"

    # Check if full node is running
    if pgrep -x "$node_process_name" >/dev/null; then
        ISRUNNING="True"
        STARTFULLNODE="Full Node - Running ✔"
    else
        ISRUNNING="False"
        STARTFULLNODE="Start Full Node"
    fi

    # Check if manager is running
    if pgrep -x "$manager_process_name" >/dev/null; then
        ISMINING="True"
        STARTMINING="Manager - Running ✔"
    else
        ISMINING="False"
        STARTMINING="Start Manager"
    fi

  exec 3>&1
  selection=$(dialog \
    --backtitle "Quai Hardware Manager" \
    --clear \
    --cancel-label "EXIT" \
    --menu "Select an Option:" 14 50 10 \
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
      # Verify the user wants to stop their node and manager
      dialog --title "Alert" --yesno "\nExit the program? This will stop your node and miner." 0 0
      response=$?
      EXIT="False"
      case $response in
          0) EXIT="True";;
          1) EXIT="False";;
          255) EXIT="False";;
      esac
      if $EXIT; then
          #If user chooses stop, kill full node
          cd $HOME/quainetwork/quai-manager
          make stop>/dev/null 2>&1
          cd $HOME/quainetwork/go-quai
          make stop>/dev/null 2>&1 | \
          dialog --title "Stop" \
          --no-collapse \
          --infobox "\nStopping Full-Node and/or Manager. Please wait."  0 0
          clear
        echo "Program terminated."
        exit
      fi
      ;;
    $DIALOG_ESC)
      # Verify the user wants to stop their node and manager
      dialog --yesno "\nExit the program? This will stop your node and miner." 0 0
      response=$?
      EXIT="False"
      case $response in
          0) EXIT="True";;
          1) EXIT="False";;
          255) EXIT="False";;
      esac
      if $EXIT; then
          #If user chooses stop, kill full node
          cd $HOME/quainetwork/quai-manager
          make stop>/dev/null 2>&1
          cd $HOME/quainetwork/go-quai
          make stop>/dev/null 2>&1 | \
          dialog --title "Stop" \
          --no-collapse \
          --infobox "\nStopping Full-Node and/or Manager. Please wait."  0 0
          clear
        echo "Program terminated."
        exit
      fi
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

        dialog --yesno "\nThis will install go-quai and quai-manager in the HOME directory. Continue?" 0 0
        response=$?
        case $response in
            0) 
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
                ;;
            1) INSTALL="False";;
            255) INSTALL="False";;
        esac
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

        dialog --title "Update" \
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
            cd $HOME/quainetwork/go-quai && make run-all
            
            # Ask the user if they would like to view nodelogs
            dialog --title "Alert" \
            --no-collapse \
            --yesno  "\nFull-Node started. Would you like to view the last 40 lines of your nodelogs?" 0 0
            response=$?
            case $response in
                0) 
                    #Print nodelogs
                    cd
                    LOCATION=$(dialog --nocancel --menu "In which location would you like to view nodelogs?" 0 0 13 \
                            1 "Prime" \
                            2 "Cyprus" \
                            3 "Paxos" \
                            4 "Hydra" \
                            5 "Cyprus-1" \
                            6 "Cyprus-2" \
                            7 "Cyprus-3" \
                            8 "Paxos-1" \
                            9 "Paxos-2" \
                            10 "Paxos-3" \
                            11 "Hydra-1" \
                            12 "Hydra-2" \
                            13 "Hydra-3" 3>&1 1>&2 2>&3 3>&- )
                    case $LOCATION in
                        1) 
                            FILE="quainetwork/go-quai/nodelogs/prime.log"
                            ;;
                        2)
                            FILE="quainetwork/go-quai/nodelogs/region-0.log"
                            ;;
                        3)
                            FILE="quainetwork/go-quai/nodelogs/region-1.log"
                            ;;
                        4)
                            FILE="quainetwork/go-quai/nodelogs/region-2.log"
                            ;;
                        5)
                            FILE="quainetwork/go-quai/nodelogs/zone-0-0.log"
                            ;;
                        6)
                            FILE="quainetwork/go-quai/nodelogs/zone-0-1.log"
                            ;;
                        7)
                            FILE="quainetwork/go-quai/nodelogs/zone-0-2.log"
                            ;;
                        8)
                            FILE="quainetwork/go-quai/nodelogs/zone-1-0.log"
                            ;;
                        9)
                            FILE="quainetwork/go-quai/nodelogs/zone-1-1.log"
                            ;;
                        10)
                            FILE="quainetwork/go-quai/nodelogs/zone-1-2.log"
                            ;;
                        11)
                            FILE="quainetwork/go-quai/nodelogs/zone-2-0.log"
                            ;;
                        12)
                            FILE="quainetwork/go-quai/nodelogs/zone-2-1.log"
                            ;;
                        13)
                            FILE="quainetwork/go-quai/nodelogs/zone-2-2.log"
                            ;;
                    esac
                    result=`tail -40 $FILE`
                    dialog --cr-wrap --title "$FILE" --no-collapse --msgbox "\n$result" 30 90
                    ;;
                1) clear;;
                255) clear;;
            esac
        fi
      ;;
    4 )
        #If manager is running, redirect back to menu
        if $ISMINING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nManager is already running." 0 0
        elif ! $ISRUNNING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease start your Full-Node before starting the Manager." 0 0
        else
            REGION=$(dialog --nocancel --menu "Which regiond would you like to mine?" 0 0 3 \
                1 "Cyprus" \
                2 "Paxos" \
                3 "Hydra" 3>&1 1>&2 2>&3 3>&- )
            ZONE=$(dialog --nocancel --menu "Which region would you like to mine?" 0 0 3 \
                1 "Zone-0" \
                2 "Zone-1" \
                3 "Zone-2" 3>&1 1>&2 2>&3 3>&- )

            # Start go-quai
            REGION=$(($REGION-1))
            ZONE=$(($ZONE-1))
            cd $HOME/quainetwork/quai-manager && make run-mine-background region=$REGION zone=$ZONE
            ISMINING="True"
            ISRUNNING="False"

            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "Manager started in: \nRegion: $REGION \nZone: $ZONE" 0 0
            
            # Ask the user if they would like to view nodelogs
            dialog --title "Alert" \
            --no-collapse \
            --yesno  "\nManager started. Would you like to view the last 40 lines of your miner logs?" 0 0
            response=$?
            case $response in
                0) 
                    # Print nodelogs
                    cd
                    result=`tail -40 quainetwork/quai-manager/logs/quai-manager.log`
                    dialog --cr-wrap --title "quainetwork/quai-manger/logs/quai-manager.log" --msgbox "\n$result" 30 90
                    ;;
                1) clear;;
                255) clear;;
            esac
        fi
      ;;
    5 )
        # Verify the user wants to stop their node and manager
        dialog --title "Alert" --yesno "\nAre you sure you want to stop the Full Node and/or Manager?" 0 0
        response=$?
        STOP="False"
        case $response in
            0) STOP="True";;
            1) STOP="False";;
            255) STOP="False";;
        esac
        if $STOP; then
            #If user chooses stop, kill full node
            cd $HOME/quainetwork/quai-manager
            make stop>/dev/null 2>&1
            cd $HOME/quainetwork/go-quai
            make stop>/dev/null 2>&1 | \
            dialog --title "Stop" \
            --no-collapse \
            --infobox "\nStopping Full-Node and/or Manager. Please wait."  0 0
            dialog --title "Stop" \
            --no-collapse \
            --msgbox "\nFull-Node and/or Manager stopped. Press OK to return to the menu." 0 0
        fi
      ;;
    6 )
        if ! $NODELOGS; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox "\nPlease start your full-node before viewing nodelogs." 0 0
        else
            #Print nodelogs
            cd
            LOCATION=$(dialog --nocancel --menu "In which location would you like to view nodelogs?" 0 0 13 \
                    1 "Prime" \
                    2 "Cyprus" \
                    3 "Paxos" \
                    4 "Hydra" \
                    5 "Cyprus-1" \
                    6 "Cyprus-2" \
                    7 "Cyprus-3" \
                    8 "Paxos-1" \
                    9 "Paxos-2" \
                    10 "Paxos-3" \
                    11 "Hydra-1" \
                    12 "Hydra-2" \
                    13 "Hydra-3" 3>&1 1>&2 2>&3 3>&- )
            dialog --nocancel --pause "This will show the last 40 lines of your nodelogs. Press OK to continue." 10 40 2
            case $LOCATION in
                1) 
                    FILE="quainetwork/go-quai/nodelogs/prime.log"
                    ;;
                2)
                    FILE="quainetwork/go-quai/nodelogs/region-0.log"
                    ;;
                3)
                    FILE="quainetwork/go-quai/nodelogs/region-1.log"
                    ;;
                4)
                    FILE="quainetwork/go-quai/nodelogs/region-2.log"
                    ;;
                5)
                    FILE="quainetwork/go-quai/nodelogs/zone-0-0.log"
                    ;;
                6)
                    FILE="quainetwork/go-quai/nodelogs/zone-0-1.log"
                    ;;
                7)
                    FILE="quainetwork/go-quai/nodelogs/zone-0-2.log"
                    ;;
                8)
                    FILE="quainetwork/go-quai/nodelogs/zone-1-0.log"
                    ;;
                9)
                    FILE="quainetwork/go-quai/nodelogs/zone-1-1.log"
                    ;;
                10)
                    FILE="quainetwork/go-quai/nodelogs/zone-1-2.log"
                    ;;
                11)
                    FILE="quainetwork/go-quai/nodelogs/zone-2-0.log"
                    ;;
                12)
                    FILE="quainetwork/go-quai/nodelogs/zone-2-1.log"
                    ;;
                13)
                    FILE="quainetwork/go-quai/nodelogs/zone-2-2.log"
                    ;;
            esac
            result=`tail -40 $FILE`
            dialog --cr-wrap --title "$FILE" --msgbox "\n$result" 0 0
        fi
      ;;
    7 )
        if ! $MININGLOGS; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox "\nPlease start your manager before viewing manager logs." 0 0
        else
            # Print Miner Logs
            cd
            dialog --nocancel --pause "This will show the last 40 lines of your miner logs. Press OK to continue." 10 40 2
            result=`tail -40 quainetwork/quai-manager/logs/quai-manager.log`
            dialog --cr-wrap --title "quainetwork/quai-manager/logs/quai-manager.log" --msgbox "\n$result" 30 90
        fi
      ;;
  esac
done