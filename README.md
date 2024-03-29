
# PSBlockchain
This module, and its [`[PSBlockchain]`](https://github.com/rhymeswithmogul/PSBlockchain/blob/master/en-us/about_PSBlockchain.help.txt) and [`[PSBlockchainBlock]`](https://github.com/rhymeswithmogul/PSBlockchain/blob/master/en-us/about_PSBlockchainBlock.help.txt) classes, represent a blockchain.  It is compatible with Windows PowerShell 5 as well as PowerShell Core.

## Quick Example
````powershell
PS C:\> $chain = [PSBlockchain]::new("This is PSCoin's ledger.")
PS C:\> $chain.Add("Alice mined 50 PSC into her wallet.")
PS C:\> $chain.Add("Bob mined 50 PSC into his wallet.")
PS C:\> $chain.Add("Alice sent 25 PSC to Bob.")
PS C:\> $chain.Add("Bob sent 10 PSC to Chris.")

PS C:\> $chain.GetBlock(2)
Name          Value
----          -----
Version       1
BlockID       2
Timestamp     132120434319335190
PrevBlockHash 87A938599211B54F1FEA0D9786FB4AD0D0A8243DBE3710E82F2CE7F840EC5376
Nonce         LuwSGjUaoAKBrRTbFkecJZxfCPMyvHnp
Content       Bob mined 50 PSC into his wallet.
Hash          3997F88BC627988564A5E70AE15B4CF600EFD0F9DB9DB3BC79EFF0318F4CAFBF

PS C:\> $chain.Verify()
True
````
