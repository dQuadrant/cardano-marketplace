import { kuberApiUrl } from '@/config';
import {Buffer} from 'buffer'
import { Kuber} from 'kuber-client';

export const   kuber=   new Kuber(kuberApiUrl)

export function decodeAssetName(asset:string) {
    try {
        return Buffer.from(asset, "hex").toString('utf-8')
    } catch (e) {
        return "0x"+asset
    }
}

export function renderLovelace(l: bigint | number) {

    if (typeof l === 'number') {
        return Math.floor(l / 1e4) / 100
    }
    return l && parseFloat((l / BigInt(10000)).toString()) / 100
}

const parser = /^([a-zA-Z0-9+]+):\/\/(.+)/

export function transformNftImageUrl(url:string) {
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