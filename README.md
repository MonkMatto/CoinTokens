# CoinTokens
This experimental contract exchanges ERC-20 'coin' amounts and ERC-1155 'token' denominations of the ERC-20.

For end-user safety, anti-rug features include locking the ERC-20 being used and denominations at deployment.
For owner flexibility, instead of a baseURI being used for all tokens, the contract tracks individual URIs.

Things to Note:
- This code has not (yet) been audited by a third-party security team - use at your own risk.
- The denominations array cannot be modified after deployment.
- - It MUST be in order of decreasing values.
- - It MUST NOT inlcude a value of '0'.
- The returnTheChange boolean is set to false by default.
- - This burns (by locking) excess ERC-20 sent into denomination functions and issues tokenId 0 in exchange (1:1).
- - 'tokenId 0' is NOT a valid denomination and it cannot be exchanged for ERC-20 value.
- - To add the URI for tokenId 0, either include it at the end of the URI array when using setAllURIs, or set it individually in setURI.
- Toggle returnTheChange with the toggleReturnTheChange function.
- - If returnTheChange is set to true, ERC-20 excess is sent back to user and tokenId 0 is not minted.
- If communities use ERC-20 balance for access, a denomination of the same required size amount should be created and allowed for access.