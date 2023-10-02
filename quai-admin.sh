#!/bin/bash

DIALOG_CANCEL=1
DIALOG_ESC=255
STYLECONFIG=~/.dialogrc
MAIN_DIR="quainetwork"
NODE_PROCESS="go-quai"
PROXY_PROCESS="quai-stratum"

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
if [[ -d "$HOME/$MAIN_DIR/go-quai" && -d "$HOME/$MAIN_DIR/go-quai-stratum" ]]; then
    :
else
    # Check if user has configured wallet addresses
    dialog --title "Installation" --yesno "\nHave you configured 13 Quai addresses? \nYou'll need them to run a node and mine." 0 0
    response=$?
    case $response in
        0)  : ;;
        1)
            # Inform user to configure addresses
            dialog --title "Installation" --colors --msgbox "\nPlease configure your wallet addresses before continuing.\n \nYou can set up addresses using Pelagus Wallet: \Z1https://pelaguswallet.io\Zn \n \nPress okay to exit." 0 0
            exit
            ;;
        255)
            exit
            ;;
    esac

    # Check if user wants to install
    NODE_LATEST_TAG=$(curl -s "https://api.github.com/repos/dominant-strategies/go-quai/tags" | jq -r '.[0].name')
    PROXY_LATEST_TAG=$(curl -s "https://api.github.com/repos/dominant-strategies/go-quai-stratum/tags" | jq -r '.[0].name')
    dialog --title "Installation" --colors --yesno "\nThis will install the most current releases of go-quai \Z1($NODE_LATEST_TAG)\Zn and go-quai-stratum \Z1($PROXY_LATEST_TAG)\Zn in the home directory.\n \nContinue?" 0 0
    response=$?
    case $response in
        0) 
            # Create directory
            cd $HOME
            if [[ -d "$MAIN_DIR" ]]; then
                :
            else
                mkdir $MAIN_DIR
            fi
            # Clone into go-quai
            cd $MAIN_DIR
            git clone https://github.com/dominant-strategies/go-quai>/dev/null 2>&1
            cd $HOME/$MAIN_DIR/go-quai
            git checkout $NODE_LATEST_TAG >/dev/null 2>&1 | \
            dialog --title "Installation" \
            --no-collapse \
            --infobox "\nInstalling go-quai.\n"  7 28

            #Configure go-quai
            cp network.env.dist network.env
            make go-quai>/dev/null 2>&1 | 
            dialog --title "Installation" \
            --no-collapse \
            --infobox "\nGenerating binaries.\n" 7 28

            #Inform user node is configured
            dialog --title "Installation" \
            --no-collapse \
            --msgbox "\nNode installed and configured.\n \nPress OK to continue." 0 0

            # Clone into go-quai-stratum
            cd $HOME/$MAIN_DIR
            git clone https://github.com/dominant-strategies/go-quai-stratum>/dev/null 2>&1
            cd $HOME/$MAIN_DIR/go-quai-stratum
            git checkout $PROXY_LATEST_TAG >/dev/null 2>&1 | \
            dialog --title "Installation" \
            --no-collapse \
            --infobox "\nInstalling Stratum Proxy.\n"  7 28

            #Configure go-quai-stratum
            cp config/config.example.json config/config.json
            make quai-stratum>/dev/null 2>&1 | \
            dialog --title "Installation" 
            --no-collapse \
            --infobox "\nGenerating binaries.\n" 7 28

            #Inform user stratum proxy is configured
            dialog --title "Installation" \
            --no-collapse \
            --msgbox "\nStratum proxy installed and configured.\n \nInstallation complete.\n \nPress OK to continue." 0 0
            ;;
        1) 
            clear
            echo "Installation cancelled."
            exit ;;
        255)
            clear 
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

    # Check if node is running
    if pgrep -x "$NODE_PROCESS">/dev/null 2>&1; then
        ISRUNNING="True"
        STARTFULLNODE="Stop Node - \Z2Running\Zn"
    else
        ISRUNNING="False"
        STARTFULLNODE="Start Node - \Z1Stopped\Zn"
    fi

    # Check if proxy is running
    if pgrep -x "$PROXY_PROCESS">/dev/null 2>&1; then
        ISPROXYRUNNING="True"
        STARTPROXY="Stop Proxy - \Z2Running\Zn"
    else
        ISPROXYRUNNING="False"
        STARTPROXY="Start Proxy - \Z1Stopped\Zn"
    fi

  exec 3>&1
  selection=$(dialog \
    --backtitle "Quai Hardware Manager" \
    --clear \
    --colors \
    --cancel-label "EXIT" \
    --menu "Select an Option:" 17 50 10 \
    "1" "$STARTFULLNODE" \
    "2" "$STARTPROXY" \
    "3" "Update Node & Proxy" \
    "4" "Node Logs" \
    "5" "Edit Mining Addresses" \
    "6" "Edit Config Variables" \
    "7" "Clear logs & db" \
    2>&1 1>&3)
  exit_status=$?
  exec 3>&-
  case $exit_status in
    $DIALOG_CANCEL)
      # Verify the user wants to stop their node and proxy
      dialog --title "Alert" --colors --yesno "\nExit the Quai Hardware Manager?\n \n\Z1This will stop your node and proxy.\Zn" 0 0
      response=$?
      EXIT="False"
      case $response in
          0) EXIT="True";;
          1) EXIT="False";;
          255) EXIT="False";;
      esac
      if [ $EXIT = "True" ]; then
          #If user chooses stop, kill node
          cd $HOME/quainetwork/go-quai
          pkill -9 quai-stratum 1>&- 2>&- && \
          make stop>/dev/null 2>&1 | \
          dialog --title "Stop" \
          --no-collapse \
          --infobox "\nStopping Node and Proxy.\n \nPlease wait."  0 0
          clear
        echo "Quai Hardware Manager stopped."
        exit
      fi
      ;;
    $DIALOG_ESC)
      # Verify the user wants to stop their node and proxy
      dialog --title "Alert" --yesno "\nExit the Quai Hardware Manager?\n \n\Z1This will stop your node and proxy.\Zn" 0 0
      response=$?
      EXIT="False"
      case $response in
          0) EXIT="True";;
          1) EXIT="False";;
          255) EXIT="False";;
      esac
      if [ $EXIT = "True" ]; then
          #If user chooses stop, kill node
          cd $HOME/quainetwork/go-quai
          pkill -9 quai-stratum 1>&- 2>&- && \
          make stop>/dev/null 2>&1 | \
          dialog --title "Stop" \
          --no-collapse \
          --infobox "\nStopping Node and Proxy.\n \nPlease wait."  0 0
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
            dialog --title "Alert" --colors --yesno "\n\Z1Are you sure you want to stop your node?\Zn" 0 0
            response=$?
            STOP="False"
            case $response in
                0) STOP="True";;
                1) STOP="False";;
                255) STOP="False";;
            esac
            if [ $STOP = "True" ]; then
                #If user chooses stop, kill node
                cd $HOME/$MAIN_DIR/go-quai
                make stop >/dev/null 2>&1 | \
                dialog --title "Stop" \
                --no-collapse \
                --infobox "\nStopping Node.\n \nPlease wait."  0 0
                dialog --title "Stop" \
                --no-cancel \
                --msgbox "\nNode stopped.\n \nPress OK to return to the menu." 0 0
            fi
        else
            # Slice selection
            NODEREGION=$(dialog --nocancel --menu "Which region would you like to run your node?\n \nIf you'd like to run a global node, you'll have to manually configure it the network.env." 0 0 3 \
                1 "Region-1" \
                2 "Region-2" \
                3 "Region-3" 3>&1 1>&2 2>&3 3>&- )
            NODEZONE=$(dialog --nocancel --menu "Which zone would you like to run your node?" 0 0 3 \
                1 "Zone-1" \
                2 "Zone-2" \
                3 "Zone-3" 3>&1 1>&2 2>&3 3>&- )

            NODEREGION=$(($NODEREGION-1))
            NODEZONE=$(($NODEZONE-1))
            
            cd $HOME/$MAIN_DIR/go-quai && sed -i.save "s/^SLICES *=.*/SLICES='[$NODEREGION $NODEZONE]'/" network.env | \ 
            dialog --title "Alert" \
            --no-collapse \
            --infobox "\n Slice set to [$NODEREGION $NODEZONE].\n \nPlease wait." 0 0
            rm -rf network.env.save
           
            # Start go-quai
            make run >/dev/null 2>&1 | \
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
                    LOCATION=$(dialog --nocancel --menu "In which location would you like to view nodelogs? \nLogs will only populate in the location your slice is running." 0 0 13 \
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
        #If proxy is running, redirect back to menu
        if [ $ISPROXYRUNNING = "True" ]; then
            dialog --title "Alert" --colors --yesno "\n\Z1Are you sure you want to stop the Proxy?\Zn" 0 0
            response=$?
            STOP="False"
            case $response in
                0) STOP="True";;
                1) STOP="False";;
                255) STOP="False";;
            esac
            if [ $STOP = "True" ]; then
                #If user chooses stop, kill node
                pkill -9 quai-stratum &>/dev/null | \
                dialog --title "Stop" \
                --no-collapse \
                --infobox "\nStopping Proxy.\n \nPlease wait."  0 0
                dialog --title "Stop" \
                --no-cancel \
                --msgbox "\nProxy stopped.\n \nPress OK to return to the menu." 0 0
            fi
        elif [ $ISRUNNING = "False" ]; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease start your Node before starting the Proxy." 0 0
        else
            ZONE=$(($NODEZONE+1))
            REGION=$(($NODEREGION+1))
            case $REGION in
                1)
                    REGION_PORT=8579
                    REGION_NAME="Cyprus"
                    case $ZONE in
                        1)
                            ZONE_PORT=8611
                            ZONE_NAME="Cyprus-1"
                            ;;
                        2)
                            ZONE_PORT=8643
                            ZONE_NAME="Cyprus-2"
                            ;;
                        3)
                            ZONE_PORT=8675
                            ZONE_NAME="Cyprus-3"
                            ;;
                    esac
                    ;;
                2)
                    REGION_PORT=8581
                    REGION_NAME="Paxos"
                    case $ZONE in
                        1)
                            ZONE_PORT=8613
                            ZONE_NAME="Paxos-1"
                            ;;
                        2)
                            ZONE_PORT=8645
                            ZONE_NAME="Paxos-2"
                            ;;
                        3)
                            ZONE_PORT=8677
                            ZONE_NAME="Paxos-3"
                            ;;
                    esac
                    ;;
                3)
                    REGION_PORT=8583
                    REGION_NAME="Hydra"
                    case $ZONE in
                        1)
                            ZONE_PORT=8615
                            ZONE_NAME="Hydra-1"
                            ;;
                        2)
                            ZONE_PORT=8647
                            ZONE_NAME="Hydra-2"
                            ;;
                        3)
                            ZONE_PORT=8679
                            ZONE_NAME="Hydra-3"
                            ;;
                    esac
                    ;;
            esac
            # Start proxy
            dialog --title "Stratum Proxy" \
            --no-collapse \
            --colors \
            --msgbox "\nSlice node running region: \Z1$REGION_NAME\Zn and zone: \Z1$ZONE_NAME\Zn [$NODEREGION $NODEZONE].\n \nThe proxy will start in same location with websocket ports \Z1$REGION_PORT\Zn and \Z1$ZONE_PORT\Zn.\n \nPress okay to continue." 0 0
            cd $HOME/quainetwork/go-quai-stratum && nohup ./build/bin/quai-stratum --region=$REGION_PORT --zone=$ZONE_PORT & >/dev/null 2>&1 | \
            dialog --title "Stratum Proxy" \
            --no-collapse \
            --colors \
            --infobox "\nStarting Proxy.\n \nPlease wait." 0 0
            dialog --title "Stratum Proxy" \
            --no-collapse \
            --msgbox "\nProxy started.\n \nPress OK to return to the menu." 0 0
        fi
      ;;
    3 )
        # Update go-quai and go-quai stratum
        if [ $ISPROXYRUNNING = "True" ]; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease stop your node and proxy to update." 0 0
        elif [ $ISRUNNING = "True" ]; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease stop your node and proxy to update." 0 0
        else
            dialog --title "Update" \
            --no-collapse \
            --msgbox "\nThis will update go-quai and go-quai-stratum to the latest release.\n \nPress OK to continue." 0 0

            cd $HOME/$MAIN_DIR/go-quai
            git fetch --all >/dev/null 2>&1
            NODE_LATEST_TAG=$(curl -s "https://api.github.com/repos/dominant-strategies/go-quai/tags" | jq -r '.[0].name')
            git checkout $NODE_LATEST_TAG >/dev/null 2>&1 | \
            dialog --title "Update" \
            --no-collapse \
            --infobox "\nUpdating Node.\n \nPlease wait." 0 0

            make go-quai>/dev/null 2>&1 | \
            dialog --title "Update" \
            --no-collapse \
            --infobox "\nUpdating Node.\n \nPlease wait." 0 0
            
            dialog --title "Update" \
            --no-collapse \
            --msgbox "\nNode updated. (Release $NODE_LATEST_TAG).\n \nPress OK to continue." 0 0

            # Update go-quai-stratum
            cd $HOME/$MAIN_DIR/go-quai-stratum
            git fetch --all >/dev/null 2>&1
            PROXY_LATEST_TAG=$(curl -s "https://api.github.com/repos/dominant-strategies/go-quai-stratum/tags" | jq -r '.[0].name')
            git checkout $PROXY_LATEST_TAG>/dev/null 2>&1 | \
            dialog --title "Update" \
            --no-collapse \
            --infobox "\nUpdating Proxy.\n \nPlease wait."  0 0
            
            make quai-stratum>/dev/null 2>&1 | \
            dialog --title "Update" \
            --no-collapse \
            --infobox "\nUpdating Proxy.\n \nPlease wait."  0 0
            
            dialog --title "Update" \
            --no-collapse \
            --msgbox "\nProxy updated. (Release $PROXY_LATEST_TAG).\n \nPress OK to return to the menu." 0 0
        fi
        ;;
    4 )
        if [ $NODELOGS = "False" ]; then
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
    5 )
        # Edit coinbase addresses in network.env
        if [ $ISPROXYRUNNING = "True" ]; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease stop your node and proxy to edit mining addresses." 0 0
        elif [ $ISRUNNING = "True" ]; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease stop your node and proxy to edit mining addresses." 0 0
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
    6 )
        if [ $ISPROXYRUNNING = "True" ]; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease stop your node and proxy to edit your config file." 0 0
        elif [ $ISRUNNING = "True" ]; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease stop your node and proxy to edit your config file." 0 0
        else
            cd $HOME/quainetwork/go-quai
            CHOICE=$(dialog --colors --menu "Which config variable would you like to edit?\n \n\Z1Note: do not change these values without knowing what they do.\Zn" 0 0 7 \
                    1 "NONCE" \
                    2 "NETWORK" \
                    3 "VERBOSITY" \
                    4 "ENABLE_ARCHIVE" \
                    5 "RUN_BLAKE3" \
                    6 "WS_API" \
                    7 "HTTP_API" 3>&1 1>&2 2>&3 3>&- )
                case $CHOICE in
                1)
                    NONCE=$(dialog --nocancel --inputbox "Input desired value for NONCE. " 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^NONCE *=.*/NONCE=$NONCE/" network.env | dialog --msgbox "NONCE set to $NONCE" 0 0
                    ;;
                2)
                    NETWORK=$(dialog --nocancel --inputbox "Input desired value for NETWORK. Options include colosseum (testnet), garden (devnet), and local." 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^NETWORK *=.*/NETWORK=$NETWORK/" network.env | dialog --msgbox "NETWORK set to $NETWORK" 0 0
                    ;;
                3)
                    VERBOSITY=$(dialog --nocancel --inputbox "Input desired value for VERBOSITY. Options include 0, 1, 2, 3, 4, 5, and 6." 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^VERBOSITY *=.*/VERBOSITY=$VERBOSITY/" network.env | dialog --msgbox "VERBOSITY set to $VERBOSITY" 0 0
                    ;;
                4)
                    ENABLE_ARCHIVE=$(dialog --nocancel --inputbox "Input desired value for ENABLE_ARCHIVE (true/false). " 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^ENABLE_ARCHIVE *=.*/ENABLE_ARCHIVE=$ENABLE_ARCHIVE/" network.env | dialog --msgbox "ENABLE_ARCHIVE set to $ENABLE_ARCHIVE" 0 0
                    ;;
                5)
                    RUN_BLAKE3=$(dialog --nocancel --inputbox "Input desired value for RUN_BLAKE3 (true/false). Note, this feature should only be enabled for local testing. " 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^RUN_BLAKE3 *=.*/RUN_BLAKE3=$RUN_BLAKE3/" network.env | dialog --msgbox "RUN_BLAKE3 set to $RUN_BLAKE3" 0 0
                    ;;
                6)
                    WS_API=$(dialog --nocancel --inputbox "Input desired value for WS_API. Options include debug, net, quai, and txpool." 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^WS_API *=.*/WS_API=$WS_API/" network.env | dialog --msgbox "WS_API set to $WS_API" 0 0
                    ;;
                7)
                    HTTP_API=$(dialog --nocancel --inputbox "Input desired value for HTTP_API. Options include debug, net, quai, and txpool." 0 0 3>&1 1>&2 2>&3 3>&-)
                    sed -i.save "s/^HTTP_API *=.*/HTTP_API=$HTTP_API/" network.env | dialog --msgbox "HTTP_API set to $HTTP_API" 0 0
                    ;;
                esac
                rm -rf network.env.save
        fi
    ;;
    7 )
        # Clear db
        if [ $ISPROXYRUNNING = "True" ]; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease stop your node and proxy to perform a full reset." 0 0
        elif [ $ISRUNNING = "True" ]; then
            dialog --title "Alert" \
            --no-collapse \
            --msgbox  "\nPlease stop your node and proxy to perform a full reset." 0 0
        else
            dialog --colors --yesno "Are you sure you want to clear your database and logs?\n \n\Z1Warning: This will fully reset your node.\Zn" 0 0
            if [ $? -eq 0 ]; then
                cd $HOME/quainetwork/go-quai
                rm -rf nodelogs ~/Library/Quai ~/.quai
                dialog --cr-wrap --msgbox "Database cleared. Node database and logs cleared." 0 0
            fi 
        fi
    ;;
  esac
done