import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { getNamedAccounts, deployments } = hre;
  const { deploy, execute } = deployments;
  const { deployer, agent } = await getNamedAccounts();


  const astoToken = await hre.deployments.get("ASTOToken");
  const lpToken = await hre.deployments.get("LPToken");
  const astoStorage = await hre.deployments.get("ASTOStorage");
  const lpStorage = await hre.deployments.get("LPStorage");
  const energyStorage = await hre.deployments.get("EnergyStorage");
  const converter = await hre.deployments.get("Converter");
  const staking = await hre.deployments.get("Staking");
  const controller = await hre.deployments.get("Controller");



  console.log({ deployer, agent}, "Controller:", controller.address);


  const res = await execute(
    "Controller",
    { from: deployer, gasLimit: 10000000 },
    "init",
      astoTokenAddress, 
      astoStorage.address, 
      lpTokenAddress, 
      lpStorage.address, 
      staking.address, 
      converter.address, 
      energyStorage.address
  );

  // console.log("Adding period to ConverterTest contract...");
  // const startTime = 1654560000; // June 7, 2022 00:00:00 UTC
  // const endTime = 1659744000; // August 6, 2022 12:00:00 UTC
  // const astoMultiplier = ethers.utils.parseEther("1");
  // const lpMultiplier = ethers.utils.parseEther("1.36");
  // await run("ConverterTest", { from: deployer }, "addPeriod", [
  //   startTime.toString(),
  //   endTime.toString(),
  //   astoMultiplier,
  //   lpMultiplier,
  // ]);




  // await energyConverter.addPeriods()
};

func.tags = ["ControllerInit"];

func.dependencies = [
  "ASTOStorage", 
  "LPStorage", 
  "Staking", 
  "StakingStorage", 
  "EnergyStorage", 
  "Converter", 
  "Controller"
];

export default func;
