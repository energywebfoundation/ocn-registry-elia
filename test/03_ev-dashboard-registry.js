const { ethers } = require("ethers")
const { toHex } = require("web3-utils")
const sign = require("./sign")

const OcnRegistry = artifacts.require('../contracts/Registry.sol')
const EvdRegistry = artifacts.require('../contracts/EvDashboardRegistry.sol')

const randomWallet = () => ethers.Wallet.createRandom()
const randomAddress = () => ethers.Wallet.createRandom().address

contract.only('EvDashboardRegistry', (accounts) => {

    let ocn
    let registry

    const operator = accounts[1]

    const users = [
        randomWallet(),
        randomWallet()
    ]

    const devices = [
        {
            address: randomAddress(),
            identifier: 'DE-EVM-00001'
        },
        {
            address: randomAddress(),
            identifier: 'DE-EVM-00002'
        },
        {
            address: randomAddress(),
            identifier: 'DE-EVC-7070707'
        }
    ]

    beforeEach(async () => {
        ocn = await OcnRegistry.new()
        registry = await EvdRegistry.new(ocn.address)
        await ocn.setNode('http://localhost:8080', { from: operator })
        const sig = await sign.setPartyRaw(toHex('DE'), toHex('EVM'), [0], operator, users[0])
        await ocn.setPartyRaw(users[0].address, toHex('DE'), toHex('EVM'), [0], operator, sig.v, sig.r, sig.s, { from: operator })
    })

    it('should add user if set in OCN registry', async () => {
        const sig = await sign.addUser(users[0])
        await registry.addUser(users[0].address, sig.v, sig.r, sig.s, { from: operator })
        const userAddresses = await registry.getAllUserAddresses()
        assert.deepEqual(userAddresses, [users[0].address])
    })

    it('should reject user if not set in OCN Registry', async () => {
        const sig = await sign.addUser(users[1])
        try {
            await registry.addUser(users[1].address, sig.v, sig.r, sig.s, { from: operator })
            assert.fail()
        } catch (e) {
            assert.isTrue(e.message.includes('User not listed in OCN Registry'))
        }
    })

    it('should reject user if already added', async () => {
        const sig = await sign.addUser(users[0])
        await registry.addUser(users[0].address, sig.v, sig.r, sig.s, { from: operator })
        try {
            await registry.addUser(users[0].address, sig.v, sig.r, sig.s, { from: operator })
            assert.fail()
        } catch (e) {
            assert.isTrue(e.message.includes('User already added'))
        }
    })

    it('should add device if user added', async () => {
        const sig1 = await sign.addUser(users[0])
        await registry.addUser(users[0].address, sig1.v, sig1.r, sig1.s, { from: operator })
        const sig2 = await sign.addDevice(devices[0].address, devices[0].identifier, users[0])
        await registry.addDevice(devices[0].address, devices[0].identifier, users[0].address, sig2.v, sig2.r, sig2.s, { from: operator })
        const deviceAddresses = await registry.getAllDeviceAddresses()
        assert.deepEqual(deviceAddresses, [devices[0].address])
        const device = await registry.devices(devices[0].address)
        assert.equal(device.identifier, devices[0].identifier)
        assert.equal(device.user, users[0].address)
    })

    it('should reject device if user not added', async () => {
        const sig = await sign.addDevice(devices[0].address, devices[0].identifier, users[0])
        try {
            await registry.addDevice(devices[0].address, devices[0].identifier, users[0].address, sig.v, sig.r, sig.s, { from: operator })
            assert.fail()
        } catch (e) {
            assert.isTrue(e.message.includes('User not added yet'))
        }
    })

    it('should reject device if already added', async () => {
        const sig1 = await sign.addUser(users[0])
        await registry.addUser(users[0].address, sig1.v, sig1.r, sig1.s, { from: operator })
        const sig2 = await sign.addDevice(devices[0].address, devices[0].identifier, users[0])
        await registry.addDevice(devices[0].address, devices[0].identifier, users[0].address, sig2.v, sig2.r, sig2.s, { from: operator })
        try {
            await registry.addDevice(devices[0].address, devices[0].identifier, users[0].address, sig2.v, sig2.r, sig2.s, { from: operator })
            assert.fail()
        } catch (e) {
            assert.isTrue(e.message.includes('Device already added'))
        }
    })

    it('should resolve device from its unique identifier', async () => {
        const sig1 = await sign.addUser(users[0])
        await registry.addUser(users[0].address, sig1.v, sig1.r, sig1.s, { from: operator })
        const sig2 = await sign.addDevice(devices[0].address, devices[0].identifier, users[0])
        await registry.addDevice(devices[0].address, devices[0].identifier, users[0].address, sig2.v, sig2.r, sig2.s, { from: operator })
        const device = await registry.getDeviceFromIdentifier(devices[0].identifier)
        assert.equal(device.addr, devices[0].address)
        assert.equal(device.user, users[0].address)
    })

})