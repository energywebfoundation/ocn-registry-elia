pragma solidity ^0.5.15;

import "./Registry.sol";

contract EvDashboardRegistry {
    Registry private registry;
    string private constant prefix = "\u0019Ethereum Signed Message:\n32";

    struct Device {
        address user;
        string identifier;
    }

    /**
     * User Storage
     */
    mapping(address => bool) private users;
    address[] private userAddressList;

    /**
     * Device Storage
     */
    mapping(address => Device) public devices;
    mapping(string => address) private identifiers;
    address[] private deviceAddressList;
    

    constructor(address ocnRegistry) public {
        registry = Registry(ocnRegistry);
    }

    function validateRegistered(address user) private {
        (address operator, ) = registry.getOperatorByAddress(user);
        require(operator != address(0), "User not listed in OCN Registry");
    }

    /**
     * Adds business user, allowing participation in FCR market. 
     * Can be relayed by any entity: the business user only needs to sign their wallet address.
     */
    function addUser(
        address user,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) public {
        bytes32 paramHash = keccak256(abi.encodePacked(user));
        address signer = ecrecover(keccak256(abi.encodePacked(prefix, paramHash)), v, r, s);
        require(user == signer, "Expected and actual user differ");
        validateRegistered(signer);
        require(users[signer] == false, "User already added");
        users[signer] = true;
        userAddressList.push(signer);
    }

    /**
      * Adds device, allowing participation in FCR market.
      * Can be relayed by any entity: the business user only needs to sign
      * the device address, unique identifier and its own user address
      */
    function addDevice(
        address device, // the address used in the devices DID
        string memory identifier, // the unique identifier (EVSE ID, Contract ID)
        address user, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) public {
        bytes32 paramHash = keccak256(abi.encodePacked(device, identifier, user));
        address signer = ecrecover(keccak256(abi.encodePacked(prefix, paramHash)), v, r, s);
        require(user == signer, "Expected and actual user differ");
        validateRegistered(signer);
        require(users[signer] == true, "User not added yet");
        require(devices[device].user == address(0), "Device already added");
        devices[device] = Device(user, identifier);
        identifiers[identifier] = device;
        deviceAddressList.push(device);
    }

    function getAllUserAddresses() public view returns (address[] memory) {
        return userAddressList;
    }

    function getAllDeviceAddresses() public view returns (address[] memory) {
        return deviceAddressList;
    }

    function getDeviceFromIdentifier(string memory identifier) public view returns (
        address addr,
        address user
    ) {
        addr = identifiers[identifier];
        user = devices[addr].user;
    }

}
