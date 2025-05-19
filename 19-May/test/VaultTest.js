const { expect } = require('chai');
const { ethers } = require('hardhat');
const { parseEther } = require("ethers"); // ✅ for CommonJS


describe("Vault Contract", function() {
    let owner, add1, add2;
    let ContractObj, DeployContract;
    const oneDay = 24 * 60 * 60; // 1 day in seconds
    const twoDays = 2 * oneDay; // 2 days


    beforeEach(async function() {
        [owner, add1, add2] = await ethers.getSigners();
        ContractObj = await ethers.getContractFactory('Vault');
        DeployContract = await ContractObj.deploy();
    });

    it('should test Owner is Deployer', async function() {

        expect(await DeployContract.owner()).to.equal(owner.address);
    });

    it('Users should deposite ETH successfully', async function() {

        await DeployContract.deposit({ value: parseEther("1") });
        expect(await DeployContract.getBalance(owner.address)).to.equal(parseEther("1"));

        await DeployContract.connect(add1).deposit({ value: parseEther("1") });
        expect(await DeployContract.getBalance(add1.address)).to.equal(parseEther("1"));

    });

    it('User should not deposite less', async function() {

        try {
            await DeployContract.connect(add1).deposit({ value: parseEther("0.5") });
            expect.fail("Expected revert but transaction succeeded");
        } catch (error) {
            expect(error.message).to.include("Vault__InvalidDeposit");
        }


    });

    it('User should not withdraw if have not that amount', async function() {
        try {
            await DeployContract.connect(add1).deposit({ value: parseEther("1") });
            await DeployContract.connect(add1).withdraw(parseEther('2'));
            expect.fail("Expected revert but transaction succeeded");
        } catch (error) {
            expect(error.message).to.include("Vault__NotEnoughBalance()");
        }

    });

    it('Should withdraw their balance ', async function() {
        await DeployContract.connect(add1).deposit({ value: parseEther("1") });
        await DeployContract.connect(add1).withdraw(parseEther('0.5'));
        expect(await DeployContract.getBalance(add1.address)).to.equal(parseEther('0.5'));

    });

    it('Should not withdraw greater than limit ', async function() {
        await DeployContract.connect(add1).deposit({ value: parseEther("6") });
        try {
            await DeployContract.connect(add1).withdraw(parseEther('6'));
            expect.fail('Expected revert but transaction succeeded');
        } catch (error) {
            expect(error.message).to.include('Vault__ExceedsDailyLimit()');
        }

    });

    it('Should not withdraw twice in  day ', async function() {
        await DeployContract.connect(add1).deposit({ value: parseEther("5") });
        await DeployContract.connect(add1).withdraw(parseEther('1'));
        await expect(DeployContract.connect(add1).withdraw(parseEther('1'))).to.revertedWithCustomError(DeployContract, 'Vault__WithdrawalTooSoon()');

    });

    it('Should do second withdraw after 1 day ', async function() {
        await DeployContract.connect(add1).deposit({ value: parseEther("5") });
        await DeployContract.connect(add1).withdraw(parseEther('1'));
        await network.provider.send("evm_increaseTime", [86400]);
        await DeployContract.connect(add1).withdraw(parseEther('1'))
        expect(await DeployContract.getBalance(add1.address)).to.equal(parseEther('3'));

    });

    it('Should not transfer to 0 address ', async function() {
        const zeroAddress = ethers.ZeroAddress;
        await DeployContract.connect(add1).deposit({ value: parseEther("5") });
        await expect(DeployContract.connect(add1).transfer(zeroAddress, parseEther('1'))).to.revertedWithCustomError(DeployContract, 'Vault__InvalidRecipient()');
    });

    it('Should not transfer to itself address ', async function() {

        await DeployContract.connect(add1).deposit({ value: parseEther("5") });
        await expect(DeployContract.connect(add1).transfer(add1, parseEther('1'))).to.revertedWithCustomError(DeployContract, 'Vault__InvalidRecipient()');
    });

    it('Should not transfer amount if have not balance ', async function() {

        await DeployContract.connect(add1).deposit({ value: parseEther("5") });
        await expect(DeployContract.connect(add1).transfer(add2, parseEther('6'))).to.revertedWithCustomError(DeployContract, 'Vault__NotEnoughBalance()');
    });

    it('Should not transfer amount if have not balance ', async function() {

        await DeployContract.connect(add1).deposit({ value: parseEther("5") });
        await expect(DeployContract.connect(add1).transfer(add2, parseEther('6'))).to.revertedWithCustomError(DeployContract, 'Vault__NotEnoughBalance()');
    });

    it('Should transfer to other users ', async function() {

        const transferAmount = parseEther('2');
        await DeployContract.connect(add1).deposit({ value: parseEther("5") });
        await DeployContract.connect(add1).transfer(add2, transferAmount);
        expect(await DeployContract.connect(add2).getBalance(add2.address)).to.equal(transferAmount);

    });

    it('Should revert if other users access ownable functions ', async function() {

        await expect(DeployContract.connect(add1).setDailyLimit(parseEther('10'))).to.revertedWithCustomError(DeployContract, "OwnableUnauthorizedAccount").withArgs(add1.address);
        await expect(DeployContract.connect(add1).setWithdrawalDelay(twoDays)).to.revertedWithCustomError(DeployContract, "OwnableUnauthorizedAccount").withArgs(add1.address);

    });

    it('Owner should set new Limit and Withdraw Delay ', async function() {

        await DeployContract.setDailyLimit(parseEther('10'));
        await DeployContract.setWithdrawalDelay(twoDays);

        expect(await DeployContract.withdrawLimit()).to.equal(parseEther('10'));
        expect(await DeployContract.withdrawalDelay()).to.equal(twoDays);

    });

    it('Should emit events ', async function() {

        await expect(DeployContract.deposit({ value: parseEther('2') })).to.emit(DeployContract, 'Vault__Deposited').withArgs(owner.address, parseEther('2'));
        await expect(DeployContract.withdraw(parseEther('1'))).to.emit(DeployContract, 'Vault__Withdrawn').withArgs(owner.address, parseEther('1'));
        await expect(DeployContract.transfer(add1, parseEther('0.5'))).to.emit(DeployContract, 'Vault__Transferred').withArgs(owner.address, add1.address, parseEther('0.5'));
        await expect(DeployContract.setDailyLimit(parseEther('6'))).to.emit(DeployContract, 'Vault__DailyLimitUpdated').withArgs(parseEther('6'));
        await expect(DeployContract.setWithdrawalDelay(twoDays)).to.emit(DeployContract, 'Vault__WithdrawalDelayUpdated').withArgs(twoDays);

    });

    it.only('Should tell next withrawal time ', async function() {
        const withdrawalDelay = 86400;
        await DeployContract.connect(add1).deposit({ value: parseEther("5") });
        const tx = await DeployContract.connect(add1).withdraw(parseEther('1'));
        const receipt = await tx.wait();
        const block = await ethers.provider.getBlock(receipt.blockNumber);
        const currentTimestamp = block.timestamp;
        const expectedNextWithdraw = currentTimestamp + withdrawalDelay;
        const contractNextWithdraw = await DeployContract.nextWithdrawTime(add1.address);
        expect(contractNextWithdraw).to.equal(expectedNextWithdraw);

    });

});