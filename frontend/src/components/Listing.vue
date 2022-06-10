<script setup lang="ts">
import {VAceEditor} from "vue3-ace-editor";
import ace from "ace-builds";
import workerJsonUrl from "ace-builds/src-noconflict/mode-json";
// @ts-ignore (for some reason ide is giving error on @/ imports)
import type {CIP30Instace, CIP30Provider} from "@/types";
import {Address} from "@emurgo/cardano-serialization-lib-asmjs";
import {Buffer} from "buffer";
import * as _notification from "@dafcoe/vue-notification";
import * as database from "@/scripts/database"
import {listMarket, getAssetDetail, getDatum} from "@/scripts/blockfrost";
import {decodeAssetName, listProviders, callKuberAndSubmit, transformNftImageUrl, renderLovelace} from "@/scripts/wallet";
// @ts-ignore
ace.config.setModuleUrl("ace/mode/json_worker", workerJsonUrl);
</script>

<template>
  <div>
    <vue-notification-list position="top-right"></vue-notification-list>

    <div class=" ml-2">
      <div v-for="utxo in utxos" :key="utxo.id" class="p-2 flex">
        <img :alt="utxo.assetName +'_img'" class="inline-block h-32 w-32  mr-4" :src="utxo.detail._imageUrl"/>
        <div class="flex flex-col justify-between pb-2">
          <div>

            <div v-if="utxo.detail._name">
              <a :href="'https://testnet.cardanoscan.io/token/'+utxo.nft"> &#x29c9; </a>

              <span class="text-blue-900 text-xl font-extrabold"> {{ utxo.detail._name }}  </span>
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
            <button
                class="bg-transparent hover:bg-blue-300 text-blue-700 font-semibold hover:text-white py-2 px-4 border border-blue-500 hover:border-blue-200 rounded">
              {{
                renderLovelace(utxo.detail?.datum?.fields[4]?.int)
              }} Ada (Buy)
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script lang="ts">


const notification = _notification.useNotificationStore();
const parser = /^([a-zA-Z0-9+]+):\/\/(.+)/

export default {
  created() {
    const _this = this
    let db;
    return database.openDB().then(dbInstance => {
      _this.hasIndexDb = db
      db = dbInstance
    }).finally(() => {
      return listMarket().then(response => {
        const _this = this
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
        this.utxos = utxos
        utxos = JSON.parse(JSON.stringify(utxos))
        const readHandle = db && database.getReadHandle(db)
        console.log("providers: ", listProviders());
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
            }
        )
      })
    })
  },
  computed: {},
  data() {
    const providers: Array<CIP30Provider> = [];

    return {
      hasIndexDb: false,
      utxos: [],
      providers: providers,
      addSelections: true,
      editor: null,
      interval: 0,
      timeout: 0,
    };
  },
  methods: {
    mapDescription(desc: Array<string> | string) {
      return Array.isArray(desc) ? desc.join('') : desc
    },
    submitTx(provider: CIP30Provider) {
      const editorContent = this.editor.getValue();
      this.save(editorContent);
      let request;
      try {
        request = JSON.parse(editorContent);
      } catch (e: any) {
        notification.setNotification({
          type: "alert",
          message: e.message,
        });
        return;
      }
      return provider
          .enable()
          .then(async (instance: CIP30Instace) => {
            const collateral = instance.getCollateral ? await instance.getCollateral().catch(() => {
            }) || [] : [];
            if (request.collaterals && typeof request.collaterals.push === "function") {
              collateral.forEach((x) => request.collaterals.push(x));
            } else if (collateral.length) {
              request.collaterals = collateral;
            }
            if (this.addSelections) {
              const availableUtxos = await instance.getUtxos();

              if (request.selections) {
                if (typeof request.selections.push === "function") {
                  availableUtxos.forEach((v) => {
                    request.selections.push(v);
                  });
                }
              } else {
                request.selections = availableUtxos;
              }
              return callKuberAndSubmit(instance, JSON.stringify(request));
            } else {
              return callKuberAndSubmit(instance, JSON.stringify(request));
            }
          })
          .catch((e: any) => {
            console.error("SubmitTx", e);
            notification.setNotification({
              type: "alert",
              message: e.message || "Oopsie, Nobody knows what happened",
            });
          });
    },
    editorInit(v: any) {

    },
    save(v: string) {
      localStorage.setItem("editor.content", v);
    },
  },
  components: {
    VAceEditor,
  },
};
</script>
<style>
@import "../assets/base.css";
</style>
