#!/bin/bash

DIALOG_CANCEL=1
DIALOG_ESC=255
STYLECONFIG=~/.dialogrc
MAIN_DIR="quainetwork"
NODE_PROCESS="go-quai"
MINER_PROCESS="quai-cpu-miner"

if [ -f "$STYLECONFIG" ]; then
    echo "Styling config found."
    if cmp --silent "$STYLECONFIG" ".dialogrc"; then
        :
    else
        cp .dialogrc ~/.dialogrc
    fi
else
    dialog --create-rc $STYLECONFIG
    cp .dialogrc ~/.dialogrc
fi

if command -v go 2>/dev/null; then
    :
else
    dialog --title "Installation" --msgbox "\nGolang is not installed. Please install to run this script." 0 0
    echo "Golang can be installed at https://go.dev/doc/install"
    exit
fi

if command -v git 2>/dev/null; then
    :
else
    dialog --title "Installation" --msgbox "\nGit is not installed. Please install to run this script." 0 0
    echo "Git can be installed at https://github.com/git-guides/install-git"
    exit
fi

# Check installation status, if not found, prompt the user to install.
if [[ -d "$HOME/$MAIN_DIR/go-quai" && -d "$HOME/$MAIN_DIR/quai-cpu-miner" ]]; then
    :
else
    # Check if user has configured wallet addresses
    dialog --title "Installation" --yesno "\nHave you configured 13 Quai addresses? You'll need them to run a node and mine." 0 0
    response=$?
    case $response in
        0)  : ;;
        1)
            # Inform user to configure addresses
            dialog --title "Installation" --msgbox "\nPlease configure your wallet addresses before continuing." 0 0
            echo "You can set up addresses here: https://docs.quai.network/use-quai/wallets/quaisnap"
            exit
            ;;
        255)
            exit
            ;;
    esac

    # Check if user wants to install
    dialog --title "Installation" --yesno "\nThis will install go-quai and quai-cpu-miner in the home directory. Continue?" 0 0
    response=$?
    case $response in
        0) 
            # Create directory
            cd $HOME
            mkdir $MAIN_DIR
            # Clone into go-quai
            cd $MAIN_DIR
            git clone https://github.com/dominant-strategies/go-quai>/dev/null 2>&1 | \
            dialog --title "Installation" \
            --no-collapse \
            --infobox "\nInstalling Node. Please wait."  7 28
            
            #Inform user node is installed
            dialog --title "Installation" \
            --no-collapse \
            --msgbox "\nNode installed.\n \nPress OK to continue." 7 28

            #Configure go-quai
            cd $HOME/$MAIN_DIR/go-quai
            cp network.env.dist network.env
            make go-quai>/dev/null 2>&1 | 
            dialog --title "Installation" \
            --no-collapse \
            --infobox "\nGenerating binaries.\n \nPlease wait. " 7 28

            #Inform user node is configured
            dialog --title "Installation" \
            --no-collapse \
            --msgbox "\nNode configured.\n \nPress OK to continue." 0 0

            # Clone into quai-cpu-miner
            cd $HOME/$MAIN_DIR
            git clone https://github.com/dominant-strategies/quai-cpu-miner>/dev/null 2>&1 | \
            dialog --title "Installation" \
            --no-collapse \
            --infobox "\nInstalling Miner.\n \nPlease wait."  7 28
            
            #Inform user miner is installed
            dialog --title "Installation" \
            --no-collapse \
            --msgbox "\nMiner installed.\n \nPress OK to continue." 7 28

            #Configure quai-cpu-miner
            cd $HOME/$MAIN_DIR/quai-cpu-miner/config
            cp config.yaml.dist config.yaml
            cd $HOME/$MAIN_DIR/quai-cpu-miner
            make quai-cpu-miner>/dev/null 2>&1 | \
            dialog --title "Installation" 
            --no-collapse \
            --infobox "\nGenerating binaries.\n \nPlease wait. " 7 28

            #Inform user miner is configured
            dialog --title "Installation" \
            --no-collapse \
            --msgbox "\nMiner configured.\n \nInstallation complete." 0 0
            ;;
        1) 
            echo "Installation cancelled."
            exit ;;
        255) 
            echo "Installation cancelled."
            exit ;;
    esac
fi

while true; do
    # Check if node logs exist (psuedo-check to see if the node has been started before)
    if [ -d "$HOME/$MAIN_DIR/go-quai/nodelogs" ]; then
        NODELOGS="True"
    else
        NODELOGS="False"
    fi

    # Check if miner logs exist (psuedo-check to see if the miner has been started before)
    if [ -d "$HOME/$MAIN_DIR/quai-cpu-miner/logs" ]; then
        MININGLOGS="True"
    else
        MININGLOGS="False"
    fi

    # Check if node is running
    if pgrep -x "$NODE_PROCESS">/dev/null 2>&1; then
        ISRUNNING="True"
        STARTFULLNODE="Node - \Z2Running\Zn"
    else
        ISRUNNING="False"
        STARTFULLNODE="Start Node - \Z1Stopped\Zn"
    fi

    # Check if miner is running
    if pgrep -x "$MINER_PROCESS">/dev/null 2>&1; then
        ISMINING="True"
        STARTMINING="Miner - \Z2Running\Zn"
    else
        ISMINING="False"
        STARTMINING="Start Miner - \Z1Stopped\Zn"
    fi

    exec 3>&1
    selection=$(dialog \
        --backtitle "Quai Hardware Manager" \
        --clear \
        --colors \
        --cancel-label "EXIT" \
        --menu "Select an Option:" 14 50 10 \
        "1" "$STARTFULLNODE" \
        "2" "$STARTMINING" \
        "3" "Stop" \
        "4" "Update" \
        "5" "Node Logs" \
        "6" "Miner Logs" \
        2>&1 1>&3)
    exit_status=$?
    exec 3>&-
    case $exit_status in
        $DIALOG_CANCEL)
        # Verify the user wants to stop their node and miner
        dialog --colors --title "Alert" --yesno "\nExit the Quai Hardware Manager?\n \n\Z1This will stop your node and miner.\Zn" 0 0
        response=$?
        EXIT="False"
        case $response in
            0) EXIT="True";;
            1) EXIT="False";;
            255) EXIT="False";;
        esac
        if [ $EXIT = "True" ]; then
            #If user chooses stop, kill node
            cd $HOME/$MAIN_DIR/quai-cpu-miner
            make stop>/dev/null 2>&1
            cd $HOME/$MAIN_DIR/go-quai
            make stop>/dev/null 2>&1 | \
            dialog --title "Stop" \
            --colors \
            --no-collapse \
            --infobox "\nStopping Node and/or Miner.\n \nPlease wait."  0 0
            clear
            echo "Quai Hardware Manager stopped."
            exit
        fi
        ;;
        $DIALOG_ESC)
        # Verify the user wants to stop their node and miner
        dialog --colors --title "Alert" --yesno "\nExit the Quai Hardware Manager?\n \n\Z1This will stop your node and miner.\Zn" 0 0
        response=$?
        EXIT="False"
        case $response in
            0) EXIT="True";;
            1) EXIT="False";;
            255) EXIT="False";;
        esac
        if [ $EXIT = "True" ]; then
            #If user chooses stop, kill node
            cd $HOME/$MAIN_DIR/quai-cpu-miner
            make stop>/dev/null 2>&1
            cd $HOME/$MAIN_DIR/go-quai
            make stop>/dev/null 2>&1 | \
            dialog --title "Stop" \
            --colors \
            --no-collapse \
            --infobox "\nStopping Node and/or Miner. Please wait."  0 0
            clear
            echo "Quai Hardware Manager stopped."
            exit
        fi
        ;;
    esac
    case $selection in
        1 )
            #If node is running, redirect back to menu
            if [ $ISRUNNING = "True" ]; then
                dialog --title "Alert" \
                --no-collapse \
                --msgbox  "\nNode is already running." 0 0
            else
                

                # Start go-quai
                cd $HOME/$MAIN_DIR/go-quai && make run-all>/dev/null 2>&1 | \
                dialog --title "Node" \
                --no-collapse \
                --infobox "\nStarting Node. Please wait." 0 0
                
                # Ask the user if they would like to view nodelogs
                dialog --title "Alert" \
                --no-collapse \
                --yesno  "\nNode started. Would you like to view the last 40 lines of your nodelogs?" 0 0
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
                                FILE="$MAIN_DIR/go-quai/nodelogs/prime.log"
                                ;;
                            2)
                                FILE="$MAIN_DIR/go-quai/nodelogs/region-0.log"
                                ;;
                            3)
                                FILE="$MAIN_DIR/go-quai/nodelogs/region-1.log"
                                ;;
                            4)
                                FILE="$MAIN_DIR/go-quai/nodelogs/region-2.log"
                                ;;
                            5)
                                FILE="$MAIN_DIR/go-quai/nodelogs/zone-0-0.log"
                                ;;
                            6)
                                FILE="$MAIN_DIR/go-quai/nodelogs/zone-0-1.log"
                                ;;
                            7)
                                FILE="$MAIN_DIR/go-quai/nodelogs/zone-0-2.log"
                                ;;
                            8)
                                FILE="$MAIN_DIR/go-quai/nodelogs/zone-1-0.log"
                                ;;
                            9)
                                FILE="$MAIN_DIR/go-quai/nodelogs/zone-1-1.log"
                                ;;
                            10)
                                FILE="$MAIN_DIR/go-quai/nodelogs/zone-1-2.log"
                                ;;
                            11)
                                FILE="$MAIN_DIR/go-quai/nodelogs/zone-2-0.log"
                                ;;
                            12)
                                FILE="$MAIN_DIR/go-quai/nodelogs/zone-2-1.log"
                                ;;
                            13)
                                FILE="$MAIN_DIR/go-quai/nodelogs/zone-2-2.log"
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
        2 )
            #If miner is running, redirect back to menu
            if [ $ISMINING = "True" ]; then
                dialog --title "Alert" \
                --no-collapse \
                --msgbox  "\nMiner is already running." 0 0
            elif [ $ISRUNNING = "False" ]; then
                dialog --title "Alert" \
                --no-collapse \
                --msgbox  "\nPlease start your Node before starting the Miner." 0 0
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
                cd $HOME/$MAIN_DIR/quai-cpu-miner && make run-mine-background region=$REGION zone=$ZONE

                dialog --title "Alert" \
                --no-collapse \
                --msgbox  "Miner started in: \nRegion: $REGION \nZone: $ZONE" 0 0
                
                # Ask the user if they would like to view nodelogs
                dialog --title "Alert" \
                --no-collapse \
                --yesno  "\nMiner started. Would you like to view the last 40 lines of your miner logs?" 0 0
                response=$?
                case $response in
                    0) 
                        # Print nodelogs
                        cd
                        result=`tail -40 $MAIN_DIR/quai-cpu-miner/logs/slice-$REGION-$ZONE.log`
                        dialog --cr-wrap --title "$MAIN_DIR/quai-manger/logs/slice-$REGION-$ZONE.log" --msgbox "\n$result" 30 90
                        ;;
                    1) clear;;
                    255) clear;;
                esac
            fi
        ;;
        3 )
            # Verify the user wants to stop their node and miner
            dialog --title "Alert" --yesno "\nAre you sure you want to stop the Node and/or Miner?" 0 0
            response=$?
            STOP="False"
            case $response in
                0) STOP="True";;
                1) STOP="False";;
                255) STOP="False";;
            esac
            if [ $STOP = "True" ]; then
                #If user chooses stop, kill node
                cd $HOME/$MAIN_DIR/quai-cpu-miner
                make stop>/dev/null 2>&1
                cd $HOME/$MAIN_DIR/go-quai
                make stop>/dev/null 2>&1 | \
                dialog --title "Stop" \
                --no-collapse \
                --infobox "\nStopping Node and/or Miner. Please wait."  0 0
                dialog --title "Stop" \
                --no-cancel \
                --msgbox "\nNode and/or Miner stopped. Press OK to return to the menu." 0 0
            fi
        ;;
        4 )
            if [ $ISMINING = "True" ]; then
                dialog --title "Alert" \
                --no-collapse \
                --msgbox  "\nPlease stop your node and miner to update." 0 0
            elif [ $ISRUNNING = "True" ]; then
                dialog --title "Alert" \
                --no-collapse \
                --msgbox  "\nPlease stop your node and miner to update." 0 0
            else
                # Update go-quai
                cd $HOME/$MAIN_DIR/go-quai
                git pull>/dev/null 2>&1 | \
                dialog --title "Update" \
                --no-collapse \
                --infobox "\nUpdating Node. Please wait."  7 28

                make go-quai>/dev/null 2>&1 | \
                dialog --title "Update" \
                --no-collapse \
                --infobox "\nUpdating Node. Please wait."  7 28
                
                dialog --title "Update" \
                --no-collapse \
                --msgbox "\nNode updated. Press OK to continue." 7 28

                # Update quai-cpu-miner
                cd $HOME/$MAIN_DIR/quai-cpu-miner 
                git pull>/dev/null 2>&1 | \
                dialog --title "Update" \
                --no-collapse \
                --infobox "\nUpdating Miner. Please wait."  7 28
                
                make quai-cpu-miner>/dev/null 2>&1 | \
                dialog --title "Update" \
                --no-collapse \
                --infobox "\nUpdating Miner. Please wait."  7 28
                
                dialog --title "Update" \
                --no-collapse \
                --msgbox "\nMiner updated. Press OK to return to the menu." 0 0
            fi
        ;;
        5 )
            if [ $NODELOGS = "False" ]; then
                dialog --title "Alert" \
                --no-collapse \
                --msgbox "\nPlease start your node before viewing nodelogs." 0 0
            else
                #Print nodelogs
                cd $HOME
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
                        FILE="$MAIN_DIR/go-quai/nodelogs/prime.log"
                        ;;
                    2)
                        FILE="$MAIN_DIR/go-quai/nodelogs/region-0.log"
                        ;;
                    3)
                        FILE="$MAIN_DIR/go-quai/nodelogs/region-1.log"
                        ;;
                    4)
                        FILE="$MAIN_DIR/go-quai/nodelogs/region-2.log"
                        ;;
                    5)
                        FILE="$MAIN_DIR/go-quai/nodelogs/zone-0-0.log"
                        ;;
                    6)
                        FILE="$MAIN_DIR/go-quai/nodelogs/zone-0-1.log"
                        ;;
                    7)
                        FILE="$MAIN_DIR/go-quai/nodelogs/zone-0-2.log"
                        ;;
                    8)
                        FILE="$MAIN_DIR/go-quai/nodelogs/zone-1-0.log"
                        ;;
                    9)
                        FILE="$MAIN_DIR/go-quai/nodelogs/zone-1-1.log"
                        ;;
                    10)
                        FILE="$MAIN_DIR/go-quai/nodelogs/zone-1-2.log"
                        ;;
                    11)
                        FILE="$MAIN_DIR/go-quai/nodelogs/zone-2-0.log"
                        ;;
                    12)
                        FILE="$MAIN_DIR/go-quai/nodelogs/zone-2-1.log"
                        ;;
                    13)
                        FILE="$MAIN_DIR/go-quai/nodelogs/zone-2-2.log"
                        ;;
                esac
                result=`tail -40 $FILE`
                dialog --cr-wrap --title "$FILE" --msgbox "\n$result" 0 0
            fi
        ;;
        6 ) 
            if [ $MININGLOGS = "False" ]; then
                dialog --title "Alert" \
                --no-collapse \
                --msgbox "\nPlease start your miner before viewing logs." 0 0
            else
                # Print Miner Logs
                REGION=$(dialog --nocancel --menu "Which region would you like to view logs for?" 0 0 3 \
                    1 "Cyprus" \
                    2 "Paxos" \
                    3 "Hydra" 3>&1 1>&2 2>&3 3>&- )
                ZONE=$(dialog --nocancel --menu "Which region would you like to view logs for?" 0 0 3 \
                    1 "Zone-1" \
                    2 "Zone-2" \
                    3 "Zone-3" 3>&1 1>&2 2>&3 3>&- )
                # Start miner
                REGION=$(($REGION-1))
                ZONE=$(($ZONE-1))
                cd
                result=`tail -40 quainetwork/quai-cpu-miner/logs/slice-$REGION-$ZONE.log`
                dialog --cr-wrap --title "quainetwork/quai-cpu-miner/logs/slice-$REGION-$ZONE.log" --msgbox "\n$result" 30 90
            fi
        ;;
  esac
done