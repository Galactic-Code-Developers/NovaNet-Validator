const { expect } = require("chai");

describe("DelegatorContract", function () {
  let delegator, validator, owner;
  let delegatorContract, validatorContract;

  beforeEach(async function () {
    [owner, validator, delegator] = await ethers.getSigners();

    const Validator = await ethers.getContractFactory("NovaNetValidator");
    validatorContract = await Validator.deploy();
    await validatorContract.deployed();

    const Delegator = await ethers.getContractFactory("DelegatorContract");
    delegatorContract = await Delegator.deploy(validatorContract.address);
    await delegatorContract.deployed();
  });

  it("should allow delegation", async function () {
    await delegatorContract.connect(delegator).delegateStake(validator.address, 100);
    const delegation = await delegatorContract.delegations(delegator.address);
    expect(delegation.amount).to.equal(100);
  });

  it("should allow claiming rewards", async function () {
    await delegatorContract.connect(delegator).delegateStake(validator.address, 100);
    await delegatorContract.connect(delegator).claimRewards();
  });
});
