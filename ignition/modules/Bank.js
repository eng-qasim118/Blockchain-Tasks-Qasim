// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("BankModule", (m) => {
    // If your Bank contract doesn't require constructor arguments:
    const bank = m.contract("Bank");

    return { bank };
});