import { ethers } from "ethers";
import abiJson from "../build/contracts/MyToken.json"


// https://docs.ethers.io/v5/api/utils/abi/coder/
const abi = abiJson.abi
const iface = new ethers.utils.Interface(abi)

const initializeData = iface.encodeFunctionData("initialize")
console.log(initializeData)
console.log(iface.getSighash("initialize"))
const abiCoder = new ethers.utils.AbiCoder()
const verifyArgs = abiCoder.encode(["address", "bytes"], ["0x2cc56Dfaf435FB9aCFc0E88C691442eC4618cCA4", initializeData])
console.log("verifyArgs=", verifyArgs)
