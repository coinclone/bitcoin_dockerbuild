#!/usr/bin/env bash

# Set veriables
source bitcoin/coin_vars.sh

# Generate key pairs and convert to hex format
mkdir $HOME/key_files/
cd $HOME/key_files/
openssl ecparam -genkey -name secp256k1 -out alertkey.pem
openssl ec -in alertkey.pem -text > alertkey.hex
openssl ecparam -genkey -name secp256k1 -out testnetalert.pem
openssl ec -in testnetalert.pem -text > testnetalert.hex
openssl ecparam -genkey -name secp256k1 -out genesiscoinbase.pem
openssl ec -in testnetalert.pem -text > genesiscoinbase.hex
wait

# Update timestamps
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$DATA_TIMESTAMP/$NEW_DATA_TIMESTAMP/g"
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$DATATESTNET_TIMESTAMP/$NEW_DATATESTNET_TIMESTAMP/g"
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$MAIN_GENESIS_NTIME/$NEW_DATA_TIMESTAMP/g"
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$TEST_GENESIS_NTIME/$NEW_DATATESTNET_TIMESTAMP/g"

# Update alert keys
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$MAIN_VALERTPUBKEY/$(python $HOME/get_pub_key.py $HOME/key_files/alertkey.hex)/g"
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$TEST_VALERTPUBKEY/$(python $HOME/get_pub_key.py $HOME/key_files/testnetalert.hex)/g"

# Update script pub key
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$SCRIPT_PUB_KEY/$(python $HOME/get_pub_key.py $HOME/key_files/genesiscoinbase.hex)/g"

# Update magic bytes
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/pchMessageStart\[0\] =/pchMessageStart\[0\] = 0x$(printf "%x\n" $(shuf -i 0-255 -n 1)); \/\//g"
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/pchMessageStart\[1\] =/pchMessageStart\[1\] = 0x$(printf "%x\n" $(shuf -i 0-255 -n 1)); \/\//g"
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/pchMessageStart\[2\] =/pchMessageStart\[2\] = 0x$(printf "%x\n" $(shuf -i 0-255 -n 1)); \/\//g"
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/pchMessageStart\[3\] =/pchMessageStart\[3\] = 0x$(printf "%x\n" $(shuf -i 0-255 -n 1)); \/\//g"

# Compile
cd $HOME/bitcoin
make

# Mine mainnet genesis block
mkdir $HOME/mined_blocks
cd $HOME/bitcoin/src
clear

cat <<EOF
--------
Mining mainnet genesis block.
Began mining $(date)

This could take up to four hours, perhaps even longer depending on your hardware.
--------
EOF

./bitcoind > $HOME/mined_blocks/mainnet_info.txt
wait

# Update mainnet genesis block paramiters
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$MAINNET_MERKLE_ROOT/$(grep 'new mainnet genesis merkle root:' $HOME/mined_blocks/mainnet_info.txt | cut -f 2 -d ':' | xargs)/g"
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$MAINNET_NONCE/$(grep 'new mainnet genesis nonce:' $HOME/mined_blocks/mainnet_info.txt | cut -f 2 -d ':' | xargs)/g"
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$MAINNET_GENESIS_HASH/$(grep 'new mainnet genesis hash:' $HOME/mined_blocks/mainnet_info.txt | cut -f 2 -d ':' | xargs)/g"

# Initialize hashGenesisBlock value for mainnet
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "0,/hashGenesisBlock = uint256(\"0x01\")/{s/hashGenesisBlock = uint256(\"0x01\")/hashGenesisBlock = uint256(\"0x$(grep 'new mainnet genesis hash:' $HOME/mined_blocks/mainnet_info.txt | cut -f 2 -d ':' | xargs)\")/}"

# Switch off the mainnet genesis mining function
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "0,/if (true/{s/if (true/if (false/}"

# Compile again
cd $HOME/bitcoin
make

# Mine testnet genesis block
cd $HOME/bitcoin/src
clear

cat <<EOF
--------
Mining testnet genesis block.
Began mining $(date)

This could take up to four hours, perhaps even longer depending on your hardware.
--------
EOF

./bitcoind > $HOME/mined_blocks/testnet_info.txt
wait

# Update testnet genesis block paramiters
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$TESTNET_NONCE/$(grep 'new testnet genesis nonce:' $HOME/mined_blocks/testnet_info.txt | cut -f 2 -d ':' | xargs)/g"
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$TESTNET_GENESIS_HASH/$(grep 'new testnet genesis hash:' $HOME/mined_blocks/testnet_info.txt | cut -f 2 -d ':' | xargs)/g"

# Initialize hashGenesisBlock value for testnet
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "0,/hashGenesisBlock = uint256(\"0x01\")/{s/hashGenesisBlock = uint256(\"0x01\")/hashGenesisBlock = uint256(\"0x$(grep 'new testnet genesis hash:' $HOME/mined_blocks/testnet_info.txt | cut -f 2 -d ':' | xargs)\")/}"

# Switch off the testnet genesis mining function
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "0,/if (true/{s/if (true/if (false/}"

# Compile for a third time
cd $HOME/bitcoin
make

# Mine regtestnet genesis block
cd $HOME/bitcoin/src
clear

cat <<EOF
--------
Mining regtestnet genesis block.
Began mining $(date)

This could take up to four hours, perhaps even longer depending on your hardware.
--------
EOF

./bitcoind > $HOME/mined_blocks/regtestnet_info.txt
wait

# Update regtestnet genesis block paramiters
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/genesis.nNonce = 2/genesis.nNonce = $(grep 'new regtestnet genesis nonce:' $HOME/mined_blocks/regtestnet_info.txt | cut -f 2 -d ':' | xargs)/g"
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$REGTESTNET_GENESIS_HASH/$(grep 'new regtestnet genesis hash:' $HOME/mined_blocks/regtestnet_info.txt | cut -f 2 -d ':' | xargs)/g"

# Initialize hashGenesisBlock value for regtestnet
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "0,/hashGenesisBlock = uint256(\"0x01\")/{s/hashGenesisBlock = uint256(\"0x01\")/hashGenesisBlock = uint256(\"0x$(grep 'new regtestnet genesis hash:' $HOME/mined_blocks/regtestnet_info.txt | cut -f 2 -d ':' | xargs)\")/}"

# Switch off the regtestnet genesis mining function
find $HOME/bitcoin/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "0,/if (true/{s/if (true/if (false/}"

# Final compile
cd $HOME/bitcoin
make

# Closing statement
clear
cat <<EOF
--------
Your new clone is ready to go.

Next steps,
Commit your new clone, be sure to save it as 'coinclone/bitcoin:node'.
In this example the container was named 'seed':

    docker commit seed coinclone/bitcoin:node && \
    docker rm seed

If you haven't already, clone the coinclone/cloner git repo:

    git clone https://github.com/coinclone/cloner.git

Move into 'cloner/deploy', edit the 'cloner/deploy/config/coin.conf' file to your specifications and build any class of container you want (miner, non-miner).

    cd cloner/deploy

    #vi config/coin.conf
    bash setup.sh <blockchain> <node_class> <number_of_instances>

Run at least two instances to establish a network. You may deploy as many instances as you wish.

    bash setup.sh bitcoin miner 1 && \
    sed -i 's/gen=1/gen=0/' config/coin.conf && \
    bash setup.sh bitcoin relay 1

Enjoy!
--------
EOF
