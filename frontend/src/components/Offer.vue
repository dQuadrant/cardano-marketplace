<script setup lang="ts">
import workerJsonUrl from "ace-builds/src-noconflict/mode-json";
import type { CIP30Instace, CIP30Provider } from "@/types";
import { Buffer } from "buffer";
import { listMarket, getAssetDetail, getDatum, listOffer } from "@/scripts/blockfrost";
import {
  decodeAssetName,
  listProviders,
  callKuberAndSubmit,
  transformNftImageUrl,
  renderLovelace,
} from "@/scripts/wallet";
import * as database from "@/scripts/database";
import { market, offerScript } from "@/config";
import {
  Address,
  BaseAddress,
  Ed25519KeyHash,
  StakeCredential,
} from "@emurgo/cardano-serialization-lib-asmjs";
import { walletAction } from "@/scripts/sotre";
</script>

<template>
  <div class="container relative">
    <div class="ml-2">
      <div class="left-3">
        <div>
          <button
            type="button"
            @click="showOfferForm = !showOfferForm"
            class="text-blue-500"
          >
            Create Offer
          </button>
        </div>
      </div>
      <div v-show="showOfferForm" class="w-full sm:w-1/2 md:w-1/4">
        <form id="offer-form" name="offer-form" class="fade ani">
          <input
            name="policyId"
            :value="offerForm.policyId"
            class="w-full mb-2 rounded text-gray-800 py-2 px-3 border-2 border-gray-200 focus:outline-2 focus:outline-indigo-500"
            placeholder="Policy Id"
            maxlength="64"
          />
          <input
            name="tokenName"
            :value="offerForm.tokenName"
            class="w-full mb-2 rounded text-gray-800 py-2 px-3 border-2 border-gray-200 focus:outline-2 focus:outline-indigo-500"
            placeholder="Asset Name (Hex or utf-8)"
            maxlength="64"
          />
          <input
            name="offer"
            :value="offerForm.offer"
            class="w-full mb-2 rounded text-gray-800 py-2 px-3 border-2 border-gray-200 focus:outline-2 focus:outline-indigo-500"
            placeholder="Offer price (Ada)"
            maxlength="64"
          />
        </form>
        <div class="flex w-full justify-between gap-4">
          <button
            type="button"
            @click="createOffer"
            class="w-2/3 border-2 border-indigo-500 cursor-pointer hover:bg-indigo-500 hover:text-white hover:border-indigo-600 active:ring-indigo-700 active:ring-offset-2 active:ring-2 rounded-xl p-2 text-center text-indigo-500"
          >
            Create Offer
          </button>
          <button
            type="button"
            @click="cancelOffer"
            class="w-1/3 border-2 border-red-500 cursor-pointer hover:bg-red-500 hover:text-white hover:border-red-600 active:ring-red-700 active:ring-offset-2 active:ring-2 rounded-xl p-2 text-center text-red-500"
          >
            Cancel
          </button>
        </div>
      </div>
      <div v-if="utxos.length == 0" class="text-gray-400 font-semibold text-center my-5">
        {{ message }}
      </div>
      <div v-for="utxo in utxos" :key="utxo.id" class="p-2 flex">
        <img
          :alt="utxo.assetName + '_img'"
          class="inline-block h-32 w-32 mr-4 border-red-300 border-2"
          :src="utxo.detail._imageUrl"
        />
        <div class="flex flex-col justify-between pb-2">
          <div>
            <div v-if="utxo.detail._name">
              <a :href="'https://testnet.cardanoscan.io/token/' + utxo.nft"> &#x29c9; </a>

              <span class="text-blue-900 text-xl font-extrabol">
                {{ utxo.detail._name }}
              </span>
              <span v-if="utxo.detail?.onchain_metadata?.artist">
                <span class="text-gray-400 text-xs">
                  &nbsp; by {{ utxo.detail.onchain_metadata.artist }}</span
                >
              </span>
            </div>

            <div v-else class="text-blue-700 font-extrabold">
              {{ utxo.policy.substring(0, 8) }}...{{ utxo.assetName }}
            </div>

            <div v-if="utxo.detail?.onchain_metadata">
              <div v-if="utxo.detail.onchain_metadata.description" class="text-gray-500">
                {{ mapDescription(utxo.detail.onchain_metadata.description) }}
              </div>

              <div v-if="utxo.detail.onchain_metadata.copyright" class="text-gray-500">
                Copyright:
                {{ utxo.detail.onchain_metadata.copyright }}
              </div>
            </div>
          </div>
          <div>
            <div class="py-2 px-1">
              <span class="text-gray-400 font-semibold">Offer </span> :
              {{ renderLovelace(utxo?.amount[0].quantity) }} Ada
            </div>
            <button
              @click="acceptOffer(utxo)"
              class="bg-transparent hover:bg-blue-300 text-blue-700 font-semibold hover:text-white py-1 px-3 border border-blue-500 hover:border-blue-200 rounded"
            >
              Accept Offer
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
    const _this = this;
    let db;
    return database
      .openDB()
      .then((dbInstance) => {
        _this.hasIndexDb = db;
        db = dbInstance;
      })
      .finally(() => {
        return listOffer()
          .then((response) => {
            console.log("All  Offer utxos", response);
            const readHandle = db && database.getReadHandle(db);
            return Promise.allSettled(
              response.map(async (utxo, i) => {
                const datum:any = await database
                  .getUtxo(readHandle, utxo.id)
                  .catch((e) => {
                    console.warn("Not found in db", utxo.id = utxo.tx_hash + "#" + utxo.tx_index);
                    return getDatum(utxo.data_hash).then(v=>v.json_value)
                      .catch((e) => {
                        if (e.status_code && e.status_code == 404) {
                          const data = {
                            utxo: response.id,
                            status_code: e.status_code,
                          };
                          return data;
                        } else {
                          console.error(e);
                          throw e;
                        }
                      });
                  });
                
                  if(datum.status_code){
                    return;
                  }
                  if(!(datum.fields && datum.fields.length ==3 && datum.fields[2].bytes && datum.fields[1].bytes)){
                      console.warn("Invalid datum for utxo ", utxo.id , datum) 
                      return;
                  }
                  const assetname =datum.fields[1].bytes;
                  const policy = datum.fields[2].bytes;
                  return getAssetDetail(policy + assetname)
                  .then((nftDetail: any) => {
                        if (nftDetail.onchain_metadata) {
                          if (nftDetail.onchain_metadata) {
                            if (nftDetail.onchain_metadata.name) {
                              nftDetail._name = nftDetail.onchain_metadata.name;
                            }
                            if (nftDetail.onchain_metadata.image) {
                              nftDetail._imageUrl = transformNftImageUrl(
                                nftDetail.onchain_metadata.image
                              );
                            }
                          }
                        }
                        nftDetail.utxo = utxo.id = utxo.tx_hash + "#" + utxo.tx_index;
                        nftDetail.datum = datum;
                        return nftDetail;
                      }).catch(e=>{
                        if(e.status_code==404){
                          console.warn("Nft not found",policy+'.'+assetname)
                        }else{
                          throw e
                        }
                      })
              })
            ).then((x: any) => {
              const lookup = {};
              x.filter((v) => v.value && v.value.datum).forEach((x) => {
                lookup[x.value.utxo] = x.value;
              });
              response.forEach((v) => (v.detail = lookup[v.id]));

              const validUtxos = response.filter((v) => v.detail );
              console.log("Valid  offers", validUtxos);
              this.utxos = validUtxos;
              if (validUtxos.length == 0) {
                this.message = "Offers is empty";
              }
            });
          })
          .catch((e) => {
            if (e.status_code == 404) {
              this.message = "Offers is empty";
            } else {
              alert(e.message);
            }
          });
      });
  },
  computed: {},
  data() {
    return {
      showOfferForm: false,
      message: "Loading ...",
      hasIndexDb: false,
      utxos: [],
      addSelections: true,
      interval: 0,
      timeout: 0,
      offerForm: {
        policyId: null,
        tokenName: null,
        offer: null,
      },
    };
  },
  methods: {
    mapDescription(desc: Array<string> | string) {
      return Array.isArray(desc) ? desc.join("") : desc;
    },
    async createOffer() {
      const data: any = {};
      Array.from(document.forms["offer-form"].elements).forEach((v: HTMLInputElement) => {
        if (v.tagName == "INPUT") data[v.name] = v.value;
      });
      walletAction.callback = async (provider: CIP30Instace) => {
        const addresses = await provider.getUsedAddresses();
        const userAddr = BaseAddress.from_address(
          Address.from_bytes(Uint8Array.from(Buffer.from(addresses[0], "hex")))
        );
        const userPkh = Buffer.from(
          userAddr.payment_cred().to_keyhash().to_bytes()
        ).toString("hex");
        const userStakeKey = Buffer.from(
          userAddr.stake_cred().to_keyhash().to_bytes()
        ).toString("hex");
        let inputTokenName = data.tokenName
        const unHex = Buffer.from(data.tokenName, "hex").toString("hex") 
        if(unHex.length != inputTokenName.length){
          inputTokenName = Buffer.from(data.tokenName, "utf-8").toString("hex")
        }

        const request : any = {
          selections: await provider.getUtxos(),
          collaterals: provider.getCollateral
            ? await provider.getCollateral().catch((_) => [])
            : [],

          outputs: [
            {
              address: offerScript.address,
              value: Math.round(parseFloat(data.offer)) * 1e6,
              datum: {
              "fields":[
                {
                  "fields":[
                    {"fields":[{"bytes":`${userPkh}`}],"constructor":0},
                    {"fields":[{ "bytes": `${userStakeKey}` }],"constructor":1}
                    ],
                  "constructor":0
                },
                {"bytes": inputTokenName},
                {"bytes":data.policyId}
              ],
              "constructor":0
              },
            },
          ],
        };
        return callKuberAndSubmit(provider, JSON.stringify(request));
      };
      walletAction.enable = true;
    },
    async acceptOffer(utxo) {
      
      console.log(utxo)
      const datum = utxo.detail.datum
      const cost = datum.fields[1].int;
      const offererPkhHex =datum.fields[0].fields[0].fields[0].bytes
      const offererStakeKeyHex = datum.fields[0].fields[1].fields[0].bytes
      const vkey = StakeCredential.from_keyhash(Ed25519KeyHash.from_bytes(Buffer.from(offererPkhHex, "hex")))
      const stakeKey = StakeCredential.from_keyhash(Ed25519KeyHash.from_bytes(Buffer.from(offererStakeKeyHex, "hex")))
      const offererAddress= BaseAddress.new(0,vkey,stakeKey)
      console.log("Offerer Address ",offererAddress.to_address().to_bech32())

      walletAction.callback=async (provider : CIP30Instace)=>{
          const request = {
        selections: await provider.getUtxos(),
        inputs: [
          {
            address: offerScript.address,
            utxo: {
              "hash":utxo.tx_hash,
              "index": utxo.tx_index
            },
            script: offerScript.script,
            // value: `2A + ${nft.policy}.${nft.asset_name}`,
            datum: datum,
            redeemer: { fields: [], constructor: 0 },
          },
        ],
        outputs: [
          {
            address: offererAddress.to_address().to_bech32("addr_test"),
            value: `2A + ${ datum.fields[2].bytes}.${ datum.fields[1].bytes}`
          },
          {
            address: offerScript.operatorAddress,
            value: offerScript.fee
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
  },
};
</script>
<style>
@import "../assets/base.css";
</style>
