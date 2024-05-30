// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "./interfaces/IUniswapV3Factory.sol";
import "./NoDelegateCall.sol";

contract UniswapV3Factory is IUniswapV3Factory, NoDelegateCall {
    //  uniswapFactory 合约所有者地址
    address public override owner;

    // 存储费率等级和 tickSpace，tickSpace 越高 越精确 费率越高
    mapping(uint24 => int24) public override feeAmountTickSpacing;

    // 存储 Pair 地址  Pair = getPool[token0][token1][fee]
    mapping(address => mapping(address => mapping(uint24 => address)))
        public
        override getPool;

    constructor() {
        // 设置 Factory owner
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);

        feeAmountTickSpacing[500] = 10;
        emit FeeAmountEnabled(500, 10);
        feeAmountTickSpacing[3000] = 60;
        emit FeeAmountEnabled(3000, 60);
        feeAmountTickSpacing[10000] = 200;
        emit FeeAmountEnabled(10000, 200);
    }

    // 创建池子， 类似 UniswapV2 createPair 概念
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external overide noDelegateCall returns (address pool) {
        require(tokenA != tokenB);
        // 排序，确保token顺序固定，getPool[token0][token1][fee] 映射的顺序
        (address token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0));
        int24 tickSpacing = feeAmountTickSpacing[fee];
        require(tickSpacing != 0);
        // 确保不存在池子,后续可以创建
        require(getPool[token0][token1][fee] == address(0));
        // 部署，使用 Create2 操作码传参，确定 pool 合约部署地址并返回，
        pool = deploy(address(this), token0, token1, fee, tickSpacing);
        // 双向存储 pool 地址
        getPool[token0][token1][fee] = pool;
        getPool[token1][token0][fee] = pool;
        emit PoolCreated(token0, token1, fee, tickSpacing, pool)l
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner);
        owner = _owner;
        emit OwnerChanged(owner, _owner);
    }

    function enableFeeAmount(uint24 fee, int24 tickSpacing) public override {
        require(msg.sender == owner);
        require(fee < 1000000);
        
        require(tickSpacing > 0 && tickSpacing < 16384);
        require(feeAmountTickSpacing[fee] == 0);

        feeAmountTickSpacing[fee] = tickSpacing;
        emit FeeAmountEnabled(fee, tickSpacing);
    }
}
