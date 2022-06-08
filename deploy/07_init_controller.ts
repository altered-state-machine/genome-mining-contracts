import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { getNamedAccounts, deployments } = hre;
  const { deploy, execute } = deployments;
  const { deployer } = await getNamedAccounts();

  const astoToken = await hre.deployments.get("ASTOToken");
  const lpToken = await hre.deployments.get("LPToken");
  const astoTokenAddress = "0xaeF0327c6726f6B44b56Bc7036cD4710f632b52E";
  const lpTokenAddress = "0xaeF0327c6726f6B44b56Bc7036cD4710f632b52E";
  const astoStorage = await hre.deployments.get("ASTOStorage");
  const lpStorage = await hre.deployments.get("LPStorage");
  const energyStorage = await hre.deployments.get("EnergyStorage");
  const converter = await hre.deployments.get("Converter");
  const staking = await hre.deployments.get("Staking");
  const controller = await hre.deployments.get("Controller");

  console.log({ deployer }, "Controller:", controller.address);

  const res = await execute(
    "Controller",
    { from: deployer },
    "init",
    astoToken.address,
    astoStorage.address,
    lpToken.address,
    lpStorage.address,
    staking.address,
    converter.address,
    energyStorage.address
  );

  console.log("Adding period to ConverterTest contract...");
  // update the timestamp and multipliers based on your requirements
  const startTime = 1654560000; // June 7, 2022 00:00:00 UTC
  const endTime = 1659744000; // August 6, 2022 12:00:00 UTC
  const astoMultiplier = ethers.utils.parseEther("1");
  const lpMultiplier = ethers.utils.parseEther("1.36");
  await execute("Converter", { from: deployer }, "addPeriod", [
    startTime.toString(),
    endTime.toString(),
    astoMultiplier,
    lpMultiplier,
  ]);
};

func.tags = ["ControllerInit"];

func.dependencies = [
  "ASTOStorage",
  "LPStorage",
  "Staking",
  "StakingStorage",
  "EnergyStorage",
  "Converter",
  "Controller",
];

export default func;
