// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./SafeMath.sol";
import "./provableAPI.sol";

contract LeaseGenerator is usingProvable {
    using SafeMath for uint256;

    address payable landlordAddress;
    address payable tenantAddress;

    uint256 ETHUSD;
    uint256 tenantPayment;
    uint256 leaseBalanceWei;

    enum State {
        payingLeaseDeposit,
        payingLease,
        collectingLeaseDeposit,
        reclaimingLeaseDeposit,
        idle
    }

    State workingState;

    struct Lease {
        uint8 numberOfMonths;
        uint8 monthsPaid;
        uint16 monthlyAmountUsd;
        uint16 leaseDepositUsd;
        uint32 leasePaymentWindowSeconds;
        uint64 leasePaymentWindowEnd;
        uint64 depositPaymentWindowEnd;
        bool leaseDepositPaid;
        bool leaseFullyPaid;
    }

    mapping(bytes32 => bool) validIds;
    mapping(address => Lease) tenantLease;

    modifier onlyLandlord() {
        require(
            msg.sender == landlordAddress,
            "Must be the landlord to create a lease"
        );
        _;
    }

    event leaseCreated(
        uint8 numberOfMonths,
        uint8 monthsPaid,
        uint16 monthlyAmountUsd,
        uint16 leaseDepositUsd,
        uint32 leasePaymentWindowSeconds,
        bool leaseDepositPaid,
        bool leaseFullyPaid
    );

    event leaseDepositPaid(address tenantAddress, uint256 amountSentUsd);

    event leasePaymentPaid(address tenantAddress, uint256 amountSentUsd);

    event leaseDepositCollected(address tenantAddress, uint256 amountCollected);

    event leaseDepositReclaimed(address tenantAddress, uint256 amountReclaimed);

    event leaseFullyPaid(
        address tenantAddress,
        uint256 numberOfmonths,
        uint256 monthsPaid
    );

    event fundsWithdrawn(uint256 transferAmount, uint256 leaseBalanceWei);
}
