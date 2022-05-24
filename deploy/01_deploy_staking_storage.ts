import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const multisig = '0x001';
const astoToken = '0xb5c8a0389aaac2def49f1746448499737ff57385';

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { getNamedAccounts, deployments } = hre;
  const { deploy } = deployments;
  const { deployer, agent, finance } = await getNamedAccounts();
  await deploy("StakingStorage", {
    from: deployer,
    args: [agent, astoToken],
    log: true,
  });
};

func.tags = ["StakingStorage"];

export default func;
