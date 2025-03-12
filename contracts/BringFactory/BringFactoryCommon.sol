// SPDX-License-Identifier: GPL-3.0AA
pragma solidity ^0.8.17;
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "../interfaces/IBringDropCommon.sol";

contract BringFactoryCommon is Ownable {

    // Current version of mastercopy contract
    uint public dropContractVersion;
    
    // Contract bytecode to be installed when deploying proxy
    bytes internal _bytecode;

    uint public fee; 
    address public feeRecipient;
    
    // Maps hash(sender address, campaign id) to its corresponding proxy address
    mapping (bytes32 => address) public deployed;
        
    // Events
    event Deployed(address indexed creator, address signer, address drop, bytes32 salt);
    event SetMasterCopy(address masterCopy, uint version);
    event SetFee(uint fee);    
    event SetFeeRecipient(address feeRecipient);
    
    /**
    * @dev Indicates whether a proxy contract for BringDrop master is deployed or not
    * @param _creator Address of Drop creator
    * @param _signer signer address
    * @return True if deployed
    */
    function isDeployed(address _creator, address _signer) public view returns (bool) {
        return (deployed[salt(_creator, _signer)] != address(0));
    }
    
    /**
    * @dev Function to deploy a proxy contract for msg.sender and add a new signing key
    * @param _signer Address corresponding to signing key
    * @return proxy Proxy contract address
    */
    function createDrop(address _signer, address _token, uint _amount, uint _claims)
    public
    returns (address proxy)
    {
        
        proxy = _deployProxy(msg.sender, _signer);
    }

    /**
    * @dev Internal function to deploy a proxy contract for BringDrop master
    * @param _creator Address of drop creator
    * @param _signer Signer address
    * @return proxy Proxy contract address
    */
    function _deployProxy(address _creator, address _signer)
    internal
    returns (address proxy)
    {

        require(!isDeployed(_creator, _signer), "BRING_DROP_CONTRACT_ALREADY_DEPLOYED");
        require(_creator != address(0), "INVALID_BRING_CREATOR_ADDRESS");
        require(_signer != address(0), "INVALID_BRING_SIGNER_ADDRESS");        

        bytes32 _salt = salt(_creator, _signer);

        // minimal proxy code
        bytes memory initcode = (hex"6352c7420d6000526103ff60206004601c335afa6040516060f3");

        assembly {
            proxy := create2(0, add(initcode, 0x20), mload(initcode), _salt)
            if iszero(extcodesize(proxy)) { revert(0, 0) }
        }

        deployed[_salt] = proxy;

        // Initialize factory address, BringDrop master address master copy version in proxy contract
        require
        (
            IBringDropCommon(proxy).initialize
            (
                _creator,
                _signer,
                dropContractVersion
            ),
            "INITIALIZATION_FAILED"
        );

        emit Deployed(_creator, _signer, proxy, _salt);
        return proxy;
    }


    /**
    * @dev Function to fetch the actual contract bytecode to install. Called by proxy when executing initcode
    * @return Contract bytecode to install
    */
    function getBytecode()
    public view
    returns (bytes memory)
    {
        return _bytecode;
    }

    /**
    * @dev Function to set new master copy and update contract bytecode to install. Can only be called by factory owner
    * @param _masterCopy Address of BringDrop mastercopy contract to calculate bytecode from
    * @return True if updated successfully
    */
    function setMasterCopy(address _masterCopy)
    public onlyOwner
    returns (bool)
    {
        require(_masterCopy != address(0), "INVALID_MASTER_COPY_ADDRESS");
        dropContractVersion = dropContractVersion + 1;

        require
        (
            IBringDropCommon(_masterCopy).initialize
            (
                address(0), // creator
                address(0), // signer
                dropContractVersion
            ),
            "INITIALIZATION_FAILED"
        );

        bytes memory bytecode = abi.encodePacked
        (
            hex"363d3d373d3d3d363d73",
            _masterCopy,
            hex"5af43d82803e903d91602b57fd5bf3"
        );

        _bytecode = bytecode;

        emit SetMasterCopy(_masterCopy, dropContractVersion);
        return true;
    }


     /**
     * @dev Function to set the fee recipient address. Only the contract owner can update this value.
     * @param _feeRecipient New fee recipient address to set.
     * @return True if the fee recipient is updated successfully.
     */
    function setFeeRecipient(address _feeRecipient) public onlyOwner returns (bool) {
        require(_feeRecipient != address(0), "INVALID_FEE_RECIPIENT_ADDRESS");
        feeRecipient = _feeRecipient;
        emit SetFeeRecipient(_feeRecipient);
        return true;
    }


    /**
     * @dev Function to update the fee value. Only the contract owner can update the fee.
     * @param _fee New fee value to set.
     * @return True if the fee is updated successfully.
     */
    function setFee(uint _fee) public onlyOwner returns (bool) {
        fee = _fee;
        emit SetFee(_fee);
        return true;
    }
    
    /**
     * @dev Function to hash `_creator` and `_signer` params. Used as salt when deploying with create2
     * @param _creator Drop Creator address
     * @param _signer Drop signer address
     * @return Hash of passed arguments
     */
    function salt(address _creator, address _signer) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_creator, _signer));
    }
  }
