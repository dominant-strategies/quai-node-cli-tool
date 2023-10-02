# quai-node-cli-tool

A simple, CLI interface for everything related to your Quai Network slice node and stratum proxy. Easily install, update, and manage both programs in a central location. This repo inclues the following script:

- `quai-admin.sh`: A CLI interface that offers baseline functionality to manager your quai slice node and stratum proxy.

This repository is a **experimental** and is made to simplify the interaction with your Quai Network node and stratum proxy. Please report any issues you encounter in our [discord](https://discord.gg/quai).

### Dependencies

- Quai Network node and proxy [installation dependencies](https://docs.quai.network/node/node-overview/run-a-node#install-dependencies)
- Your favorite Unix package manager (e.g. `apt`, `yum`, `brew`, etc.)
- [Dialog](https://invisible-island.net/dialog/#synopsis)

### Installation

- Clone this repository
- Install dependencies
- Install dialog using your favorite package manager
  - `sudo apt install dialog` (Ubuntu)
  - `sudo yum install dialog` (CentOS)
  - `brew install dialog` (MacOS)

## Executing Program

To run the script, open up a terminal window and navigate to the directory where you cloned the repo.
Run the following command to make the script executable:

```
chmod +x quai.sh
```

You may need to run `sudo chmod +x quai.sh` if you get a permission denied error. You'll only need to do this once.

Then run the following command to execute the script:

```
./quai.sh
```

The interface should look like this:

![quai.sh](./Screenshots/quaish.png)

## Usage

Upon running the script for the first time, it will prompt you to install the necessary dependencies and build the node and proxy. Once you've installed dependencies, the script will install and configure the node and proxy.

After the installation has completed, you can choose to run, update, view logs, clear the node db and logs, and directly edit the config file or mining addresses.

## Acknowledgements

Special thanks to [dm-paull](https://github.com/dm-paull) for his contribution to this script.
