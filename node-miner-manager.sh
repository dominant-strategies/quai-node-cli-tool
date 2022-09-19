#!/bin/bash

which -s brew
if [[ $? != 0 ]] ; then
    # Install Homebrew
    echo "Installing Homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
    echo "Homebrew found. Checking for gum installation..."
fi
which -s gum
if [[ $? != 0 ]] ; then
    # Install Gum
    echo "Installing Gum..."
    brew install gum
else
    echo "Gum found. Starting up your node manager..."
fi
clear

ISRUNNING="False"
ISMINING="False"

while true; do 

    arr=("$HOME/quainetwork/go-quai" "$HOME/quainetwork/quai-manager")
    for i in "${arr[@]}"; do
        if [ -d "$i" ]; then
            INSTALLED="$(gum style --foreground="#5aab61" 'Installed ✔') "
            NEWUSER=false
        else
            INSTALLED=Install
            NEWUSER=true
        fi
    done

    if $ISRUNNING; then
        STARTFULLNODE="Full Node - $(gum style --foreground="#5aab61" 'Running ✔') "
        STARTMININGNODE="Full Node - $(gum style --foreground="#5aab61" 'Running ✔') "
    elif $ISMINING; then
        STARTFULLNODE="Mining Node - $(gum style --foreground="#5aab61" 'Running ✔') "
        STARTMININGNODE="Mining Node & Manager - $(gum style --foreground="#5aab61" 'Running ✔') "
    else
        STARTFULLNODE="Start Full Node"
        STARTMININGNODE="Start Mining Node and Manager"
    fi

    gum style --border double --margin "0 0" --padding "1 2" --border-foreground="#ec4d37" "Hello, there! Welcome to your $(gum style --foreground "#ec4d37" 'Quai Node Manager')."
    $NEWUSER && gum style --margin "1 0" --padding "1 0" --border-foreground="#ec4d37" "Select the $(gum style --foreground "#ec4d37" 'install option') to get started."
    CHOICE=$(gum choose --cursor="~"  "$INSTALLED" "Update" "$STARTFULLNODE" "$STARTMININGNODE" "Stop" "Check Node logs" "Check Miner Logs" "Quit")

    case $CHOICE in
        "$(gum style --foreground="#5aab61" 'Installed ✔') ")
            echo "\nYou've already installed your node and manager.\nSelect $(gum style --foreground "#ec4d37" 'update') to update your node and manager."
            sleep 3
            clear
        ;;
        "Full Node - $(gum style --foreground="#5aab61" 'Running ✔') ")
            echo "\nYour full node is already running.\nSelect $(gum style --foreground "#ec4d37" 'stop') to stop your node."
            sleep 3
            clear
        ;;
        "Mining Node - $(gum style --foreground="#5aab61" 'Running ✔') ")
            echo "\nYour mining node is already running.\nSelect $(gum style --foreground "#ec4d37" 'stop') to stop your node."
            sleep 3
            clear
        ;;
        "Mining Node & Manager - $(gum style --foreground="#5aab61" 'Running ✔') ")
            echo "\nYour mining node and manager are already running.\nSelect $(gum style --foreground "#ec4d37" 'stop') to stop your node."
            sleep 3
            clear
        ;;
        "Install")

            menu='./quai.sh'
            echo 'export menu='$menu >> $HOME/.bash_profile

            IP=$(wget -qO- eth0.me)
            echo 'export IP='$IP >> $HOME/.bash_profile
            source $HOME/.bash_profile

            ######################## Preparation ########################
            
            # navigate to home directory
            cd $HOME

            # dependency installation warning
            echo "\nThis script assumes that you have all of the required dependencies installed.\nThese include git, golang, and a number of terminal commands.\nIf you do not have them installed, please visit https://docs.quai.network/develop/installation for instructions on how to install them.\n"

            ######################## Install Quai Node ########################
            
            # tell the user where their node and miner will be installed
            cd $HOME
            MAIN_DIR=quainetwork
            if test -d "$MAIN_DIR"; then
                echo "------> $(gum style --foreground "#ec4d37" 'Quai Network directory ')already exists.\n"
            else
                echo "------> $(gum style --foreground "#ec4d37" 'your node and miner will be installed inside the $HOME/quainetwork directory.')\n"
                echo "------> $(gum style --foreground "#ec4d37" 'quainetwork directory ')created\n"
                mkdir quainetwork
            fi
            cd quainetwork

            # clone go-quai on to your machine
            NODE_DIR=go-quai
            if test -d "$NODE_DIR"; then
                echo "------> $(gum style --foreground "#ec4d37" 'go-quai already exists, ')skipping install.\n"
            else
                gum spin --spinner="line" --title="Installing go-quai..." --spinner.foreground "#ec4d37" git clone https://github.com/dominant-strategies/go-quai 
                echo "------> $(gum style --foreground "#ec4d37" 'go-quai ')installed\n"
                # move into go-quai directory
                cd $HOME/quainetwork/go-quai

                # copies environment variables to your machine
                cp network.env.dist network.env

                # generates go-quai binary
                gum spin --spinner="line" --title="Generating binaries" --spinner.foreground "#ec4d37" make go-quai
                echo "------> $(gum style --foreground "#ec4d37" 'go-quai binary ')generated\n"

                # prompt user to input their mining addresses
                read -p 'Would you like to input your mining addresses?
    They are required to mine, but not to run a node. (y/n) ' yn
                case $yn in
                    [Yy]* )
                            PRIME_COINBASE=$(gum input --placeholder "Enter Prime Address: ")
                            sed -i -e "s/^PRIME_COINBASE *=.*/PRIME_COINBASE = \"$PRIME_COINBASE\"/" network.env                    

                            REGION_1_COINBASE=$(gum input --placeholder "Enter Region 1 Address: ")
                            sed -i -e "s/^REGION_1_COINBASE *=.*/REGION_1_COINBASE = \"$REGION_1_COINBASE\"/" network.env                

                            REGION_2_COINBASE=$(gum input --placeholder "Enter Region 2 Address: ")
                            sed -i -e "s/^REGION_2_COINBASE *=.*/REGION_2_COINBASE = \"$REGION_2_COINBASE\"/" network.env

                            REGION_3_COINBASE=$(gum input --placeholder "Enter Region 3 Address: ")
                            sed -i -e "s/^REGION_3_COINBASE *=.*/REGION_3_COINBASE = \"$REGION_3_COINBASE\"/" network.env

                            ZONE_1_1_COINBASE=$(gum input --placeholder "Enter Zone-1-1 Address: ")
                            sed -i -e "s/^ZONE_1_1_COINBASE *=.*/ZONE_1_1_COINBASE = \"$ZONE_1_1_COINBASE\"/" network.env

                            ZONE_1_2_COINBASE=$(gum input --placeholder "Enter Zone-1-2 Address: ")
                            sed -i -e "s/^ZONE_1_2_COINBASE *=.*/ZONE_1_2_COINBASE = \"$ZONE_1_2_COINBASE\"/" network.env

                            ZONE_1_3_COINBASE=$(gum input --placeholder "Enter Zone-1-3 Address: ")
                            sed -i -e "s/^ZONE_1_3_COINBASE *=.*/ZONE_1_3_COINBASE = \"$ZONE_1_3_COINBASE\"/" network.env

                            ZONE_2_1_COINBASE=$(gum input --placeholder "Enter Zone-2-1 Address: ")
                            sed -i -e "s/^ZONE_2_1_COINBASE *=.*/ZONE_2_1_COINBASE = \"$ZONE_2_1_COINBASE\"/" network.env

                            ZONE_2_2_COINBASE=$(gum input --placeholder "Enter Zone-2-2 Address: ")
                            sed -i -e "s/^ZONE_2_2_COINBASE *=.*/ZONE_2_2_COINBASE = \"$ZONE_2_2_COINBASE\"/" network.env

                            ZONE_2_3_COINBASE=$(gum input --placeholder "Enter Zone-2-3 Address: ")
                            sed -i -e "s/^ZONE_2_3_COINBASE *=.*/ZONE_2_3_COINBASE = \"$ZONE_2_3_COINBASE\"/" network.env

                            ZONE_3_1_COINBASE=$(gum input --placeholder "Enter Zone-3-1 Address: ")
                            sed -i -e "s/^ZONE_3_1_COINBASE *=.*/ZONE_3_1_COINBASE = \"$ZONE_3_1_COINBASE\"/" network.env

                            ZONE_3_2_COINBASE=$(gum input --placeholder "Enter Zone-3-2 Address: ")
                            sed -i -e "s/^ZONE_3_2_COINBASE *=.*/ZONE_3_2_COINBASE = \"$ZONE_3_2_COINBASE\"/" network.env

                            ZONE_3_3_COINBASE=$(gum input --placeholder "Enter Zone-3-3 Address: ")
                            sed -i -e "s/^ZONE_3_3_COINBASE *=.*/ZONE_3_3_COINBASE = \"$ZONE_3_3_COINBASE\"/" network.env
                            echo "\n------> $(gum style --foreground "#ec4d37"  "Mining addresses added to network.env ")successfully\n"
                            ;;
                    [Nn]* ) echo ""    
                    ;;
                    * ) echo "Please answer y or n.";;
                esac
            fi

                    
            ######################## Install Quai Miner ########################
            # go to parent directory
            cd $HOME/quainetwork

            MANAGER_DIR=quai-manager
            if test -d "$MANAGER_DIR"; then
                echo "------> $(gum style --foreground "#ec4d37" 'quai-manager already exists, ')skipping install.\n"
            else
                # clone quai-manager
                gum spin --spinner="line" --title="Installing quai-manager..." --spinner.foreground "#ec4d37" git clone https://github.com/dominant-strategies/quai-manager 
                echo "------> $(gum style --foreground "#ec4d37" 'quai-manager ')installed\n"

                # move into quai-manager directory
                cd $HOME/quainetwork/quai-manager

                # generate quai-manager binary
                gum spin --spinner="line" --title="Generating binaries" --spinner.foreground "#ec4d37" make quai-manager
                echo "------> $(gum style --foreground "#ec4d37" 'quai-manager binary ')generated\n"
            fi
            echo "Do you want to exit the script?\n"
            EXIT_CHOICE="$(gum choose  "Yes" "No")"
            case $EXIT_CHOICE in
                "Yes" ) 
                        cd $HOME/quainetwork/quai-manager
                        gum spin --spinner="line" --title="stopping manager" --spinner.foreground "#ec4d37" make stop
                        echo "------> $(gum style --foreground "#ec4d37" 'manager ')stopped.\n"
                        cd $HOME/quainetwork/go-quai
                        gum spin --spinner="line" --title="stopping full node " --spinner.foreground "#ec4d37" make stop
                        echo "------> $(gum style --foreground "#ec4d37" 'full node ')stopped.\n"
                        gum spin --spinner="line" --title="Exiting session" --spinner.foreground "#ec4d37" sleep 2
                        clear
                        exit 0
                ;;
                "No" ) clear
                ;;
            esac
        ;;

        "Update")
            cd $HOME/quainetwork/go-quai
            gum spin --spinner="line" --title="Updating your node" --spinner.foreground "#ec4d37" git pull origin main
            gum spin --spinner="line" --title="Generating binaries" --spinner.foreground "#ec4d37" make go-quai
            echo "------> $(gum style --foreground "#ec4d37" 'full node ')udpated!\n"

            cd $HOME/quainetwork/quai-manager
            gum spin --spinner="line" --title="Generating binaries" --spinner.foreground "#ec4d37" git pull origin main
            gum spin --spinner="line" --title="Generating binaries" --spinner.foreground "#ec4d37" make quai-manager
            echo "------> $(gum style --foreground "#ec4d37" 'manager ')updated!\n"
            echo "Do you want to exit the script?\n"
            EXIT_CHOICE="$(gum choose  "Yes" "No")"
            case $EXIT_CHOICE in
                "Yes" ) 
                        cd $HOME/quainetwork/quai-manager
                        gum spin --spinner="line" --title="stopping manager" --spinner.foreground "#ec4d37" make stop
                        echo "------> $(gum style --foreground "#ec4d37" 'manager ')stopped.\n"
                        cd $HOME/quainetwork/go-quai
                        gum spin --spinner="line" --title="stopping full node " --spinner.foreground "#ec4d37" make stop
                        echo "------> $(gum style --foreground "#ec4d37" 'full node ')stopped.\n"
                        gum spin --spinner="line" --title="Exiting session" --spinner.foreground "#ec4d37" sleep 2
                        clear
                        exit 0
                ;;
                "No" ) clear
                ;;
            esac
        ;;

        "Start Full Node")
            echo "------> $(gum style --foreground "#ec4d37" 'starting full node...')\n"
            cd $HOME/quainetwork/go-quai
            make run-full-node
            gum spin --spinner="line" --title="Loading logs: " --spinner.foreground "#ec4d37" sleep 2
            echo "------> $(gum style --foreground "#ec4d37" 'prime ')logs:\n"
            tail -20 $HOME/quainetwork/go-quai/nodelogs/prime.log
            echo "\nDo you want to exit the script?\n"
            EXIT_CHOICE="$(gum choose  "Yes" "No")"
            case $EXIT_CHOICE in
                "Yes" ) 
                        cd $HOME/quainetwork/quai-manager
                        gum spin --spinner="line" --title="stopping manager" --spinner.foreground "#ec4d37" make stop
                        echo "------> $(gum style --foreground "#ec4d37" 'manager ')stopped.\n"
                        cd $HOME/quainetwork/go-quai
                        gum spin --spinner="line" --title="stopping full node " --spinner.foreground "#ec4d37" make stop
                        echo "------> $(gum style --foreground "#ec4d37" 'full node ')stopped.\n"
                        gum spin --spinner="line" --title="Exiting session" --spinner.foreground "#ec4d37" sleep 2
                        clear
                        exit 0
                ;;
                "No" ) clear
                ;;
            esac
            ISRUNNING="true"
        ;;

        "Start Mining Node and Manager")
            # start running our full node that is primed for mining
            cd $HOME/quainetwork/go-quai
            gum spin --spinner="line" --title="initializing node" --spinner.foreground "#ec4d37" make run-full-mining
            echo "------> $(gum style --foreground "#ec4d37" 'mining node ')started."

            # select region and zone for mining, start manager
            echo ""
            region=$(gum input --placeholder "What region would you like to mine? (1, 2, 3) ")
            zone=$(gum input --placeholder "What zone would you like to mine? (1, 2, 3) ")
            cd $HOME/quainetwork/quai-manager
            gum spin --spinner="line" --title="initializing manager" --spinner.foreground "#ec4d37" make run-mine-background region=$region zone=$zone
            echo "------> $(gum style --foreground "#ec4d37" 'manager ')started."

            # tail the logs
            echo "\n------> $(gum style --foreground "#ec4d37" 'prime node ')logs:\n"
            gum spin --spinner="line" --title="loading nodelogs: " --spinner.foreground "#ec4d37" sleep 2
            tail -20 $HOME/quainetwork/go-quai/nodelogs/prime.log
            echo "\n------> $(gum style --foreground "#ec4d37" 'manager ')logs\n"
            gum spin --spinner="line" --title="loading manager logs: " --spinner.foreground "#ec4d37" sleep 2
            tail -20 $HOME/quainetwork/quai-manager/logs/quai-manager.log
            echo "\nDo you want to exit the script?\n"
            EXIT_CHOICE="$(gum choose  "Yes" "No")"
            case $EXIT_CHOICE in
                "Yes" ) 
                        cd $HOME/quainetwork/quai-manager
                        gum spin --spinner="line" --title="stopping manager" --spinner.foreground "#ec4d37" make stop
                        echo "------> $(gum style --foreground "#ec4d37" 'manager ')stopped.\n"
                        cd $HOME/quainetwork/go-quai
                        gum spin --spinner="line" --title="stopping full node " --spinner.foreground "#ec4d37" make stop
                        echo "------> $(gum style --foreground "#ec4d37" 'full node ')stopped.\n"
                        gum spin --spinner="line" --title="Exiting session" --spinner.foreground "#ec4d37" sleep 2
                        clear
                        exit 0
                ;;
                "No" ) clear
                ;;
            esac
            ISRUNNING="false"
            ISMINING="true"
        ;;

        "Stop")
            ###### CHANGE: stop both node and miner, miner first node second ######
            cd $HOME/quainetwork/quai-manager
            gum spin --spinner="line" --title="stopping manager" --spinner.foreground "#ec4d37" make stop
            echo "------> $(gum style --foreground "#ec4d37" 'manager ')stopped.\n"
            cd $HOME/quainetwork/go-quai
            gum spin --spinner="line" --title="stopping full node " --spinner.foreground "#ec4d37" make stop
            echo "------> $(gum style --foreground "#ec4d37" 'full node ')stopped.\n"
            echo "Do you want to exit the script?\n"
            EXIT_CHOICE="$(gum choose  "Yes" "No")"
            case $EXIT_CHOICE in
                "Yes" ) 
                        cd $HOME/quainetwork/quai-manager
                        gum spin --spinner="line" --title="stopping manager" --spinner.foreground "#ec4d37" make stop
                        echo "------> $(gum style --foreground "#ec4d37" 'manager ')stopped.\n"
                        cd $HOME/quainetwork/go-quai
                        gum spin --spinner="line" --title="stopping full node " --spinner.foreground "#ec4d37" make stop
                        echo "------> $(gum style --foreground "#ec4d37" 'full node ')stopped.\n"
                        gum spin --spinner="line" --title="Exiting session" --spinner.foreground "#ec4d37" sleep 2
                        clear
                        exit 0
                ;;
                "No" ) clear
                ;;
            esac
            ISRUNNING="false"
            ISMINING="false"
        ;;

        "Check Node logs")
            echo "$(gum style --foreground "#ec4d37" 'where would you like to view logs?')"
            LOGS_LOCATION=$(gum choose "Prime" "Region" "Zone")
            clear
                case $LOGS_LOCATION in 
                    "Prime")
                        echo "\n------> $(gum style --foreground "#ec4d37" 'prime ')logs:\n"
                        gum spin --spinner="line" --title="loading logs: " --spinner.foreground "#ec4d37" sleep 2
                        tail 30 $HOME/quainetwork/go-quai/nodelogs/prime.log
                    ;;

                    "Region")
                        region=$(gum input --cursor.foreground="#ec4d37" --prompt "Which region? " --placeholder "1, 2, or 3")
                        echo "\n------> $(gum style --foreground "#ec4d37" 'region-'$region' ')logs:\n"
                        gum spin --spinner="line" --title="loading logs: " --spinner.foreground "#ec4d37" sleep 2
                        tail 30 $HOME/quainetwork/go-quai/nodelogs/region-$region.log
                    ;;

                    "Zone")
                        region=$(gum input --prompt "Which region? " --placeholder "1, 2, or 3")
                        zone=$(gum input --prompt "Which zone? " --placeholder "1, 2, or 3")
                        echo "\n------> $(gum style --foreground "#ec4d37" 'region-'$region' zone-'$zone' logs:')\n"
                        gum spin --spinner="line" --title="loading logs: " --spinner.foreground "#ec4d37" sleep 2
                        tail 30 $HOME/quainetwork/go-quai/nodelogs/zone-$region-$zone.log
                    ;;
                esac
            echo "\nDo you want to exit the script?\n"
            EXIT_CHOICE="$(gum choose  "Yes" "No")"
            case $EXIT_CHOICE in
                "Yes" ) 
                        cd $HOME/quainetwork/quai-manager
                        gum spin --spinner="line" --title="stopping manager" --spinner.foreground "#ec4d37" make stop
                        echo "------> $(gum style --foreground "#ec4d37" 'manager ')stopped.\n"
                        cd $HOME/quainetwork/go-quai
                        gum spin --spinner="line" --title="stopping full node " --spinner.foreground "#ec4d37" make stop
                        echo "------> $(gum style --foreground "#ec4d37" 'full node ')stopped.\n"
                        gum spin --spinner="line" --title="Exiting session" --spinner.foreground "#ec4d37" sleep 2
                        clear
                        exit 0
                ;;
                "No" ) clear
                ;;
            esac
        ;;
        "Check Miner Logs")
            echo "\n------> $(gum style --foreground "#ec4d37" 'manager ')logs:\n"
            gum spin --spinner="line" --title="loading logs: " --spinner.foreground "#ec4d37" sleep 2
            tail 30 $HOME/quainetwork/quai-manager/logs/quai-manager.log
            echo "\nDo you want to exit the script?\n"
            EXIT_CHOICE="$(gum choose  "Yes" "No")"
            case $EXIT_CHOICE in
                "Yes" ) 
                        cd $HOME/quainetwork/quai-manager
                        gum spin --spinner="line" --title="stopping manager" --spinner.foreground "#ec4d37" make stop
                        echo "------> $(gum style --foreground "#ec4d37" 'manager ')stopped.\n"
                        cd $HOME/quainetwork/go-quai
                        gum spin --spinner="line" --title="stopping full node " --spinner.foreground "#ec4d37" make stop
                        echo "------> $(gum style --foreground "#ec4d37" 'full node ')stopped.\n"
                        gum spin --spinner="line" --title="Exiting session" --spinner.foreground "#ec4d37" sleep 2
                        clear
                        exit 0
                ;;
                "No" ) clear
                ;;
            esac
        ;;
        "Quit")
            gum spin --spinner="line" --title="Exiting session" --spinner.foreground "#ec4d37" sleep 2
            clear
            exit 0
        ;;
    esac
done