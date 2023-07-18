// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";

contract Dummy { }

contract Target {
    address public caller;

    function setCaller(address addr) public {
        caller = addr;
    }

    function recordCaller() public {
        caller = msg.sender;
    }
}

contract Ext is Test {
    function prank(address user) public {
        vm.prank(user);
    }
}

contract PrankSetUpTest is Test {
    Target target;

    function setUp() public {
        target = new Target();
        vm.prank(address(target)); // prank is reset after setUp()
    }

    function checkPrank(address user) public {
        vm.prank(user);
        target.recordCaller();
        assert(target.caller() == user);
    }
}

contract PrankTest is Test {
    Target target;
    Ext ext;
    Dummy dummy;

    function setUp() public {
        target = new Target();
        ext = new Ext();
    }

    function prank(address user) public {
        vm.prank(user);
    }

    function checkPrank(address user) public {
        vm.prank(user);
        target.recordCaller();
        assert(target.caller() == user);

        target.recordCaller();
        assert(target.caller() == address(this));
    }

    function checkStartPrank(address user) public {
        vm.startPrank(user);

        target.recordCaller();
        assert(target.caller() == user);

        target.setCaller(address(this));
        assert(target.caller() == address(this));

        target.recordCaller();
        assert(target.caller() == user);

        vm.stopPrank();

        target.recordCaller();
        assert(target.caller() == address(this));
    }

    function checkPrankInternal(address user) public {
        prank(user); // indirect prank
        target.recordCaller();
        assert(target.caller() == user);
    }

    function checkPrankExternal(address user) public {
        ext.prank(user); // prank isn't propagated beyond the vm boundry
        target.recordCaller();
        assert(target.caller() == address(this));
    }

    function checkPrankExternalSelf(address user) public {
        this.prank(user); // prank isn't propagated beyond the vm boundry
        target.recordCaller();
        assert(target.caller() == address(this));
    }

    function checkPrankNew(address user) public {
        vm.prank(user);
        dummy = new Dummy(); // contract creation also consumes prank
        vm.prank(user);
        target.recordCaller();
        assert(target.caller() == user);
    }

    function checkPrankReset1(address user) public {
    //  vm.prank(address(target)); // overwriting active prank is not allowed
        vm.prank(user);
        target.recordCaller();
        assert(target.caller() == user);
    }

    function checkPrankReset2(address user) public {
    //  vm.prank(address(target)); // overwriting active prank is not allowed
        vm.startPrank(user);
        target.recordCaller();
        assert(target.caller() == user);
    }

    function checkStopPrank1(address user) public {
        vm.prank(user);
        vm.stopPrank(); // stopPrank can be used to disable both startPrank() and prank()
        target.recordCaller();
        assert(target.caller() == address(this));
    }

    function checkStopPrank2() public {
        vm.stopPrank(); // stopPrank is allowed even when no active prank exists!
        target.recordCaller();
        assert(target.caller() == address(this));
    }
}
