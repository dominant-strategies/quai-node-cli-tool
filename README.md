# quai-node-cli-tool

A simple, CLI interface for installing, configuring, and running your Quai Network node and manager.

## Getting Started

### Dependencies

- Quai Network node and manager [installation dependencies](https://docs.quai.network/develop/installation)
  - [GoLang](https://golang.org/doc/install)
  - [git](https://github.com/git-guides/install-git)
- MacOS or Linux
- [Homebrew](https://brew.sh/)
- [charmbracelet/gum](https://github.com/charmbracelet/gum) (optional - will be installed if not present)

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

![Screenshot](/screenshots/UpdatedScreenshot.png)

## Usage

For first time users, choose install. This will install the necessary dependencies and build the node and manager. Once the installation is complete, you can choose to run, update or stop the node or manager and check their logs.

## Acknowledgements

Special thanks to [dm-paull](https://github.com/dm-paull/guides/blob/main/quai/quai.sh) for his contribution to this script.
