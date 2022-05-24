import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const multisig = '0x001';
const lpToken = '0xabd4487c5bff63f5d980b6a9f0b88ad28cef5085'; // LP pair contract

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { getNamedAccounts, deployments } = hre;
  const { deploy } = deployments;
  const { deployer, agent, finance } = await getNamedAccounts();
  await deploy("Staking", {
    from: deployer,
    args: [agent, lpToken],
    log: true,
  });
};

func.tags = ["Staking"];

export default func;
