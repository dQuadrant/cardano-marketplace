import { kuberApiUrl } from '@/config';
// @ts-nocheck
import {
    Address, AssetName,
    BaseAddress, BigNum, Ed25519KeyHash, EnterpriseAddress,
    hash_auxiliary_data, MultiAsset, PointerAddress, ScriptHash, ScriptHashes, StakeCredential,
    Transaction,
    TransactionBody, TransactionUnspentOutput, TransactionWitnessSet, Value, Vkeywitnesses
} from '@emurgo/cardano-serialization-lib-asmjs';

declare global {
    interface Window {
      cardano: any;
    }
  }

import type {CIP30Instace} from "@/types";
import {Buffer} from 'buffer'

export async function signAndSubmit(provider: CIP30Instace, _tx: string) {
    let tx:Transaction;
    try {
        const txArray=Uint8Array.from(Buffer.from(_tx, 'hex'))
      tx = Transaction.from_bytes(txArray)
      if (tx.auxiliary_data()) {
        const _txBody = tx.body()
        const txBody = TransactionBody.new(_txBody.inputs(),_txBody.outputs(),_txBody.fee(),_txBody.ttl())
        txBody.set_auxiliary_data_hash(hash_auxiliary_data(tx.auxiliary_data()))
        if(_txBody.collateral())
            txBody.set_collateral(_txBody.collateral())
        if(_txBody.mint())
            txBody.set_mint(_txBody.mint())
        if(_txBody.required_signers()){
            txBody.set_required_signers(_txBody.required_signers())
        }
        if(_txBody.validity_start_interval_bignum()) {
            txBody.set_validity_start_interval_bignum(_txBody.validity_start_interval_bignum())
        }
        if(_txBody.network_id()){
            txBody.set_network_id(_txBody.network_id())
        }
        tx = Transaction.new(txBody, tx.witness_set(), tx.auxiliary_data())
      }
    } catch (e:any) {
      throw new Error("Invalid transaction string :"+ e.message)
    }

    const witnesesRaw = await provider.signTx(
        Buffer.from(tx.to_bytes()).toString('hex'),
        true
    )
    const newWitnesses = TransactionWitnessSet.from_bytes(Buffer.from(witnesesRaw, "hex"))
    const newWitnessSet = TransactionWitnessSet.new();
    if (tx.witness_set().plutus_data())
        newWitnessSet.set_plutus_data(tx.witness_set().plutus_data());
    if (tx.witness_set().plutus_scripts())
        newWitnessSet.set_plutus_scripts(tx.witness_set().plutus_scripts())
    if (tx.witness_set().redeemers())
        newWitnessSet.set_redeemers(tx.witness_set().redeemers())
    if (tx.witness_set().native_scripts())
        newWitnessSet.set_native_scripts(tx.witness_set().native_scripts())
    // add the new witness.
    if (tx.witness_set().vkeys()) {
        const newVkeySet = Vkeywitnesses.new()

        for (let i = 0; i < tx.witness_set().vkeys().len(); i++) {
            newVkeySet.add(tx.witness_set().vkeys().get(i))
        }
        for (let i = 0; i < newWitnesses.vkeys().len(); i++) {
            newVkeySet.add(newWitnesses.vkeys().get(i))
        }
        newWitnessSet.set_vkeys(newVkeySet)

    } else {
        newWitnessSet.set_vkeys(newWitnesses.vkeys())
    }
    tx = Transaction.new(tx.body(), newWitnessSet, tx.auxiliary_data());
    const signedTxString = Buffer.from(tx.to_bytes()).toString('hex')
    // @ts-ignore
    console.log({
        additionWitnessSet: witnesesRaw,
        finalTx: signedTxString
    })
    return provider.submitTx(signedTxString)
}

export function listProviders() {
    if(!window.cardano){
        return []
    }

    const pluginMap = new Map()
    Object.keys(window.cardano).forEach(x => {
        const plugin = window.cardano[x]
        if (plugin.enable && plugin.name) {
            pluginMap.set(plugin.name, plugin)
        }
    })
    const providers = Array.from(pluginMap.values())
    console.log("Provides", providers)
    return providers
}


export async function callKuberAndSubmit(provider: CIP30Instace, data: string) {
    let network = await provider.getNetworkId()
    console.log("Current Network :", network)
    let kuberUrlByNetwork = kuberApiUrl

    return fetch(
        // eslint-disable-next-line max-len
        `${kuberUrlByNetwork}/api/v1/tx`,
        {
            mode: 'cors',
            method: 'POST',
            body: data,
            headers: new Headers({'content-type': 'application/json'}),
        },
    ).catch(e => {
        console.error(`${kuberUrlByNetwork}/api/v1/tx`, e)
        throw Error(`Kubær API call : ` + e.message)
    }).then(res => {
        if (res.status === 200) {
            return res.json()
                .then(json => {
                    console.log(json)
                    return signAndSubmit(provider, json.tx).catch(e => {
                        if (e.info && e.code) {
                            throw Error(`Code : ${e.code} :: \n ${e.info}`)
                        } else throw e
                    });
                })
        } else {
            return res.text().then(txt => {
                let json: any
                try {
                    json = JSON.parse(txt)
                } catch (e) {
                    return Promise.reject(Error(`KubærApi [Status ${res.status}] : ${txt}`)
                    )
                }
                if (json) {
                    return Promise.reject(Error(`KubærApi [Status ${res.status}] : ${json.message ? json.message : txt}`))
                } else {
                    return Promise.reject(Error(`KubærApi [Status ${res.status}] : ${txt}`))
                }
            })
        }
    })
}

export async function calculatePolicyHash(script:any): Promise<string>{
    return fetch(
        // eslint-disable-next-line max-len
        `${kuberApiUrl}/api/v1/scriptPolicy`,
        {
            mode: 'cors',
            method: 'POST',
            body: JSON.stringify(script),
            headers: new Headers({'content-type': 'application/json'}),
        },
    ).catch(e => {
        console.error(`${kuberApiUrl}/api/v1/tx`, e)
        throw Error(`Kubær API call : ` + e.message)
    }).then(res=>{
        if (res.status === 200) {
            return res.text()
        } else {
            return res.text().then(txt => {
                let json: any
                try {
                    json = JSON.parse(txt)
                } catch (e) {
                    return Promise.reject(Error(`KubærApi [Status ${res.status}] : ${txt}`)
                    )
                }
                if (json) {
                    return Promise.reject(Error(`KubærApi [Status ${res.status}] : ${json.message ? json.message : txt}`))
                } else {
                    return Promise.reject(Error(`KubærApi [Status ${res.status}] : ${txt}`))
                }
            })
        }
    })
}

export async function walletValue(provider): Promise<any> {
    const utxos: TransactionUnspentOutput[] = (await provider.getUtxos()).map(u =>
        TransactionUnspentOutput.from_bytes(Buffer.from(u, "hex")),
    );
    const assets: Map<ScriptHash, Map<AssetName, BigNum>> = new Map()
    let adaVal = BigNum.zero()

    utxos.forEach((utxo) => {
        const value: Value = utxo.output()
            .amount();
        adaVal = adaVal.checked_add(value.coin())
        if (value.multiasset()) {
            const multiAssets: ScriptHashes = value.multiasset().keys();
            for (let j = 0; j < multiAssets.len(); j++) {
                const policy: ScriptHash = multiAssets.get(j);
                const policyAssets = value.multiasset().get(policy);
                const assetNames = policyAssets.keys();
                let assetNameMap
                assets.get(policy)
                if (!assetNameMap) {
                    assets.set(policy, assetNameMap = new Map());
                }
                for (let k = 0; k < assetNames.len(); k++) {
                    const policyAsset: AssetName = assetNames.get(k);
                    let quantity = policyAssets.get(policyAsset);
                    const oldQuantity: BigNum = assetNameMap.get(policyAsset)
                    if (oldQuantity) {
                        quantity = oldQuantity.checked_add(quantity)
                    }
                    assetNameMap.set(policyAsset, quantity)
                }
            }
        }
    })
    const assetObj = {}
    assets.forEach((k: Map<AssetName, BigNum>, v: ScriptHash,) => {
        const policy=Buffer.from(v.to_bytes()).toString('hex')
        let policyMap
        if(assetObj[policy]){
            policyMap=assetObj[policy]
        }else{
            policyMap={}
            assetObj[policy]=policyMap
        }
        k.forEach((q: BigNum, a: AssetName) => {
            const assetName = Buffer.from(a.name())
            policyMap[assetName.toString('hex')] = BigInt(q.to_str())
        })

    })
    console.log("policymap",assetObj)

    return {
        lovelace: BigInt(adaVal.to_str()),
        multiassets: assetObj
    }
}

export function decodeAssetName(asset) {
    try {
        return Buffer.from(asset, "hex").toString('utf-8')
    } catch (e) {
    }
}

export function renderLovelace(l: bigint | number) {

    if (typeof l === 'number') {
        return Math.floor(l / 1e4) / 100
    }
    return l && parseFloat((l / BigInt(10000)).toString()) / 100
}

const parser = /^([a-zA-Z0-9+]+):\/\/(.+)/

export function transformNftImageUrl(url) {
    if(!url){
        return null
    }
    const result = parser.exec(url);
    if(result){
        if (result[1] && (result [1] == 'ipfs' || result[1] == 'ipns')) {
            return 'https://ipfs.io/' + result[1] + "/" + result[2]
        }
    }else if(url.indexOf('/')== -1 ){
        return 'https://ipfs.io/ipfs/'+url
    }
    return url
}

