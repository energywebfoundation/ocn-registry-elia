pragma ^0.5.16;

import "./Registry.sol";

contract EvDashboardRegistry {
    Registry private registry;
    string private constant prefix = "\u0019Ethereum Signed Message:\n32";

    struct Device {
        address owner;
        string identifier;
    }

    /**
     * User Storage
     */
    mapping(address => bool) public users;
    address[] public userList;

    /**
     * Device Storage
     */
    mapping(address => Device) public devices; 
    address[] public devices;
    

    constructor(address ocnRegistry) {
        this.registry = Registry(ocnRegistry);
    }

    function validateRegistered(address user) private {
        (address operator, ) = registry.getOperatorByAddress(provider);
        require(operator != address(0), "Trying to add user without listing in OCN Registry.");
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
        userList.push(signer);
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
        bytes32 paramHash = keccak256(abi.encodePacked(device, identifier, owner));
        address signer = ecrecover(keccak256(abi.encodePacked(prefix, paramHash)), v, r, s);
        require(owner == signer, "Expected and actual user differ");
        validateRegistered(signer);
        require(users[signer] == true, "User not added yet");
        require(devices[device] == false, "Device already added");
        devices[device] = true;
        devices[device] = Device(user, identifier);
        devicesList.push(device);
    }

    function resolveDeviceFromIdentifier(string memory identifier) public returns (Device) {
        // TODO
    }

}
