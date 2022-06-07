import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { getNamedAccounts, deployments } = hre;
  const { deploy } = deployments;
  const { deployer, agent } = await getNamedAccounts();

  const controller = await hre.deployments.get("Controller");

  const astoStorage = await deploy("ASTOStorage", {
    from: deployer,
    contract: "StakingStorage",
    args: [controller.address],
    log: true,
  });
};

func.tags = ["ASTOStorage"];
func.dependencies = ["Controller"]

export default func;
