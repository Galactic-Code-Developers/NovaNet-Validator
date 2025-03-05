const NovaNetValidator = artifacts.require("NovaNetValidator");
const DelegatorContract = artifacts.require("DelegatorContract");

module.exports = async function (deployer) {
    await deployer.deploy(NovaNetValidator);
    const validatorInstance = await NovaNetValidator.deployed();

    await deployer.deploy(DelegatorContract, validatorInstance.address);
};
