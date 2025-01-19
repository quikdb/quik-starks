## quik-starks

This application was initiated with `scarb new <project name>` command

- Steps to deploy the contract class.
1. `scarb build`
2. `starkli declare target/dev/<contract-name>.contract_class.json --network sepolia --account <path/to/account.json> --keystore <path/to/keystore.json>`

- expected output
```bash
Enter keystore password: 
Sierra compiler version not specified. Attempting to automatically decide version to use...
Network detected: sepolia. Using the default compiler version for this network: 2.9.1. Use the --compiler-version flag to choose a different version.
Declaring Cairo 1 class: 0x0544827caefecbd4010a8ec04cd52ba2a5cacfdd85335bfe12d5d3b54a166036
Compiling Sierra class to CASM with compiler version 2.9.1...
CASM class hash: 0x00a3b109389575a420cd0c5ccbd14e9bf2f5b56d50f6085d08202d15ee2b3222
Contract declaration transaction: 0x031bebde4572dfa11d5e24259926f8dd383d2df2172af0df7a5699234299e4a5
Class hash declared:
0x0544827caefecbd4010a8ec04cd52ba2a5cacfdd85335bfe12d5d3b54a166036
```

3. Deploy
```bash
starkli deploy \
    <CLASS_HASH> \
    <CONSTRUCTOR_INPUTS> \
    --network sepolia --account <path/to/account.json> --keystore /path/to/keystore.json
```

```sample code
starkli deploy \
    0x0544827caefecbd4010a8ec04cd52ba2a5cacfdd85335bfe12d5d3b54a166036 \
    0x02cdAb749380950e7a7c0deFf5ea8eDD716fEb3a2952aDd4E5659655077B8510 \
    --network sepolia --account Users/mac/account.json --keystore /Users/mac/account.json
```