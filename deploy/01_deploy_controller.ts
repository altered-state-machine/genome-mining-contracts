import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import { ethers } from 'hardhat'

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { getNamedAccounts, deployments } = hre
  const { deploy } = deployments
  const { deployer, agent } = await getNamedAccounts()

  const controller = await deploy('Controller', {
    from: deployer,
    args: [deployer],
    log: true
  })
}


func.tags = ['Controller']

export default func
