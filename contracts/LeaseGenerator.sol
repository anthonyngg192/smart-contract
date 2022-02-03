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

    constructor() public payable {
        landlordAddress = msg.sender;
        provable_setCustomGasPrice(100000000000);
        OAR = OracleAddrResolverI(0xB7D2d92e74447535088A32AD65d459E97f692222);
    }

    function fetchUsdRate() internal {
        require(
            provable_getPrice("URL") < address(this).balance,
            "Not enough Ether in contract, please add more"
        );
        bytes32 queryId = provable_query(
            "URL",
            "json(https://api.pro.coinbase.com/products/ETH-USD/ticker).price"
        );
        validIds[queryId] = true;
    }

    function __callback(bytes32 myId, string memory result) public {
        require(
            validIds[myId],
            "Provable query IDs do not match, no valid call was made to provable_query()"
        );
        require(
            msg.sender == provable_cbAddress(),
            "Calling address does match usingProvable contract address "
        );
        validIds[myId] = false;
        ETHUSD = parseInt(result);

        if (workingState == State.payingLeaseDeposit) {
            _payLeaseDeposit();
        } else if (workingState == State.payingLease) {
            _payLease();
        } else if (workingState == State.collectingLeaseDeposit) {
            _collectLeaseDeposit();
        } else if (workingState == State.reclaimingLeaseDeposit) {
            _reclaimLeaseDeposit();
        }
    }
}
