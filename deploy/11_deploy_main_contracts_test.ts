import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { getNamedAccounts, deployments } = hre;
  const { deploy, execute } = deployments;
  const { deployer } = await getNamedAccounts();

  // TODO use separate deploy scripts for each contract
  const ASTOTokenTest = await hre.deployments.get("ASTOTokenTest");

  const lpTokenTest = await deploy("LPTokenTest", {
    from: deployer,
    args: [],
    log: true,
  });

  const controller = await deploy("ControllerTest", {
    from: deployer,
    args: [deployer],
    log: true,
  });

  const astoStorage = await deploy("ASTOStakingStorageTest", {
    from: deployer,
    contract: "StakingStorageTest",
    args: [controller.address],
    log: true,
  });
  const lpStorage = await deploy("LPStakingStorageTest", {
    from: deployer,
    contract: "StakingStorageTest",
    args: [controller.address],
    log: true,
  });

  const staking = await deploy("Staking", {
    from: deployer,
    args: [controller.address],
    log: true,
  });

  const energyStorage = await deploy("EnergyStorage", {
    from: deployer,
    args: [controller.address],
    log: true,
  });
  const energyConverter = await deploy("ConverterTest", {
    from: deployer,
    args: [controller.address],
    log: true,
  });

  // TODO check if not initialized
  console.log("Initializing contracts...");
  await execute(
    "ControllerTest",
    { from: deployer },
    "init",
    ASTOTokenTest.address,
    astoStorage.address,
    lpTokenTest.address,
    lpStorage.address,
    staking.address,
    energyConverter.address,
    energyStorage.address
  );

  console.log("Adding period to ConverterTest contract...");
  const startTime = 1654560000; // June 7, 2022 00:00:00 UTC
  const endTime = 1659744000; // August 6, 2022 12:00:00 UTC
  const astoMultiplier = ethers.utils.parseEther("1");
  const lpMultiplier = ethers.utils.parseEther("1.36");
  await execute("ConverterTest", { from: deployer }, "addPeriod", [
    startTime.toString(),
    endTime.toString(),
    astoMultiplier,
    lpMultiplier,
  ]);
};

func.tags = ["ASTOEnergyContractsTest"];

export default func;
