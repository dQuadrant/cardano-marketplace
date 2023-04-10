import type { CIP30Wallet } from 'kuber-client';
import { reactive, ref } from 'vue'
export const walletState = ref(false) 

interface WalletAction{
    enable : boolean;
    callback : ((CIP30Wallet) =>(Promise<unknown> |null)) | null
    message: string
}
export const walletAction:WalletAction = reactive({
    enable: false,
    callback :null,
    message : null,
})
