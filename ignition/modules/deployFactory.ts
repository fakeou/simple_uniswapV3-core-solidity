import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LockModule = buildModule("UniswapV3Factory", (m) => {
  const factory = m.contract("UniswapV3Factory");
  console.log(factory);

  return { factory };
});

export default LockModule;
