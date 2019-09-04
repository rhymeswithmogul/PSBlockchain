<#
This file is part of PSBlockchain.
<https://github.com/rhymeswithmogul/PSBlockchain/>

PSBlockchain is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

PSBlockchain is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PSBlockchain.  If not, see <https://www.gnu.org/licenses/>.
#>

#Requires -Version 5

class PSBlockchain {
    hidden [UInt32] $Version = 1
    hidden [System.Collections.ArrayList] $Blocks = (New-Object System.Collections.ArrayList)

    #region Class constructors
    PSBlockchain() {
        $this.Add($null)
    }

    PSBlockchain([PSCustomObject]$obj) {
        $this.Add($obj)
    }
    #endregion

    #region Getters
    static [UInt32[]] SupportedVersions() {
        Return 1
    }

    [UInt32] GetVersion() {
        Return $this.Version
    }

    [PSBlockchainBlock] GetBlock([UInt64]$BlockID) {
        If ($BlockID -lt $this.GetLength()) {
            Return $this.Blocks[$BlockID]
        }
        Return $null
    }

    [PSBlockchainBlock] GetGenesisBlock() {
        Return $this.Blocks[0]
    }

    [PSBlockchainBlock] GetLastBlock() {
        Return $this.Blocks[-1]
    }

    [UInt64] GetLength() {
        Return $this.Blocks.Count
    }
    [UInt64] Count() {
        Return $this.Blocks.Count
    }
    #endregion

    #region Setters
    [void] Add([Object]$obj) {
        $this.AddBlock([PSBlockchainBlock]::new($obj))
    }

    [void] AddBlock([PSBlockchainBlock]$newBlock) {
        $this.Blocks.Add($newBlock)
        If ($this.GetLength() -gt 1) {
            $this.Blocks[-1].SetPreviousBlock($this.Blocks[-2])
        }
    }
    #endregion

    #region Verification
    [bool] Verify() {
        If ($this.Count() -eq 0) {
            Return $true
        }
        ElseIf ($this.Count -eq 1) {
            Return $this.GetGenesisBlock().Verify()
        }
        Else {
            $Progress = "Verifying the blockchain"
            Write-Progress -Activity $Progress

            For ($i = 1; $i -lt $this.GetLength(); $i++) {
                Write-Progress -Activity $Progress -CurrentOperation "Validating block $i of $($this.GetLength())" -PercentComplete (100 * $i / $this.GetLength())

                If ($this.GetBlock($i).GetPreviousBlockHash() -eq $this.GetBlock($i-1).GetHash()) {
                    Write-Debug "[$i] The previous block's hash value matches the actual hash of previous block."
                } Else {
                    Write-Error -Message "Verification failed at block $i (previous hash does not match)" -Category InvalidResult -TargetObject ($this.GetBlock($i-1))
                    Write-Progress -Activity $Progress -Completed
                    Return $false
                }

                If ($this.GetBlock($i).Verify()) {
                    Write-Debug "[$i] This block's stored hash value is correct."
                } Else {
                    Write-Error -Message "Verification failed at block $i (hash did not verify)" -Category InvalidData -TargetObject ($this.GetBlock($i))
                    Write-Progress -Activity $Progress -Completed
                    Return $false
                }
            }
        }
        Write-Progress -Activity $Progress -Completed
        Return $true
    }
    #endregion

    [String] ToString() {
        $RetVal = ""
        $this.Blocks | ForEach-Object {$RetVal += $_}
        Return $RetVal
    }

    [String] ToCompressedString() {
        $RetVal = ""
        $this.Blocks | ForEach-Object {$RetVal += $_.ToCompressedString()}
        Return $RetVal
    }
}

class PSBlockchainBlock : <# implements #> System.IComparable {
    hidden [UInt32] $Version = 1
    hidden [UInt64] $BlockID = 0
    hidden [DateTime] $Timestamp = (Get-Date)
    hidden [String] $PreviousBlockHash
    hidden [String] $Nonce = -Join ((65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
                           # ↑ Thanks to https://devblogs.microsoft.com/scripting/generate-random-letters-with-powershell/
    hidden [PSCustomObject] $Content
    hidden [String] $Hash

    #region Class constructors.
    PSBlockchainBlock() {
        $this.SetContent($null)
    }

    PSBlockchainBlock([PSCustomObject]$obj) {
        $this.SetContent($obj)
    }
    #endregion

    #region Getters
    static [UInt32[]] SupportedVersions() {
        Return 1
    }

    [UInt32] GetVersion() {
        Return $this.Version
    }

    [UInt64] GetBlockID() {
        Return $this.BlockID
    }

    [DateTime] GetBlockTimestamp() {
        Return $this.Timestamp
    }

    [String] GetNonce() {
        Return $this.Nonce
    }

    [PSCustomObject] GetContent() {
        Return $this.Content
    }

    [String] GetHash() {
        Return $this.Hash
    }

    [String] GetPreviousBlockHash() {
        Return $this.PreviousBlockHash
    }

    [Bool] IsGenesisBlock() {
        Return ($this.PreviousBlockHash -IsNot $null)
    }
    #endregion

    #region Setters
    [void] SetBlockID([UInt64]$NewID) {
        $this.BlockID = $NewID
        $this.UpdateHash()
    }

    [void] SetBlockTimestamp() {
        $this.SetBlockTimestamp((Get-Date))
    }

    [void] SetBlockTimestamp([DateTime]$NewTimestamp) {
        $this.Timestamp = $NewTimestamp
        $this.UpdateHash()
    }

    [void] SetPreviousBlock([PSBlockchainBlock]$NewPrevBlock) {
        $this.BlockID = $NewPrevBlock.GetBlockID() + 1
        $this.PreviousBlockHash = $NewPrevBlock.GetHash()
        $this.UpdateHash()
    }

    [void] SetContent([PSCustomObject]$obj) {
        $this.Content = $obj
        $this.UpdateHash()
    }
    #endregion

    [int] CompareTo([Object]$that) {
        If ($this.GetHash() -eq $that.GetHash()) {
            Return 0
        } Else {
            # If the blocks don't match, then sort by block ID number instead.
            # There's no real reason why it's done this way.  It's just to support -lt/-gt.
            Return ($this.BlockID.CompareTo($that.BlockID))
        }
    }

    [String] ToString() {
        Return (Out-String -InputObject ([ordered]@{
            Version       = $this.Version;
            BlockID       = $this.BlockID;
            Timestamp     = $this.Timestamp.ToFileTimeUTC();
            PrevBlockHash = $this.PreviousBlockHash;
            Nonce         = $this.Nonce;
            Content       = $this.Content;
            Hash          = $this.Hash
        }))
    }

    [String] ToCompressedString() {
        Return (ConvertTo-JSON -Compress -InputObject ([ordered]@{
            v = $this.Version;
            i = $this.BlockID;
            t = $this.Timestamp.ToFileTimeUTC();
            p = $this.PreviousBlockHash;
            n = $this.Nonce;
            c = $this.Content;
            h = $this.Hash
        }))
    }

    [bool] Verify() {
        Return $this.Hash -eq $this.Hasher()
    }

    #region Helper functions
    hidden [String] Hasher() {
        $Engine  = New-Object System.Security.Cryptography.SHA256Managed
        $TheHash = $Engine.ComputeHash([System.Text.Encoding]::UTF8.GetBytes(
                        ("v{0}:i{1}:t{2}:p{3}:n{4}::{5}" -f `
                            $this.Version,
                            $this.BlockID,
                            $this.Timestamp.ToFileTimeUTC(),
                            $this.PreviousBlockHash,
                            $this.Nonce,
                            $this.Content
                        )
        ))
        $Engine.Dispose()
        Return ([System.BitConverter]::ToString($TheHash) -Replace '-')
    }

    hidden [void] UpdateHash() {
        $this.Hash = $this.Hasher()
    }
    #endregion
}