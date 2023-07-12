// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**



  /$$$$$$            /$$                 /$$$$$$$$        /$$                                    
 /$$__  $$          |__/                |__  $$__/       | $$                                    
| $$  \__/  /$$$$$$  /$$ /$$$$$$$          | $$  /$$$$$$ | $$   /$$  /$$$$$$  /$$$$$$$   /$$$$$$$
| $$       /$$__  $$| $$| $$__  $$         | $$ /$$__  $$| $$  /$$/ /$$__  $$| $$__  $$ /$$_____/
| $$      | $$  \ $$| $$| $$  \ $$         | $$| $$  \ $$| $$$$$$/ | $$$$$$$$| $$  \ $$|  $$$$$$ 
| $$    $$| $$  | $$| $$| $$  | $$         | $$| $$  | $$| $$_  $$ | $$_____/| $$  | $$ \____  $$
|  $$$$$$/|  $$$$$$/| $$| $$  | $$         | $$|  $$$$$$/| $$ \  $$|  $$$$$$$| $$  | $$ /$$$$$$$/
 \______/  \______/ |__/|__/  |__/         |__/ \______/ |__/  \__/ \_______/|__/  |__/|_______/ 



*/

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface iERC20 {
  function balanceOf(address owner) external view returns (uint256);
  function decimals() external view returns (uint8);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool); 
}

/** @title CoinTokens v1.0
  * @author Matto (AKA MonkMatto, Matto.xyz)
  * @notice This experimental contract exchanges ERC-20 'coin' amounts and ERC-1155 'token' denominations of the ERC-20.
  * @dev Custom ERC-1155 contract with ERC-20 interface. URIs uses mapping because tokenIDs match denominations.
  * Using this contract with an improperly coded/malicious ERC-20 contract could cause loss of user funds.
  * @custom:security-contact monkmatto@protonmail.com
  */
contract CoinTokens is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply, ReentrancyGuard {
    mapping(uint256 => string) URIs;
    string public name;
    string public symbol;
    address public ERC20;
    uint256[] public denominations;
    address royaltyAccount;
    uint256 royaltyBPS;
    bool public returnTheChange;
    uint256 decimalsMultiplier;

    /** 
      * @notice Runs one time on contract deployment and sets initial parameters.
      * @dev Permantly sets these parameters.
      * @param _name is the name for the contract.
      * @param _symbol is the symbol for the contract's tokens.
      * @param _ERC20contract is the ERC-20 contract to exchange with.
      * @param _denominations is an array of decreasing integer denomination values - DO NOT include '0' for tokenId 0.
      */
    constructor(
        string memory _name,
        string memory _symbol,
        address _ERC20contract, 
        uint256[] memory _denominations
    ) ERC1155("") {
        name = _name;
        symbol = _symbol;
        ERC20 = _ERC20contract;
        denominations = _denominations;
        decimalsMultiplier = 10 ** uint256(iERC20(_ERC20contract).decimals());
    }

    event LockedTokens(address indexed sender, uint256 ERC20Locked);
    event ChangeReturned(address indexed sender, uint256 ERC20Change);
    event Denominated(address indexed sender, uint256 ERC20Denominated);
    event Liquidated(address indexed sender, uint256 ERC20Liquidated);

    /** 
      * @notice Returns a token's URI information.
      * @dev overrides to use mapping of URIs instead of an array.
      * @param tokenId is the tokenId to get the URI of.
      */
    function uri(uint256 tokenId)
        view
        public
        override
        returns (string memory)
    {
        return URIs[tokenId];
    }

    /** 
      * @notice Returns the amount of ERC-20 that is currently held in denominations by an account.
      * @dev Iterates the denominations array and sums any balance held by an account.
      * @param account is any EOA.
      * @return value represents the value of ERC-1155 tokens issued by this contract to the account.
      */
    function valueOfAccountsTokens(address account) 
        external 
        view 
        returns (uint256) 
    {
        uint256 value;
        for (uint256 i = 0; i < denominations.length; i++) {
            value += balanceOf(account, denominations[i]) * denominations[i];
        }
        return value;
    }  

    /** 
      * @notice Returns the amount of ERC-20 that is being circulated as ERC-1155 denominated tokens.
      * @dev Iterates the denominations array and sums value denominated into each.
      * @return value represents the value of all issued ERC-1155 tokens.
      */
    function valueInCirculation() 
        public 
        view 
        returns (uint256) 
    {
        uint256 value;
        for (uint256 i = 0; i < denominations.length; i++) {
            value += totalSupply(denominations[i]) * denominations[i];
        }
        return value;
    }

    /** 
      * @notice Returns the amount of ERC-20 that is forever locked by this contract.
      * @dev There is no withdraw function present in this contract. Any balance above issued token value is locked.
      */
    function valueLockedByContract()
        external 
        view 
        returns (uint256) 
    {
        return ((iERC20(ERC20).balanceOf(address(this)) / decimalsMultiplier) - valueInCirculation());
    }

    /** 
      * @notice Returns royalty information.
      * @dev Because all token's have the same royalty details, this function has been simplified.
      * @param tokenId is expected by the standard but the parameter is not used in this implementation.
      */
    function getRoyalties(uint256 tokenId)
        external
        view
        returns (address, uint256)
    {
        return (royaltyAccount, royaltyBPS);
    }

    /** 
      * @notice Returns royalty information for a specific token's sale.
      * @dev Because all token's have the same royalty details, this function has been simplified.
      * @param tokenId is expected by the standard but the parameter is not used in this implementation.
      * @param value is the sale amount to calculate royalties for.
      */
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        returns (address, uint256)
    {
        return (royaltyAccount, value * royaltyBPS / 10000); 
    }

    /** 
      * @notice Updates the ERC-1155 royalty information.
      * @param newAccount becomes the new address for royaltyAccount.
      * @param newBPS becomes the new royaltyBPS.
      */
    function setRoyaltyData(address newAccount, uint256 newBPS)
        external
        onlyOwner
    {
        royaltyAccount = newAccount;
        royaltyBPS = newBPS;
    }

    /** 
      * @notice Allows setting of all tokenURI information at once.
      * @dev Updates all denomination tokenURIs.
      * If the submitted array has more elements than denominations, the last element is set to tokenId 0.
      * @param newURIs is a string array of all tokenURIs, in order of decreasing denomination.
      */
    function setAllURIs(string[] memory newURIs) 
        external 
        onlyOwner
    {
        require(!(newURIs.length < denominations.length), "URI array too short");
        for (uint256 i = 0; i < denominations.length; i++) {
            URIs[denominations[i]] = newURIs[i];
        }
        if (newURIs.length > denominations.length) {
            URIs[0] = newURIs[newURIs.length - 1];
        }
    }

    /** 
      * @notice Allows setting of a single token's URI information.
      * @dev Sets a single token's URI.
      * @param id is the tokenID to set.
      * @param newURI is the new URI to store.
      */
    function setURI(uint256 id, string memory newURI) 
        external 
        onlyOwner 
    {
        URIs[id] = newURI;
    }

    /** 
      * @notice Toggles returnTheChange on or off.
      * @dev returnTheChange is public so for efficiency only a toggle is provided.
      */
    function toggleReturnTheChange() 
        external 
        onlyOwner 
    {
        returnTheChange = !returnTheChange;
    }

    /** 
      * @notice Breaks ERC-20 value into largest possible ERC-1155 denominations and sends tokens back to caller.
      * @dev denominations array can be iterated this way because the denominations are in decreasing order.
      * @param amountToDenominate The amount of ERC-20 being denominated.
      */
    function DENOMINATE_ALL(uint256 amountToDenominate)
        external
        nonReentrant
    {
        require(amountToDenominate > 0, "Must denominate something");
        iERC20(ERC20).transferFrom(msg.sender, address(this), amountToDenominate * decimalsMultiplier);
        uint256 leftover = amountToDenominate;
        uint256[] memory amountToIssue = new uint256[](denominations.length);
        uint256 issueCount;
        for (uint256 i = 0; i < denominations.length; i++) {
            amountToIssue[i] = leftover / denominations[i];
            leftover = leftover - (amountToIssue[i] * denominations[i]);
            if (amountToIssue[i] > 0) {
                issueCount++;
            }
        }
        if (issueCount > 0) { 
            _mintBatch(msg.sender, denominations, amountToIssue, "");
            emit Denominated(msg.sender, amountToDenominate - leftover);
        }
        if (leftover > 0) _processLeftover(leftover);
    }

    /** 
      * @notice Breaks ERC-20 value into submitted ERC-1155 denomination and sends tokens back to caller.
      * @dev _getDenominationIndex finds the index of the submitted denomination in the demoninations array.
      * @param amountToDenominate The amount of ERC-20 being denominated.
      * @param tokenDenomination The denomination of ERC-1155 that is being exchanged.
      */
    function DENOMINATE_INTO_TOKEN(uint256 amountToDenominate, uint256 tokenDenomination)
        external
        nonReentrant
    {
        require(amountToDenominate > 0, "Must denominate something");
        iERC20(ERC20).transferFrom(msg.sender, address(this), amountToDenominate * decimalsMultiplier);
        uint256 index = _getDenominationIndex(tokenDenomination);
        uint256 amountToIssue = amountToDenominate / denominations[index];
        if (amountToIssue > 0) {
            _mint(msg.sender, denominations[index], amountToIssue, "");
            emit Denominated(msg.sender, amountToIssue * denominations[index]);
        }
        uint256 leftover = amountToDenominate - (amountToIssue * denominations[index]);
        if (leftover > 0) _processLeftover(leftover);
    }

    /** 
      * @notice Converts all ERC-1155 tokens held by caller to ERC-20 and sends it back to the caller.
      * @dev All ERC-1155 denomination tokens owned by the caller are burned in the process.
      */
    function LIQUIDATE_ALL()
        external
        nonReentrant
    {
        uint256[] memory amountToBurn = new uint256[](denominations.length);
        uint256 withdrawlAmount;
        for (uint256 i = 0; i < denominations.length; i++) {
            amountToBurn[i] = balanceOf(msg.sender, denominations[i]);
            if (amountToBurn[i] > 0) {
                withdrawlAmount += denominations[i] * amountToBurn[i];
            }
        }
        require(withdrawlAmount > 0, "Insufficient Balance");
        burnBatch(msg.sender, denominations, amountToBurn);
        iERC20(ERC20).transfer(msg.sender, withdrawlAmount * decimalsMultiplier);
        emit Liquidated(msg.sender, withdrawlAmount);
    }

    /** 
      * @notice Converts a specified quantity and denomination of ERC-1155 tokens to ERC-20 and sends it to caller.
      * @dev ERC-1155 tokens owned by the caller are burned in the process.
      * @param amountToLiquidate is the amount of tokens to exchange for ERC-20.
      * @param tokenDenomination is token denomination (and tokenId) to be liquidated to ERC-20.
      */
    function LIQUIDATE_FROM_TOKEN(uint256 amountToLiquidate, uint256 tokenDenomination)
        external
        nonReentrant
    {
        require(amountToLiquidate > 0, "Must liquidate something");
        uint256 index = _getDenominationIndex(tokenDenomination);
        require(balanceOf(msg.sender, denominations[index]) >= amountToLiquidate, "Insufficient Balance");
        burn(msg.sender, denominations[index], amountToLiquidate);
        iERC20(ERC20).transfer(msg.sender, amountToLiquidate * denominations[index] * decimalsMultiplier);
        emit Liquidated(msg.sender, amountToLiquidate * denominations[index]);
    }

    /** 
      * @notice Helper function finds the index of a submitted denomination in the denominations array.
      * @dev Returns immediately upon finding a match to save gas.
      * @param submittedDenomination is the value to find in the denominations array.
      * @return index in the array where submittedDenomination can be found.
      */
    function _getDenominationIndex(uint256 submittedDenomination)
        internal 
        view 
        returns (uint256) 
    {
        for (uint256 i = 0; i < denominations.length; i++) {
            if (submittedDenomination == denominations[i]) {
                return i;
            }
        }
        revert("Invalid Denomination");
    }

    /** 
      * @notice Helper function to handle cases when excess ERC-20 is used in denominate functions.
      * @dev tokenID 0 has a ERC-20 value of 0 and is not in the denominations array.
      * @param leftover is the amount of ERC-20 that is leftover from denomination functions.
      */
    function _processLeftover(uint256 leftover) 
        internal 
    {
        if (returnTheChange) {
            emit ChangeReturned(msg.sender, leftover);
            iERC20(ERC20).transfer(msg.sender, leftover * decimalsMultiplier);
        } else { 
            emit LockedTokens(msg.sender, leftover);
            _mint(msg.sender, 0, leftover, "");
        }
    }

    /** 
      * @notice Helper function to enhance supply tracking
      * @dev from OpenZeppelin supply extension
      */
    function _beforeTokenTransfer(
        address operator, 
        address from, 
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data
    )
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}