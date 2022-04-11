/* eslint-disable func-names */
/* global describe it beforeEach */
const { ethers } = require('hardhat');
const crypto = require('crypto');
const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');

chai.use(chaiAsPromised);

const { expect } = chai;

const babyjubjub = require('../../helpers/babyjubjub');
const { Note } = require('../../helpers/note');

let railgunLogic;
let primaryAccount;
let treasuryAccount;

describe('Logic/RailgunLogic', () => {
  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [primaryAccount, treasuryAccount] = accounts;

    const PoseidonT3 = await ethers.getContractFactory('PoseidonT3');
    const PoseidonT4 = await ethers.getContractFactory('PoseidonT4');
    const poseidonT3 = await PoseidonT3.deploy();
    const poseidonT4 = await PoseidonT4.deploy();

    const RailgunLogic = await ethers.getContractFactory('RailgunLogic', {
      libraries: {
        PoseidonT3: poseidonT3.address,
        PoseidonT4: poseidonT4.address,
      },
    });
    railgunLogic = await RailgunLogic.deploy();
    await railgunLogic.initializeRailgunLogic(
      treasuryAccount.address,
      25n,
      25n,
      25n,
      primaryAccount.address,
    );
  });

  it('Should hash note preimages', async function () {
    let loops = 10n;

    if (process.env.LONG_TESTS) {
      this.timeout(5 * 60 * 60 * 1000);
      loops = 1000n;
    }

    for (let i = 0n; i < loops; i += 1n) {
      const privateKey = babyjubjub.genRandomPrivateKey();
      const viewingKey = babyjubjub.genRandomPrivateKey();
      const token = ethers.utils.keccak256(
        ethers.BigNumber.from(i * loops).toHexString(),
      ).slice(0, 42);

      const note = new Note(
        privateKey,
        viewingKey,
        i,
        BigInt(ethers.utils.keccak256(ethers.BigNumber.from(i).toHexString())),
        BigInt(`${token}`),
      );

      // eslint-disable-next-line no-await-in-loop
      const contractHash = await railgunLogic.hashCommitment({
        npk: note.notePublicKey,
        token: {
          tokenType: 0,
          tokenAddress: token,
          tokenSubID: 0,
        },
        value: note.value,
      });

      expect(contractHash).to.equal(note.hash);
    }
  });

  it('Should change treasury', async () => {
    expect(await railgunLogic.treasury()).to.equal(treasuryAccount.address);
    await railgunLogic.changeTreasury(ethers.constants.AddressZero);
    expect(await railgunLogic.treasury()).to.equal(ethers.constants.AddressZero);
    await railgunLogic.changeTreasury(primaryAccount.address);
    expect(await railgunLogic.treasury()).to.equal(primaryAccount.address);
  });

  it('Should change fee', async () => {
    expect(await railgunLogic.depositFee()).to.equal(25n);
    expect(await railgunLogic.withdrawFee()).to.equal(25n);
    expect(await railgunLogic.nftFee()).to.equal(25n);

    await railgunLogic.changeFee(5n, 12n, 800n);

    expect(await railgunLogic.depositFee()).to.equal(5n);
    expect(await railgunLogic.withdrawFee()).to.equal(12n);
    expect(await railgunLogic.nftFee()).to.equal(800n);
  });

  it('Should calculate fee', async function () {
    let loops = 10n;

    if (process.env.LONG_TESTS) {
      this.timeout(5 * 60 * 60 * 1000);
      loops = 100n;
    }

    const BASIS_POINTS = 10000n;

    /**
     * Get base and fee amount
     *
     * @param {bigint} amount - Amount to calculate for
     * @param {bigint} isInclusive - Whether the amount passed in is inclusive of the fee
     * @param {bigint} feeBP - Fee basis points
     * @returns {Array<bigint>} base, fee
     */
    function getFee(amount, isInclusive, feeBP) {
      let base;
      let fee;

      if (isInclusive) {
        base = (amount * BASIS_POINTS) / (BASIS_POINTS + feeBP);
        fee = amount - base;
      } else {
        base = amount;
        fee = (amount * feeBP) / BASIS_POINTS;
      }

      return [base, fee];
    }

    for (let feeBP = 0n; feeBP < loops; feeBP += 1n) {
      for (let i = 1n; i <= 120n; i += 1n) {
        const baseExclusive = BigInt(`0x${crypto.randomBytes(Number(i)).toString('hex')}`);
        const feeExclusive = getFee(baseExclusive, false, feeBP)[1];

        // eslint-disable-next-line no-await-in-loop
        const resultExclusive = await railgunLogic.getFee(baseExclusive, false, feeBP);
        expect(resultExclusive[0]).to.equal(baseExclusive);
        expect(resultExclusive[1]).to.equal(feeExclusive);

        const totalInclusive = baseExclusive + feeExclusive;
        const [baseInclusive, feeInclusive] = getFee(totalInclusive, true, feeBP);

        // eslint-disable-next-line no-await-in-loop
        const resultInclusive = await railgunLogic.getFee(totalInclusive, true, feeBP);
        expect(resultInclusive[0]).to.equal(baseInclusive);
        expect(resultInclusive[1]).to.equal(feeInclusive);

        console.log(totalInclusive);
      }
    }
  });
});
