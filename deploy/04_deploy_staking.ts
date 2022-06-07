import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { getNamedAccounts, deployments } = hre;
  const { deploy } = deployments;
  const { deployer, agent } = await getNamedAccounts();

  const controller = await hre.deployments.get("Controller");

  const staking = await deploy("Staking", {
    from: deployer,
    args: [controller.address],
    log: true,
  });
};

func.tags = ["Staking"];
func.dependencies = ["Controller"]

export default func;
