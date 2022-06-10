<script setup lang="ts">

import { Buffer } from "buffer";
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import {decodeAssetName, listProviders, walletValue} from "@/scripts/wallet";
import type {CIP30Provider} from "@/types";
import {getAssetDetail} from "@/scripts/blockfrost";
import {walletState, sellNftState} from "@/scripts/sotre";

import {
  Address,
  AssetName,
  BaseAddress,
  BigNum,
  Ed25519KeyHash,
  EnterpriseAddress,
  hash_auxiliary_data,
  PointerAddress,
  ScriptHash,
  ScriptHashes,
  StakeCredential,
  Transaction,
  TransactionBody,
  TransactionUnspentOutput,
  TransactionWitnessSet,
  Value,
  Vkeywitnesses,
} from '@emurgo/cardano-serialization-lib-asmjs';

</script>

<template>
  <!-- This example requires Tailwind CSS v2.0+ -->
  <TransitionRoot  as="template" :show="walletState">
    <Dialog as="div" class="relative z-10" @close="walletState=false">
      <TransitionChild as="template" enter="ease-in-out duration-300" enter-from="opacity-0" enter-to="opacity-100" leave="ease-in-out duration-300" leave-from="opacity-100" leave-to="opacity-0">
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" />
      </TransitionChild>
      <div class="fixed inset-0 overflow-hidden">
        <div class="absolute inset-0 overflow-hidden">
          <div class="pointer-events-none fixed inset-y-0 right-0 flex max-w-full pl-10">
            <TransitionChild as="template" enter="transform transition ease-in-out duration-300 sm:duration-400" enter-from="translate-x-full" enter-to="translate-x-0" leave="transform transition ease-in-out duration-300 sm:duration-400" leave-from="translate-x-0" leave-to="translate-x-full">
              <DialogPanel class="pointer-events-auto relative w-screen max-w-md">
                <div class="flex h-full flex-col overflow-y-scroll bg-white py-6 shadow-xl">

                  <div  class="px-4 sm:px-6">
                    <div v-if="curProvider" class="flex">
                      <img v-if="curProvider.icon" class="inline-block align-bottom  w-16 h-16 mr-2 " :src="curProvider.icon" />
                      <img v-else class="inline-block align-bottom  w-12 h-12 " src="/cardano.png" />
                      <span class="inline-block w-full ">
                      <div class="text-3xl top-0 pb-1 font-bold text-blue-900">{{curProvider.name}}</div>
                      <div class="align-bottom float-right  text-blue-900">{{renderLovelace(balance.lovelace) }}  Ada</div>
                      <div v-if="walletPkh" class="flex items-center">
                        <div class="text-blue-900 text-md mr-2">{{walletPkh.slice(0,5)}}...{{walletPkh.slice(walletPkh.length-5,)}}</div>
                        <img class="inline-block align-bottom w-5 h-5 cursor-pointer" @click="copyToClipboard()" src="/clipboard.svg" />
                      </div>

                      </span>
                      <button @click="disconnectProvider" class="float-right h-full"> <img class="inline text-red-600 h-4 w-4" src="/disconnect.svg"></button>
                    </div>
                    <DialogTitle v-else class="text-xl font-medium text-blue-900"> {{prompt}} </DialogTitle>
                  </div>
                  <div class="relative mt-6 flex-1 px-4 sm:px-6">
                    <div v-if="selectWallet || !curProvider" class="flex mb-3" v-for="provider in this.providers">
                      <button  @click="activate(provider)" class="flex-grow content-start text-left text-gray-600 text-xl focus:border-b-orange-400 focus:text-blue-700 hover:text-blue-700 focus:border-0 focus:m-0 focus:text-2xl ">
                        <img v-if="provider.icon" class="inline  w-12 h-12 mr-2 " :src="provider.icon" />
                        <img v-else class="inline  w-12 h-12 mr-2" src="/cardano.png" />
                        <span>{{provider.name}}</span>
                      </button>
                    </div>
                    <div v-else>
                      <div v-for="asset in balance.multiAssets">
                        <img  :alt="asset.tokenName +'_img'" v-if="asset.image" :src="asset.image" />
                        <div class="flex justify-between items-start">
                          <span v-if="asset.name" class="text-blue-900 text-xl font-extrabold pb-2 "> {{ asset.name }}  </span>
                          <div v-else class="text-blue-700 font-extrabold" > {{ asset.policy.substring(0, 8) }}...{{
                              asset.tokenName
                            }}
                          </div>
                          <div v-if="!sellNftState" class="text-blue-600 text-lg cursor-pointer " @click="sellNftState=true">Sell</div>
                        </div>

                        <div v-if="sellNftState">
                          <input :value="this.sellAmount" @change="setInputValue" class="w-full mb-2 rounded text-gray-800 py-2 px-3 border-2 border-gray-200 focus:outline-2 focus:outline-indigo-500" placeholder="Enter the amount"/>
                          <div class="flex w-full justify-between gap-4">
                            <div
                                class="w-full border-2 border-indigo-500 cursor-pointer hover:bg-indigo-500 hover:text-white hover:border-indigo-600 active:ring-indigo-700 active:ring-offset-2 active:ring-2 rounded-xl p-2 text-center text-indigo-500"
                                @click="sellNft(curInstance,asset,sellAmount)">Sell</div>
                            <div
                                class="w-full border-2 border-red-500 cursor-pointer hover:bg-red-500 hover:text-white hover:border-red-600 active:ring-red-700 active:ring-offset-2 active:ring-2 rounded-xl p-2 text-center text-red-500"
                                @click="sellNftState=false">Cancel</div>
                        </div>
                        </div>

                      </div>
                    </div>
                  </div>
                </div>
              </DialogPanel>
            </TransitionChild>
          </div>
        </div>
      </div>
    </Dialog>
  </TransitionRoot>
</template>

<script lang="ts">

import {callKuberAndSubmit, transformNftImageUrl} from "@/scripts/wallet";

export default{
  data(){
    return {
      prompt: "Connect Wallet",
      selectWallet : false,
      providers: null,
      curProvider: null,
      walletPkh:null,
      curInstance:null,
      sellAmount:"",
      balance: {
        lovelace:BigInt(0),
        multiAssets:[]
      },
    }
  },
  mounted(){
    let unWatch;
    let handler=  (newVal,oldVal)=>{
        if(newVal && newVal!=oldVal){
          const providers=listProviders()
          console.log("Providers",providers)
          this.providers=providers
          unWatch()
        }
      }
    unWatch=this.$watch( 'walletState',handler)
  },
  methods:{
    copyToClipboard(){
      navigator.clipboard.writeText(this.walletPkh);
    },
    async sellNft(providerInstance,asset) {
      const addresses = await providerInstance.getUsedAddresses()
      const sellerAddr = BaseAddress.from_address(
          Address.from_bytes(Uint8Array.from(Buffer.from(addresses[0], 'hex'))),
      );
      console.log('sellerAddr', sellerAddr);
      const sellerPkh = Buffer.from(sellerAddr.payment_cred().to_keyhash().to_bytes()).toString('hex');
      const sellerStakeKey = Buffer.from(sellerAddr.stake_cred().to_keyhash().to_bytes()).toString('hex')
      const body = {
        "selections": await providerInstance.getUtxos(),
        "outputs": [{
          "address": "addr_test1wrmh4x8uy2hhfp0qlyqv3rdcqv8ar543pwq8tv8tecjlwfcuxj4zt",
          "value": `2A + 1 ${asset.policy}.${asset.tokenName}`,
          "datum": {"fields":[
              {"fields":[
                  {"fields":[{"bytes":`${sellerPkh}`}],"constructor":0},
                  {"fields":[{"bytes":`${sellerStakeKey}`}], "constructor":1}],
                "constructor":0},
              {"int":Math.round(this.sellAmount * 1e6)}],
            "constructor":0}
        }]
      };
      callKuberAndSubmit(providerInstance, JSON.stringify(body));
    },
    async renderPubKeyHash(providerInstance) {
      const addresses = await providerInstance.getUsedAddresses()
      const sellerAddr = BaseAddress.from_address(
          Address.from_bytes(Uint8Array.from(Buffer.from(addresses[0], 'hex'))),
      );
      const sellerPkh = Buffer.from(sellerAddr.payment_cred().to_keyhash().to_bytes()).toString('hex');
      console.log("seller public key hash",typeof sellerPkh);
      return sellerPkh
    },
    setInputValue(event){
      this.sellAmount = event.target.value;
    },
    renderLovelace(l:BigInt){
      return parseFloat(l/BigInt(10000))/100
    },
    activate(provider:CIP30Provider){
      const vm=this
      this.curProvider=provider
      return provider.enable().then(async instance => {
        this.curInstance = instance
        this.walletPkh = await this.renderPubKeyHash(instance)
        return walletValue(instance).then(val => {
          let assetList: Array<any> = []
          for (let policy in val.multiassets) {
            const tokens = val.multiassets[policy]
            for (let token in tokens) {
              console.log(policy, token, tokens[token])
              if (tokens[token] == 1) {
                assetList.push({tokenName: decodeAssetName(token), policy: policy, asset: policy + token})
              }
            }
          }
          this.balance.lovelace = val.lovelace
          this.balance.multiAssets = assetList
          return Promise.all(this.balance.multiAssets.map((v, i) => {
            return getAssetDetail(v.asset).then(asset => {
              v.name = asset.onchain_metadata?.name
              v.image = transformNftImageUrl(asset.onchain_metadata?.image)
            })
          }))

          //this.balance.multiAssets[i]=v
        })
      })
    },
    disconnectProvider(){
      this.balance.lovelace=BigInt(0)
      this.balance.multiAssets=[]
      this.curProvider=null
      this.curInstance=null
    }
  }
}
</script>
