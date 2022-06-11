export type HexString  = string;

export  interface CIP30Provider {
    apiVersion: String ;
    enable : ()=> Promise<CIP30Instace>;
    icon: string;
    isEnabled:()=> Promise<Boolean>;
    name: string;
}

export  interface CIP30Instace {
    submitTx:(tx:string) =>   Promise <any>
    signTx: (tx: string,partial?: Boolean) => Promise<HexString>
    getChangeAddress: ()=> Promise<HexString>
    getNetworkId: ()=>Promise<number>
    getRewardAddresses: ()=>Promise<HexString>
    getUnusedAddresses: ()=>Promise<Array<HexString>>
    getUsedAddresses: ()=>Promise<Array<HexString>>
    getUtxos: ()=>Promise<Array<HexString>>
    getCollateral: () => Promise<Array<HexString>>
}
