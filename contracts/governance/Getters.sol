// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Staking } from "./Staking.sol";
import { GovernorRewards } from "../treasury/GovernorRewards.sol";

/**
 * @title Governance Getters
 * @author Railgun Contributors
 * @notice Convenience functions to quickly get data from governance contracts
 */
contract Getters {
  Staking staking;
  GovernorRewards governorRewards;

  /**
   * @notice Sets external contract addresses
   * @param _staking - staking contract
   * @param _governorRewards - governor rewards contract
   */
  constructor(Staking _staking, GovernorRewards _governorRewards) {
    staking = _staking;
    governorRewards = _governorRewards;
  }

  /**
   * @notice Gets all snapshots for account
   * @param _account - account to get snapshots for
   * @return snapshots
   */
  function getAccountSnapshots(address _account)
    external
    view
    returns (Staking.AccountSnapshot[] memory)
  {
    // Get number of snapshots
    uint256 length = staking.accountSnapshotLength(_account);

    // Retrieve snapshots
    Staking.AccountSnapshot[] memory snapshots = new Staking.AccountSnapshot[](length);
    for (uint256 i = 0; i < length; i++) {
      snapshots[i] = staking.accountSnapshot(_account, i);
    }

    // Return
    return snapshots;
  }

  /**
   * @notice Gets all snapshots for globals
   * @return snapshots
   */
  function getGlobalsSnapshots() external view returns (Staking.GlobalsSnapshot[] memory) {
    // Get number of snapshots
    uint256 length = staking.globalsSnapshotLength();

    // Retrieve snapshots
    Staking.GlobalsSnapshot[] memory snapshots = new Staking.GlobalsSnapshot[](length);
    for (uint256 i = 0; i < length; i++) {
      snapshots[i] = staking.globalsSnapshot(i);
    }

    // Return
    return snapshots;
  }

  /**
   * @notice Gets all claimed for account and interval for token
   * @dev this will return a flattened bool array
   * @param _account - account to get claims for
   * @param _token - token to get earned amount for
   * @param _startingInterval - fetch starting interval
   * @param _endingInterval - fetch ending interval
   * @return flattened claims array
   */
  function getEarnedTokensPerInterval(
    address _account,
    IERC20 _token,
    uint256 _startingInterval,
    uint256 _endingInterval
  ) external view returns (uint256[] memory) {
    // Create bitmap array
    uint256 intervalsLength = _endingInterval - _startingInterval + 1;
    uint256[] memory earned = new uint256[](intervalsLength);

    // Loop through each interval
    for (uint256 intervalIter = 0; intervalIter < intervalsLength; intervalIter++) {
      // Calculate hint parameter
      uint256[] memory hintParam = new uint256[](1);
      hintParam[0] = 0;

      // Calculate tokens parameter
      IERC20[] memory tokenParam = new IERC20[](1);
      tokenParam[0] = _token;

      // Get earned amounts for token
      uint256[] memory earnedForInterval = governorRewards.calculateRewards(
        tokenParam,
        _account,
        intervalIter + _startingInterval,
        intervalIter + _startingInterval,
        hintParam,
        true
      );

      // Loop through tokens
      for (uint256 tokenIter = 0; tokenIter < earnedForInterval.length; tokenIter++) {
        // Insert each earned amount into token sub-array
        earned[tokenIter * intervalsLength + intervalIter] = earnedForInterval[tokenIter];
      }
    }

    // Return
    return earned;
  }

  /**
   * @notice Gets all claimed for account and interval for token
   * @dev this will return a flattened bool array
   * @param _account - account to get claims for
   * @param _tokens - tokens to get claims bitmap for
   * @param _startingInterval - fetch starting interval
   * @param _endingInterval - fetch ending interval
   * @return flattened claims array
   */
  function getClaimed(
    address _account,
    IERC20[] calldata _tokens,
    uint256 _startingInterval,
    uint256 _endingInterval
  ) external view returns (bool[] memory) {
    // Create bitmap array
    uint256 intervalsLength = _endingInterval - _startingInterval + 1;
    bool[] memory claimed = new bool[](_tokens.length * intervalsLength);

    // Loop through each token
    for (uint256 tokensIter = 0; tokensIter < _tokens.length; tokensIter++) {
      for (uint256 intervalIter = 0; intervalIter < intervalsLength; intervalIter++) {
        claimed[tokensIter * intervalsLength + intervalIter] = governorRewards.getClaimed(
          _account,
          _tokens[tokensIter],
          intervalIter + _startingInterval
        );
      }
    }

    // Return
    return claimed;
  }
}
