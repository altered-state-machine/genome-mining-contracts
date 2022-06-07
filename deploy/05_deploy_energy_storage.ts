import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { getNamedAccounts, deployments } = hre;
  const { deploy } = deployments;
  const { deployer, agent } = await getNamedAccounts();

  const controller = await hre.deployments.get("Controller");

  const energyStorage = await deploy("EnergyStorage", {
    from: deployer,
    args: [controller.address],
    log: true,
  });
};

func.tags = ["EnergyStorage"];
func.dependencies = ["Controller"]

export default func;
