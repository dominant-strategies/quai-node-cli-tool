#!/bin/bash

DIALOG_CANCEL=1
DIALOG_ESC=255
ISRUNNING="False"
ISMINING="False"
NODELOGS="False"
MININGLOGS="False"

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
    fi

    if [ -d "$HOME/quainetwork/quai-manager/logs" ]; then
        MININGLOGS="True"
    fi

    if $ISRUNNING; then
        STARTFULLNODE="Full Node - Running ✔"
        STARTMINING="Manager - Stopped x"
    elif $ISMINING; then
        STARTFULLNODE="Full Node - Running ✔"
        STARTMINING="Manager - Running ✔"
    else
        STARTFULLNODE="Start Full Node"
        STARTMINING="Start Manager"
    fi

  exec 3>&1
  selection=$(dialog \
    --backtitle "Quai Hardware Manager" \
    --clear \
    --cancel-label "EXIT" \
    --menu "Select an Option:" 17 50 10 \
    "1" "$INSTALL_DISPLAY" \
    "2" "Update" \
    "3" "$STARTFULLNODE" \
    "4" "$STARTMINING" \
    "5" "Stop" \
    "6" "Print Node Logs" \
    "7" "Print Miner Logs" \
    "8" "Edit Mining Addresses" \
    "9" "Edit Config Directly" \
    "10" "Clear database and logs" \
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
          ISMINING="False"
          ISRUNNING="False"
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
          ISMINING="False"
          ISRUNNING="False"
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
            ISRUNNING="True"
            NODELOGS="True"
            
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
        #If node is running, redirect back to menu
        if $ISMINING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nManager is already running." 0 0
        elif ! $ISRUNNING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease start your Full-Node before starting the Manager." 0 0
        else
            REGION=$(dialog --nocancel --menu "Which region would you like to mine?" 0 0 3 \
                1 "Cyprus" \
                2 "Paxos" \
                3 "Hydra" 3>&1 1>&2 2>&3 3>&- )
            ZONE=$(dialog --nocancel --menu "Which region would you like to mine?" 0 0 3 \
                1 "Zone-1" \
                2 "Zone-2" \
                3 "Zone-3" 3>&1 1>&2 2>&3 3>&- )

            # Start go-quai
            REGION=$REGION-1
            ZONE=$ZONE-1
            cd $HOME/quainetwork/quai-manager && make run-mine-background region=$REGION zone=$ZONE
            ISMINING="True"
            ISRUNNING="False"
            NODELOGS="True"
            MININGLOGS="True"
            
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
            ISMINING="False"
            ISRUNNING="False"
            
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
    8 )
        # Edit coinbase addresses in network.env
        if $ISMINING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease stop your node and manager to edit mining addresses." 0 0
        elif $ISRUNNING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease stop your node and manager to edit mining addresses." 0 0
        else
            cd $HOME/quainetwork/go-quai
            LOCATION=$(dialog --nocancel --menu "Which mining address would you like to edit?" 0 0 13 \
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
                    ADDRESS=$(dialog --nocancel --inputbox "Enter your Prime mining address:" 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^PRIME_COINBASE *=.*/PRIME_COINBASE=$ADDRESS/" network.env | dialog --msgbox "Prime address updated." 0 0
                    ;;
                2)
                    ADDRESS=$(dialog --nocancel --inputbox "Enter your Cyprus mining address:" 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^REGION_0_COINBASE *=.*/REGION_0_COINBASE=$ADDRESS/" network.env | dialog --msgbox "Cyprus address updated." 0 0
                    ;;
                3)
                    ADDRESS=$(dialog --nocancel --inputbox "Enter your Paxos mining address:" 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^REGION_1_COINBASE *=.*/REGION_1_COINBASE=$ADDRESS/" network.env | dialog --msgbox "Paxos address updated." 0 0
                    ;;
                4)
                    ADDRESS=$(dialog --nocancel --inputbox "Enter your Hydra mining address:" 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^REGION_2_COINBASE *=.*/REGION_2_COINBASE=$ADDRESS/" network.env | dialog --msgbox "Hydra address updated." 0 0                
                    ;;
                5)
                    ADDRESS=$(dialog --nocancel --inputbox "Enter your Cyprus-1 mining address:" 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^ZONE_0_0_COINBASE *=.*/ZONE_0_0_COINBASE=$ADDRESS/" network.env | dialog --msgbox "Cyprus-1 address updated." 0 0               
                    ;;
                6)
                    ADDRESS=$(dialog --nocancel --inputbox "Enter your Cyprus-2 mining address:" 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^ZONE_0_1_COINBASE *=.*/ZONE_0_1_COINBASE=$ADDRESS/" network.env | dialog --msgbox "Cyprus-2 address updated." 0 0            
                    ;;
                7)
                    ADDRESS=$(dialog --nocancel --inputbox "Enter your Cyprus-3 mining address:" 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^ZONE_0_2_COINBASE *=.*/ZONE_0_2_COINBASE=$ADDRESS/" network.env | dialog --msgbox "Cyprus-3 address updated." 0 0               
                    ;;
                8)
                    ADDRESS=$(dialog --nocancel --inputbox "Enter your Paxos-1 mining address:" 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^ZONE_1_0_COINBASE *=.*/ZONE_1_0_COINBASE=$ADDRESS/" network.env | dialog --msgbox "Paxos-1 address updated." 0 0            
                    ;;
                9)  
                    ADDRESS=$(dialog --nocancel --inputbox "Enter your Paxos-2 mining address:" 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^ZONE_1_1_COINBASE *=.*/ZONE_1_1_COINBASE=$ADDRESS/" network.env | dialog --msgbox "Paxos-2 address updated." 0 0               
                    ;;
                10)
                    ADDRESS=$(dialog --nocancel --inputbox "Enter your Paxos-3 mining address:" 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^ZONE_1_2_COINBASE *=.*/ZONE_1_2_COINBASE=$ADDRESS/" network.env | dialog --msgbox "Paxos-3 address updated." 0 0                
                    ;;
                11)
                    ADDRESS=$(dialog --nocancel --inputbox "Enter your Hydra-1 mining address:" 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^ZONE_2_0_COINBASE *=.*/ZONE_2_0_COINBASE=$ADDRESS/" network.env | dialog --msgbox "Hydra-1 address updated." 0 0               
                    ;;
                12)
                    ADDRESS=$(dialog --nocancel --inputbox "Enter your Hydra-2 mining address:" 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^ZONE_2_1_COINBASE *=.*/ZONE_2_1_COINBASE=$ADDRESS/" network.env | dialog --msgbox "Hydra-2 address updated." 0 0                
                    ;;
                13)
                    ADDRESS=$(dialog --nocancel --inputbox "Enter your Hydra-3 mining address:" 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^ZONE_2_2_COINBASE *=.*/ZONE_2_2_COINBASE=$ADDRESS/" network.env | dialog --msgbox "Hydra-3 address updated." 0 0           
                    ;;
                esac
            rm -rf network.env.save
        fi
        ;;
    9)
        if $ISMINING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease stop your node and manager to edit your config file." 0 0
        elif $ISRUNNING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease stop your node and manager to edit your config file." 0 0
        else
            # Edit config file
            cd $HOME/quainetwork/go-quai
            dialog --title "network.env" --editbox network.env 0 0 2> /tmp/network.env
            if [ $? -eq 0 ]; then
                cp /tmp/network.env network.env
                rm -rf /tmp/network.env
            fi
            make go-quai>/dev/null 2>&1
            dialog --msgbox "network.env updated." 0 0
        fi
    ;;
    10)
        # Clear db
        if $ISMINING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease stop your node and manager to clear the db." 0 0
        elif $ISRUNNING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease stop your node and manager to clear the db." 0 0
        else
            dialog --yesno "Are you sure you want to clear your database and logs?" 0 0
            if [ $? -eq 0 ]; then
                cd $HOME/quainetwork/go-quai
                rm -rf nodelogs
                rm -rf ~/Library/Quai
                yes | ./build/bin/quai removedb
                cd $HOME/quainetwork/quai-manager/logs
                rm -rf quai-manager.log
                NODELOGS="False"
                MININGLOGS="False"
                dialog --cr-wrap --msgbox "Database cleared. Nodelogs removed." 0 0
            fi 
        fi
    ;;
  esac
done