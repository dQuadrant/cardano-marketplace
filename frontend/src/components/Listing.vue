<script setup lang="ts">

import type {CIP30Instace, CIP30Provider} from "@/types";
import {Buffer} from "buffer";
import {listMarket, getAssetDetail, getDatum} from "@/scripts/blockfrost";
import {decodeAssetName, listProviders, callKuberAndSubmit, transformNftImageUrl, renderLovelace} from "@/scripts/wallet";
import * as database from "@/scripts/database"
import {market} from "@/config";
import {Address, BaseAddress, Ed25519KeyHash, StakeCredential} from "@emurgo/cardano-serialization-lib-asmjs";
import {walletAction} from "@/scripts/sotre"
</script>

<template>
  <div>
    <div class=" ml-2"> 
      <div v-if="utxos.length==0" class="text-gray-400 font-semibold text-center my-5"> {{message}}</div>
      <div v-for="utxo in utxos" :key="utxo.id" class="p-2 flex">
        <img :alt="utxo.assetName +'_img'" class="inline-block h-32 w-32  mr-4 border-red-300 border-2" :src="utxo.detail._imageUrl"/>
        <div class="flex flex-col justify-between pb-2">
          <div>

            <div v-if="utxo.detail._name">
              <a :href="'https://testnet.cardanoscan.io/token/'+utxo.nft"> &#x29c9; </a>

              <span class="text-blue-900 text-xl font-extrabol"> {{ utxo.detail._name }}  </span>
              <span v-if="utxo.detail?.onchain_metadata?.artist"> <span
                  class="text-gray-400 text-xs"> &nbsp; by {{ utxo.detail.onchain_metadata.artist }}</span>  </span>
            </div>

            <div v-else class="text-blue-700 font-extrabold"> {{ utxo.policy.substring(0, 8) }}...{{
                utxo.assetName
              }}
            </div>

            <div v-if="utxo.detail?.onchain_metadata">
              <div v-if="utxo.detail.onchain_metadata.description" class="text-gray-500">
                {{ mapDescription(utxo.detail.onchain_metadata.description) }}
              </div>

              <div v-if="utxo.detail.onchain_metadata.copyright" class="text-gray-500"> Copyright:
                {{ utxo.detail.onchain_metadata.copyright }}
              </div>
            </div>
          </div>
          <div>
            <button  @click="buy(utxo)"
                class="bg-transparent hover:bg-blue-300 text-blue-700 font-semibold hover:text-white py-2 px-4 border border-blue-500 hover:border-blue-200 rounded">
              {{
                renderLovelace(utxo.detail?.datum?.fields[1]?.int)
              }} Ada (Buy)
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script lang="ts">
export default {
  created() {
    const _this = this
    let db;
    return database.openDB().then(dbInstance => {
      _this.hasIndexDb = db
      db = dbInstance
    }).finally(() => {
      return listMarket().then(response => {
        console.log("All  Marketet utxos", response)
        let utxos: Array<any> = response.filter(utxo => {
          const amount_ = utxo.amount.filter(x => x.unit !== 'lovelace')
          if (amount_.length == 1 && amount_[0].quantity == 1) {
            const nft: string = amount_[0].unit
            const policy = nft.substring(0, 56)
            const asset = nft.substring(56)
            const assetUtf8 = decodeAssetName(asset)
            utxo.policy = policy
            utxo.assetName = assetUtf8
            utxo.detail = {}
            utxo.nft = nft
            utxo.id = utxo.tx_hash + '#' + utxo.tx_index
            return true
          } else {
            return false
          }
        })
        const readHandle = db && database.getReadHandle(db)
        return Promise.allSettled(utxos.map((utxo, i) => {
          return database.getUtxo(readHandle, utxo.id).then(v => {
            return v
          }).catch(e => {
            console.log("Error returned from db", e)
            return getDatum(utxo.data_hash)
                .then(dataResponse => {
                      utxo.datum = dataResponse.json_value
                      return getAssetDetail(utxo.nft)
                    }
                ).then((nftDetail: any) => {
                  if (nftDetail.onchain_metadata) {
                    if (nftDetail.onchain_metadata) {
                      if (nftDetail.onchain_metadata.name) {
                        nftDetail._name = nftDetail.onchain_metadata.name
                      }
                      if (nftDetail.onchain_metadata.image) {
                        nftDetail._imageUrl =transformNftImageUrl(nftDetail.onchain_metadata.image)
                      }
                    }
                  }
                  nftDetail.utxo = utxo.id
                  nftDetail.datum = utxo.datum
                  setTimeout(() => {
                    database.saveUtxos(db, [nftDetail])
                  })
                  return nftDetail
                }).catch(e => {
                  if (e.status_code && e.status_code == 404) {
                    const data = {
                      utxo: utxo.id,
                      status_code: e.status_code
                    }
                    database.saveUtxos(db, [data])
                    return data
                  } else {
                    console.error(e)
                    throw e
                  }
                })
          })
        })).then((x: Array<any>) => {
              const lookup = {}
              x.filter(v => v.value && v.value.datum).forEach(
                  x => {
                    lookup[x.value.utxo] = x.value
                  })
              utxos.forEach(v => v.detail = lookup[v.id])
              const validUtxos = utxos.filter(v => v.detail)
              console.log("Valid market utxos", validUtxos)
              this.utxos = validUtxos
              if(validUtxos.length == 0){
                this.message="Marketplace is empty"
              }
            }
        )
      }).catch((e)=>{
        if(e.status_code == 404){
            this.message="Marketplace is empty"
        }else{
          alert(e.message)
        }
      })
    })
  },
  computed: {},
  data() {
    const providers: Array<CIP30Provider> = [];

    return {
      message: "Loading ...",
      hasIndexDb: false,
      utxos: [],
      providers: providers,
      addSelections: true,
      interval: 0,
      timeout: 0,
    };
  },
  methods: {
    mapDescription(desc: Array<string> | string) {
      return Array.isArray(desc) ? desc.join('') : desc
    },
    async buy( utxo) {
      console.log(utxo)
      const datum = utxo.detail.datum
      const cost = datum.fields[1].int;
      const sellerPubKeyHashHex =datum.fields[0].fields[0].fields[0].bytes
      const sellerStakeKeyHashHex = datum.fields[0].fields[1].fields[0].fields[0].fields[0].bytes
      const vkey = StakeCredential.from_keyhash(Ed25519KeyHash.from_bytes(Buffer.from(sellerPubKeyHashHex, "hex")))
      const stakeKey = StakeCredential.from_keyhash(Ed25519KeyHash.from_bytes(Buffer.from(sellerStakeKeyHashHex, "hex")))
      const sellerAddr= BaseAddress.new(0,vkey,stakeKey)
      console.log("SellerAddr",sellerAddr.to_address().to_bech32())

      // Create constraints for buying
      walletAction.callback=async (provider : CIP30Instace)=>{
          const request = {
        selections: await provider.getUtxos(),
        inputs: [
          {
            address: market.address,
            utxo: {
              "hash":utxo.tx_hash,
              "index": utxo.tx_index
            },
            script: market.script,
            redeemer: { fields: [], constructor: 0 },
          },
        ],
        outputs: [
          {
            address: sellerAddr.to_address().to_bech32(market.address.startsWith('addr_test')?"addr_test":"addr"),
            value: cost,
            insuffientUtxoAda: "increase"
          }
        ],
      };
      return callKuberAndSubmit(provider,JSON.stringify(request))
      }
      walletAction.enable=true
    },
    save(v: string) {
      localStorage.setItem("editor.content", v);
    },
  }
};
</script>
<style>
@import "../assets/base.css";
</style>
