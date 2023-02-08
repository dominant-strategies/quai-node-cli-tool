#!/bin/bash

DIALOG_CANCEL=1
DIALOG_ESC=255
STYLECONFIG=~/.dialogrc
MAIN_DIR="quainetwork"
NODE_PROCESS="go-quai"
MANAGER_PROCESS="quai-manager"

if [ -f "$STYLECONFIG" ]; then
    echo "Styling config found."
    if cmp --silent "$STYLECONFIG" ".dialogrc"; then
        echo "Styling config is up to date."
    else
        echo "Styling config is out of date."
        cp .dialogrc ~/.dialogrc
    fi
else
    dialog --create-rc $STYLECONFIG
    cp .dialogrc ~/.dialogrc
fi

if command -v go 2>/dev/null; then
    :
else
    dialog --title "Installation" --msgbox "\nGolang is not installed. \nPlease install to run this script." 0 0
    echo "Golang can be installed at https://go.dev/doc/install"
    exit
fi

if command -v git 2>/dev/null; then
    :
else
    dialog --title "Installation" --msgbox "\nGit is not installed. \nPlease install to run this script." 0 0
    echo "Git can be installed at https://github.com/git-guides/install-git"
    exit
fi

# Check installation status, if not found, prompt the user to install.
if [[ -d "$HOME/$MAIN_DIR/go-quai" && -d "$HOME/$MAIN_DIR/quai-manager" ]]; then
    :
else
    # Check if user has configured wallet addresses
    dialog --title "Installation" --yesno "\nHave you configured 13 Quai addresses? \nYou'll need them to run a node and mine." 0 0
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
    dialog --title "Installation" --yesno "\nThis will install go-quai and quai-manager in the home directory.\n \nContinue?" 0 0
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

            # Clone into quai-manager
            cd $HOME/$MAIN_DIR
            git clone https://github.com/dominant-strategies/quai-manager>/dev/null 2>&1 | \
            dialog --title "Installation" \
            --no-collapse \
            --infobox "\nInstalling Manager.\n \nPlease wait."  7 28
            
            #Inform user manager is installed
            dialog --title "Installation" \
            --no-collapse \
            --msgbox "\nManager installed.\n \nPress OK to continue." 7 28

            #Configure quai-manager
            cd $HOME/$MAIN_DIR/quai-manager
            make quai-manager>/dev/null 2>&1 | \
            dialog --title "Installation" 
            --no-collapse \
            --infobox "\nGenerating binaries.\n \nPlease wait. " 7 28

            #Inform user manager is configured
            dialog --title "Installation" \
            --no-collapse \
            --msgbox "\nManager configured.\n \nInstallation complete." 0 0
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

    # Check if node is running
    if pgrep -x "$NODE_PROCESS">/dev/null 2>&1; then
        ISRUNNING="True"
        STARTFULLNODE="Node - \Z2Running\Zn"
    else
        ISRUNNING="False"
        STARTFULLNODE="Start Node - \Z1Stopped\Zn"
    fi

    # Check if manager is running
    if pgrep -x "$MANAGER_PROCESS">/dev/null 2>&1; then
        ISMINING="True"
        STARTMINING="Manager - \Z2Running\Zn"
    else
        ISMINING="False"
        STARTMINING="Start Manager - \Z1Stopped\Zn"
    fi

  exec 3>&1
  selection=$(dialog \
    --backtitle "Quai Hardware Manager" \
    --clear \
    --colors \
    --cancel-label "EXIT" \
    --menu "Select an Option:" 17 50 10 \
    "1" "$STARTFULLNODE" \
    "2" "$STARTMINING" \
    "3" "Stop" \
    "4" "Update" \
    "5" "Node Logs" \
    "6" "Miner Logs" \
    "7" "Edit Mining Addresses" \
    "8" "Edit Config Variables" \
    "9" "Clear logs & db" \
    2>&1 1>&3)
  exit_status=$?
  exec 3>&-
  case $exit_status in
    $DIALOG_CANCEL)
      # Verify the user wants to stop their node and manager
      dialog --title "Alert" --colors --yesno "\nExit the Quai Hardware Manager?\n \n\Z1This will stop your node and miner.\Zn" 0 0
      response=$?
      EXIT="False"
      case $response in
          0) EXIT="True";;
          1) EXIT="False";;
          255) EXIT="False";;
      esac
      if $EXIT; then
          #If user chooses stop, kill node
          cd $HOME/quainetwork/quai-manager
          make stop>/dev/null 2>&1
          cd $HOME/quainetwork/go-quai
          make stop>/dev/null 2>&1 | \
          dialog --title "Stop" \
          --no-collapse \
          --infobox "\nStopping Node and/or Manager.\n \nPlease wait."  0 0
          clear
        echo "Quai Hardware Manager stopped."
        exit
      fi
      ;;
    $DIALOG_ESC)
      # Verify the user wants to stop their node and manager
      dialog --title "Alert" --yesno "\nExit the Quai Hardware Manager?\n \n\Z1This will stop your node and miner.\Zn" 0 0
      response=$?
      EXIT="False"
      case $response in
          0) EXIT="True";;
          1) EXIT="False";;
          255) EXIT="False";;
      esac
      if $EXIT; then
          #If user chooses stop, kill node
          cd $HOME/quainetwork/quai-manager
          make stop>/dev/null 2>&1
          cd $HOME/quainetwork/go-quai
          make stop>/dev/null 2>&1 | \
          dialog --title "Stop" \
          --no-collapse \
          --infobox "\nStopping Node and/or Manager.\n \nPlease wait."  0 0
          clear
        echo "Quai Hardware Manager stopped."
        exit
      fi
      ;;
  esac
  case $selection in
    1 )
        #If node is running, redirect back to menu
        if $ISRUNNING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nNode is already running." 0 0
        else
            # Start go-quai
            cd $HOME/quainetwork/go-quai && make run-all >/dev/null 2>&1 | \
            dialog --title "Node" \
            --no-collapse \
            --infobox "\nStarting Node.\n \nPlease wait." 0 0
            
            # Ask the user if they would like to view nodelogs
            dialog --title "Alert" \
            --no-collapse \
            --yesno  "\nWould you like to view the last 40 lines of your nodelogs?" 0 0
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
    2 )
        #If manager is running, redirect back to menu
        if $ISMINING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nManager is already running." 0 0
        elif ! $ISRUNNING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease start your Node before starting the Manager." 0 0
        else
            REGION=$(dialog --nocancel --menu "Which region would you like to mine?" 0 0 3 \
                1 "Cyprus" \
                2 "Paxos" \
                3 "Hydra" 3>&1 1>&2 2>&3 3>&- )
            ZONE=$(dialog --nocancel --menu "Which region would you like to mine?" 0 0 3 \
                1 "Zone-1" \
                2 "Zone-2" \
                3 "Zone-3" 3>&1 1>&2 2>&3 3>&- )

            # Start manager
            REGION=$(($REGION-1))
            ZONE=$(($ZONE-1))
            cd $HOME/quainetwork/quai-manager && make run-mine-background region=$REGION zone=$ZONE >/dev/null 2>&1 | \
            dialog --title "Manager" \
            --no-collapse \
            --infobox "\nStarting Manager.\n \nPlease wait." 0 0
            
            # Ask the user if they would like to view nodelogs
            dialog --title "Alert" \
            --no-collapse \
            --yesno  "\nWould you like to view the last 40 lines of your miner logs?" 0 0
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
    3 )
        # Verify the user wants to stop their node and manager
            dialog --title "Alert" --colors --yesno "\n\Z1Are you sure you want to stop the Node and/or Manager?\Zn" 0 0
            response=$?
            STOP="False"
            case $response in
                0) STOP="True";;
                1) STOP="False";;
                255) STOP="False";;
            esac
            if [ $STOP = "True" ]; then
                #If user chooses stop, kill node
                cd $HOME/$MAIN_DIR/quai-manager
                make stop>/dev/null 2>&1
                cd $HOME/$MAIN_DIR/go-quai
                make stop>/dev/null 2>&1 | \
                dialog --title "Stop" \
                --no-collapse \
                --infobox "\nStopping Node and/or Manager.\n \nPlease wait."  0 0
                dialog --title "Stop" \
                --no-cancel \
                --msgbox "\nNode and/or Manager stopped.\n \nPress OK to return to the menu." 0 0
            fi
        ;;
    4 )
        # Update go-quai
        if $ISMINING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease stop your node and manager to update." 0 0
        elif $ISRUNNING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease stop your node and manager to update." 0 0
        else
            cd $HOME/$MAIN_DIR/go-quai
            git pull>/dev/null 2>&1 | \
            dialog --title "Update" \
            --no-collapse \
            --infobox "\nUpdating Node.\n \nPlease wait." 0 0

            make go-quai>/dev/null 2>&1 | \
            dialog --title "Update" \
            --no-collapse \
            --infobox "\nUpdating Node.\n \nPlease wait." 0 0
            
            dialog --title "Update" \
            --no-collapse \
            --msgbox "\nNode updated.\n \nPress OK to continue." 0 0

            # Update quai-manager
            cd $HOME/$MAIN_DIR/quai-manager 
            git pull>/dev/null 2>&1 | \
            dialog --title "Update" \
            --no-collapse \
            --infobox "\nUpdating Manager.\n \nPlease wait."  0 0
            
            make quai-manager>/dev/null 2>&1 | \
            dialog --title "Update" \
            --no-collapse \
            --infobox "\nUpdating Manager.\n \nPlease wait."  0 0
            
            dialog --title "Update" \
            --no-collapse \
            --msgbox "\nManager updated.\n \nPress OK to return to the menu." 0 0
        fi
        ;;
    5 )
        if ! $NODELOGS; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox "\nPlease start your node before viewing nodelogs." 0 0
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
    6 )
        if ! $MININGLOGS; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox "\nPlease start your manager before viewing manager logs." 0 0
        else
            # Print Miner Logs
            cd
            result=`tail -40 quainetwork/quai-manager/logs/quai-manager.log`
            dialog --cr-wrap --title "quainetwork/quai-manager/logs/quai-manager.log" --msgbox "\n$result" 30 90
        fi
      ;;
    7 )
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
            LOCATION=$(dialog --colors --menu "Which mining address would you like to edit?\n \n\Z1Note: Entering an incorrect address will either break your node or send rewards to another user.\Zn" 0 0 13 \
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
    8)
        if $ISMINING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease stop your node and manager to edit your config file." 0 0
        elif $ISRUNNING; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease stop your node and manager to edit your config file." 0 0
        else
            cd $HOME/quainetwork/go-quai
            LOCATION=$(dialog --colors --menu "Which config variable would you like to edit?\n \n\Z1Note: do not change these values without knowing what they do.\Zn" 0 0 13 \
                    1 "ENABLE_HTTP" \
                    2 "ENABLE_WS" \
                    3 "ENABLE_UNLOCK" \
                    4 "ENABLE_ARCHIVE" \
                    5 "NETWORK" \
                    6 "HTTP_ADDR" \
                    7 "WS_ADDR" \
                    8 "WS_API" \
                    9 "HTTP_API" \
                    10 "QUAI_MINING" \
                    11 "THREADS" 3>&1 1>&2 2>&3 3>&- )
                case $LOCATION in
                1)
                    ENABLE_HTTP=$(dialog --nocancel --inputbox "Input desired value for ENABLE_HTTP (true/false). " 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^ENABLE_HTTP *=.*/ENABLE_HTTP=$ENABLE_HTTP/" network.env | dialog --msgbox "ENABLE_HTTP set to $ENABLE_HTTP" 0 0
                    ;;
                2)
                    ENABLE_WS=$(dialog --nocancel --inputbox "Input desired value for ENABLE_WS (true/false). " 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^ENABLE_WS *=.*/ENABLE_WS=$ENABLE_WS/" network.env | dialog --msgbox "ENABLE_WS set to $ENABLE_WS" 0 0
                    ;;
                3)
                    ENABLE_UNLOCK=$(dialog --nocancel --inputbox "Input desired value for ENABLE_UNLOCK (true/false). " 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^ENABLE_UNLOCK *=.*/ENABLE_UNLOCK=$ENABLE_UNLOCK/" network.env | dialog --msgbox "ENABLE_UNLOCK set to $ENABLE_UNLOCK" 0 0
                    ;;
                4)
                    ENABLE_ARCHIVE=$(dialog --nocancel --inputbox "Input desired value for ENABLE_ARCHIVE (true/false). " 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^ENABLE_ARCHIVE *=.*/ENABLE_ARCHIVE=$ENABLE_ARCHIVE/" network.env | dialog --msgbox "ENABLE_ARCHIVE set to $ENABLE_ARCHIVE" 0 0
                    ;;
                5)
                    NETWORK=$(dialog --nocancel --inputbox "Input desired value for NETWORK. Options include colosseum (testnet), garden (devnet), and local." 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^NETWORK *=.*/NETWORK=$NETWORK/" network.env | dialog --msgbox "NETWORK set to $NETWORK" 0 0
                    ;;
                6)
                    HTTP_ADDR=$(dialog --nocancel --inputbox "Input desired value for HTTP_ADDR. Options include 0.0.0.0 and 127.0.0.1 (localhost)." 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^HTTP_ADDR *=.*/HTTP_ADDR=$HTTP_ADDR/" network.env | dialog --msgbox "HTTP_ADDR set to $HTTP_ADDR" 0 0
                    ;;
                7)
                    WS_ADDR=$(dialog --nocancel --inputbox "Input desired value for WS_ADDR. Options include 0.0.0.0 and 127.0.0.1 (localhost)." 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^WS_ADDR *=.*/WS_ADDR=$WS_ADDR/" network.env | dialog --msgbox "WS_ADDR set to $WS_ADDR" 0 0
                    ;;
                8)
                    WS_API=$(dialog --nocancel --inputbox "Input desired value for WS_API. Options include debug, net, quai, and txpool." 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^WS_API *=.*/WS_API=$WS_API/" network.env | dialog --msgbox "WS_API set to $WS_API" 0 0
                    ;;
                9)
                    HTTP_API=$(dialog --nocancel --inputbox "Input desired value for HTTP_API. Options include debug, net, quai, and txpool." 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^HTTP_API *=.*/HTTP_API=$HTTP_API/" network.env | dialog --msgbox "HTTP_API set to $HTTP_API" 0 0
                    ;;
                10)
                    QUAI_MINING=$(dialog --nocancel --inputbox "Input desired value for QUAI_MINING (true/false). " 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^QUAI_MINING *=.*/QUAI_MINING=$QUAI_MINING/" network.env | dialog --msgbox "QUAI_MINING set to $QUAI_MINING" 0 0
                    ;;
                11) 
                    THREADS=$(dialog --nocancel --inputbox "Input desired value for THREADS. Set this lower than the number of threads your machine has for best performance." 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^THREADS *=.*/THREADS=$THREADS/" network.env | dialog --msgbox "THREADS set to $THREADS" 0 0
                    ;;
                esac
                rm -rf network.env.save
        fi
    ;;
    9)
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
            dialog --colors --yesno "Are you sure you want to clear your database and logs?\n \n\Z1Warning: This will fully reset your node.\Zn" 0 0
            if [ $? -eq 0 ]; then
                cd $HOME/quainetwork/go-quai
                rm -rf nodelogs
                rm -rf ~/Library/Quai
                yes | ./build/bin/quai removedb
                cd $HOME/quainetwork/quai-manager
                rm -rf logs
                dialog --cr-wrap --msgbox "Database cleared. Nodelogs removed." 0 0
            fi 
        fi
    ;;
  esac
done