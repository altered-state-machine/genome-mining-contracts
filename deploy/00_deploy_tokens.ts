import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { getNamedAccounts, deployments } = hre;
  const { deploy } = deployments;
  const { deployer, agent, finance } = await getNamedAccounts();

  await deploy("ASTOToken", {
    from: deployer,
    contract: "ASTOTokenTest",
    args: [],
    log: true,
  });
  
  await deploy("LPToken", {
    from: deployer,
    contract: "LPTokenTest",
    args: [],
    log: true,
  });

};

func.tags = ["ASTOToken", "LPToken"];

export default func;
