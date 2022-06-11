
import {blockfrost,market} from    "@/config"


export function listMarket() {
    return getBlockfrost("/addresses/" + market.address + "/utxos?order=desc")
}

export function getAssetDetail(asset: string) {
    return getBlockfrost("/assets/" + asset)
}

export function getDatum(hash: string) {
    return getBlockfrost("/scripts/datum/" + hash)
}

function getBlockfrost(path) {
    const url= blockfrost.apiUrl + path
    return fetch(url, {
        headers: {project_id: blockfrost.apiKey}
    }).then(res => {
        if (res.status === 200) {
            return res.json()
        } else {
            return res.text().then(txt => {
                let err
                let json: any
                try {
                    json = JSON.parse(txt)
                    if (json) {
                        err = Error(`BlockfrostApi [Status ${res.status}] : ${json.message ? json.message : txt}`)
                        err.json = json
                    } else {
                        err = Error(`BlockfrostApi [Status ${res.status}] : ${txt}`)
                        err.text = txt
                    }
                } catch (e) {
                    err = Error(`BlockfrostApi [Status ${res.status}] : ${txt}`)
                    err.text = txt
                }
                err.response=res
                err.url=url
                err.status_code=res.status
                throw(err)
            })
        }
    })
}
