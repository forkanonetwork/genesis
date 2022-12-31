[![en](https://img.shields.io/badge/lang-en-red.svg)](https://github.com/forkanonetwork/genesis/blob/main/README.md)
[![es](https://img.shields.io/badge/lang-es-yellow.svg)](https://github.com/forkanonetwork/genesis/blob/main/README.es-ES.md)

# Forkano node and staking pool operation + block producer node
## This repo includes
    - Genesis data from forkano network
    - Scripts to deploy and run a node and (optional) a stake pool


## Installation
### Dependencies/Requirements:
- docker installed
- Storage: 3 GB free for image and data
- RAM: 2 GB at least for proper running
- Internet connection
- Optional: 1 (ONE) port forwarding for incoming connections

###    Linux instructions


Clone this repository **and _be noticed!: this is experimental, only for educational purposes_**
```bash
git clone https://github.com/forkanonetwork/genesis.git
cd genesis
./00-init.sh
```

This could take some time, docker image (~2.5 GB) needs to be downloaded the first time!

If things go well _(means you're lucky)_ you'll see this kind of output:

`Chain extended, new tip: ba3e79a37d5c31a4db0ef8bbc122fe769d080f1bc77e7e7c66b3a89ccdfa0e70 at slot 11`

That's your node syncing with Forkano mainnet!

Now you must wait for this to finish in order to register a new stake pool. Refer to **gLiveView Section** in order to monitor your node and know when it finishes syncing.

#### In the meantime you can donate some BTC, USDT or ADA to this project! Check **Contributing section** for donation addresses!


## gLiveView


After you've donated some (or not, as you wish, _remember the educational purposes_) you can check the status of your node by opening a second terminal and then run

```bash
cd genesis
./02-gLiveView-forkano_node.sh
```
Hopefully, you will see the following panel:


![imagen](https://user-images.githubusercontent.com/1715667/207903021-916bae11-71fc-4faf-890d-f1a934a09a1b.png)

Once the **"Syncing"** reaches "100%" you'll be able to perform the next **optional** operations

## Registering your pool as a Block Producing Node
* * MANDATORY: you must forward a port directly to the machine running the docker container in order to receive incoming connections from other Forkano Nodes. If you don't allow access from the other nodes, you'll be able to operate normally but **you won't receive rewards for producing blocks!**
* Your node could receive delegators!
* Your node will earn rewards **in CAP (the Forkano main native asset)** for producing blocks!
* You will have to provide your node's forkano wallet address in order to receive initial funds from us, by filling <a href="https://forkano.net/en/registro-de-pool-de-staking/" target="_blank">THIS FORM (MANDATORY!)</a>
* You must keep an eye on your node ir order to assure propperly funtioning 
* You will need to rotate the KES keys (script is provided, don't worry)

But, how can I see my forkano wallet address?

You can quit gLiveView pressing 'q' key or open a new terminal

Then enter the Forkano container running the node
```bash
./03-join-forkano_node.sh
 - You will be inside the container running the node, then
cd ~
./forkano_init/scripts/01-pools/01-check-balance.sh
```
 
This script will show your pool address, and will check the current balance
Once you have funds in that address you can continue with next step

```bash
# (yes... you MUST edit POOL_ vars before running, lines ~52-58)
# You'll access MC Editor, find those lines and edit according to your needs
# Press F2 to save and F10 to exit when done
mcedit ./forkano_init/scripts/01-pools/02-register-new-pool.sh
# Now run
./forkano_init/scripts/01-pools/02-register-new-pool.sh 
```

If this script finishes with no error now you are able to run the pool by daemonizing the docker container

# Daemonizing your node
Kill/exit/end every docker container and run from inside the genesis dir
```bash
./01-run-forkano_node_daemon.sh
```

# Accessing your daemonized node
```bash
./03-join-forkano_node.sh
```

# Tailing logs
```bash
./02-tail-forkano_node.sh (this will tail logs from inside the daemonized container)
./02-tail-local.sh (this will tail logs from your local data directory)
```



Once your pool is registered, you can check the status by running `./forkano_init/scripts/01-pools/03-query-pool-details.sh` script inside the container image

And again, you can check KES status, Block producing status, and everything else with gLiveView!

## Contributing


**BTC Address**: bc1qe4wre8qwtav3krd3psxyk3cfpyyrmjhdu5p7jt

**USDT Address TRC-20 network**: TXPNLaLYNGd5TFkkDif9BY8PcMUeChqrY2

**ADA Address over Cardano Network**: addr1qxtdszvk7y5py6yu6yka27fsxpej5c33cu570fk6zg7tshwpkr4eltx90uad3gx4pr6s747vc94g26954lpk06swhcnsdqv0c9



## Securing your keys

It's up to you where/how do you keep your keys safe!

Your private keys could be stored in a cold environment and then deleted from your node

