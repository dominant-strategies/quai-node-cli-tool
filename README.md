# quai-node-cli-tool

A simple, CLI interface for installing, building, and running Quai Network nodes and managers.

## Getting Started

###  Dependencies

* [Node and manager installation dependencies](https://docs.quai.network/develop/installation)
* MacOS or Linux
* Homebrew
* charmbracelet/gum (optional - will be installed if not present)

### Installation

``` 
git clone https://github.com/spruce-solutions/quai-node-cli-tool.git
```

## Executing Program

Open up terminal and navigate to the directory where you cloned the repo. To use the script, run the following command:

```
sh node-miner-manager.sh
```

A window will pop up that looks like this:
![Screenshot](/screenshots/Interface.png)

## Usage

For first time users, choose install. This will install the necessary dependencies and build the node and manager. Once the installation is complete, you can choose to run, update or stop the node or manager and check their logs.

The script must be run again everytime you want to use it. (i.e. once to install, once to run, once to stop, etc.)

## Acknowledgements

Special thanks to [dm-paull](https://github.com/dm-paull/guides/blob/main/quai/quai.sh) for his contribution to this script. 




