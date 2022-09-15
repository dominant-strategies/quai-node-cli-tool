#!/bin/bash
brew install gum
clear

gum style --border normal --margin "1" --padding "1 2" --border-foreground "#ec4d37" "Hello, there! Welcome to your $(gum style --foreground "#ec4d37" 'Quai Node Manager')."
CHOICE=$(gum choose --cursor-prefix="[•] " --selected.foreground="#ec4d37" "Install" "Update" "Start Full Node" "Start Mining Node and Manager" "Stop" "Check Node logs" "Check Miner Logs")

case $CHOICE in
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
        echo "------> $(gum style --foreground "#ec4d37" 'your node and miner will be installed inside the $HOME directory.')\n"
        cd $HOME
        mkdir quainetwork
        cd quainetwork

        # clone go-quai on to your machine
        git clone https://github.com/spruce-solutions/go-quai
        clear
        echo "\n------> $(gum style --foreground "#ec4d37" 'go-quai installed')\n"

        # move into go-quai directory
        cd $HOME/quainetwork/go-quai

        # copies environment variables to your machine
        cp network.env.dist network.env

        # generates go-quai binary
        make go-quai
        clear
        echo "\n------> $(gum style --foreground "#ec4d37" 'go-quai binary generated')\n"

        # prompt user to input their mining addresses
        read -p 'Would you like to input your mining addresses? They are required to mine, but not to run a node. (y/n) ' yn
        case $yn in
            [Yy]* ) PRIME_COINBASE=$(gum input --placeholder "Enter Prime Address: ")
                    sed -i -e "s/^PRIME_COINBASE *=.*/PRIME_COINBASE = \"$address\"/" $HOME/quainetwork/go-quai/network.env                    

                    REGION_1_COINBASE=$(gum input --placeholder "Enter Region 1 Address: ")
                    sed -i -e "s/^REGION_1_COINBASE *=.*/REGION_1_COINBASE = \"$address\"/" $HOME/quainetwork/go-quai/network.env                

                    REGION_2_COINBASE=$(gum input --placeholder "Enter Region 2 Address: ")
                    sed -i -e "s/^REGION_2_COINBASE *=.*/REGION_2_COINBASE = \"$address\"/" $HOME/quainetwork/go-quai/network.env

                    REGION_3_COINBASE=$(gum input --placeholder "Enter Region 3 Address: ")
                    sed -i -e "s/^REGION_3_COINBASE *=.*/REGION_3_COINBASE = \"$address\"/" $HOME/quainetwork/go-quai/network.env

                    ZONE_1_1_COINBASE=$(gum input --placeholder "Enter Zone-1-1 Address: ")
                    sed -i -e "s/^ZONE_1_1_COINBASE *=.*/ZONE_1_1_COINBASE = \"$address\"/" $HOME/quainetwork/go-quai/network.env

                    ZONE_1_2_COINBASE=$(gum input --placeholder "Enter Zone-1-2 Address: ")
                    sed -i -e "s/^ZONE_1_2_COINBASE *=.*/ZONE_1_2_COINBASE = \"$address\"/" $HOME/quainetwork/go-quai/network.env

                    ZONE_1_3_COINBASE=$(gum input --placeholder "Enter Zone-1-3 Address: ")
                    sed -i -e "s/^ZONE_1_3_COINBASE *=.*/ZONE_1_3_COINBASE = \"$address\"/" $HOME/quainetwork/go-quai/network.env

                    ZONE_2_1_COINBASE=$(gum input --placeholder "Enter Zone-2-1 Address: ")
                    sed -i -e "s/^ZONE_2_1_COINBASE *=.*/ZONE_2_1_COINBASE = \"$address\"/" $HOME/quainetwork/go-quai/network.env

                    ZONE_2_2_COINBASE=$(gum input --placeholder "Enter Zone-2-2 Address: ")
                    sed -i -e "s/^ZONE_2_2_COINBASE *=.*/ZONE_2_2_COINBASE = \"$address\"/" $HOME/quainetwork/go-quai/network.env

                    ZONE_2_3_COINBASE=$(gum input --placeholder "Enter Zone-2-3 Address: ")
                    sed -i -e "s/^ZONE_2_3_COINBASE *=.*/ZONE_2_3_COINBASE = \"$address\"/" $HOME/quainetwork/go-quai/network.env

                    ZONE_3_1_COINBASE=$(gum input --placeholder "Enter Zone-3-1 Address: ")
                    sed -i -e "s/^ZONE_3_1_COINBASE *=.*/ZONE_3_1_COINBASE = \"$address\"/" $HOME/quainetwork/go-quai/network.env

                    ZONE_3_2_COINBASE=$(gum input --placeholder "Enter Zone-3-2 Address: ")
                    sed -i -e "s/^ZONE_3_2_COINBASE *=.*/ZONE_3_2_COINBASE = \"$address\"/" $HOME/quainetwork/go-quai/network.env

                    ZONE_3_3_COINBASE=$(gum input --placeholder "Enter Zone-3-3 Address: ")
                    sed -i -e "s/^ZONE_3_3_COINBASE *=.*/ZONE_3_3_COINBASE = \"$address\"/" $HOME/quainetwork/go-quai/network.env
                    echo "Mining addresses added to network.env successfully"
                    ;;
            [Nn]* ) ;;
            * ) echo "Please answer y or n.";;
        esac
        
        ######################## Install Quai Miner ########################

        # go to parent directory
        cd $HOME/quainetwork

        # clone quai-manager
        git clone https://github.com/spruce-solutions/quai-manager
        echo "\n------> $(gum style --foreground "#ec4d37" 'quai-manager installed')\n"

        # move into quai-manager directory
        cd $HOME/quainetwork/quai-manager

        # generate quai-manager binary
        make quai-manager
        echo "\n------> $(gum style --foreground "#ec4d37" 'quai-manager binary generated')\n"
    break
    ;;

    "Update")
        cd $HOME/quainetwork/go-quai
        git pull origin main
        make go-quai
        echo "\n------> $(gum style --foreground "#ec4d37" 'full node udpated!')\n"

        cd $HOME/quainetwork/quai-manager
        git pull origin main
        make quai-manager
        echo "\n------> $(gum style --foreground "#ec4d37" 'manager updated!')\n"
    break
    ;;

    "Start Full Node")
        echo "------> $(gum style --foreground "#ec4d37" 'starting full node...')\n"
        cd $HOME/quainetwork/go-quai
        make run-full-node
        tail -20 $HOME/quainetwork/go-quai/nodelogs/prime.log
    break
    ;;

    "Start Mining Node and Manager")
        # start running our full node that is primed for mining
        echo "------> $(gum style --foreground "#ec4d37" 'starting full node...')\n"
        cd $HOME/quainetwork/go-quai
        make run-full-mining

        # select region and zone for mining, start manager
        echo ""
        region=$(gum input --placeholder "What region would you like to mine? (1, 2, 3) ")
        zone=$(gum input --placeholder "What zone would you like to mine? (1, 2, 3) ")
        echo "\n------> $(gum style --foreground "#ec4d37" 'starting manager...')\n"
        cd $HOME/quainetwork/quai-manager
        make run-mine-background region=$region zone=$zone

        # tail the logs
        echo "\n------> $(gum style --foreground "#ec4d37" 'getting prime nodelogs snapshot:')\n"
        tail -20 $HOME/quainetwork/go-quai/nodelogs/prime.log
        echo "\n------> $(gum style --foreground "#ec4d37" ' getting manager logs snapshot:')\n"
        tail -20 $HOME/quainetwork/quai-manager/logs/quai-manager.log
    break
    ;;

    "Stop")
        ###### CHANGE: stop both node and miner, miner first node second ######
        cd $HOME/quainetwork/quai-manager
        make stop
        echo "\n------> $(gum style --foreground "#ec4d37" 'manager stopped.')\n"
        cd $HOME/quainetwork/go-quai
        make stop
        echo "\n------> $(gum style --foreground "#ec4d37" 'full node stopped.')\n"
    break
    ;;

    "Check Node logs")
        echo "$(gum style --foreground "#ec4d37" 'where would you like to view logs?')"
        LOGS_LOCATION=$(gum choose "Prime" "Region" "Zone")
        clear
            case $LOGS_LOCATION in 
                "Prime")
                    echo "\n------> $(gum style --foreground "#ec4d37" 'getting prime logs:')\n"
                    tail -f $HOME/quainetwork/go-quai/nodelogs/prime.log
                    break
                ;;

                "Region")
                    region=$(gum input --cursor.foreground="#ec4d37" --prompt "Which region? " --placeholder "1, 2, or 3")
                    echo "\n------> $(gum style --foreground "#ec4d37" 'getting region-'$region' logs:')\n"
                    tail -f $HOME/quainetwork/go-quai/nodelogs/region-$region.log
                    break
                ;;

                "Zone")
                    region=$(gum input --prompt "Which region? " --placeholder "1, 2, or 3")
                    zone=$(gum input --prompt "Which zone? " --placeholder "1, 2, or 3")
                    echo "\n------> $(gum style --foreground "#ec4d37" 'getting region-'$region' zone-'$zone' logs:')\n"
                    tail -f $HOME/quainetwork/go-quai/nodelogs/zone-$region-$zone.log
                    break
                ;;
            esac

    break
    ;;

    "Check Miner Logs")
        echo "\n------> $(gum style --foreground "#ec4d37" 'manager logs: ')\n"
        tail -f $HOME/quainetwork/quai-manager/logs/quai-manager.log
    break
    ;;
esac
