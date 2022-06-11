import { reactive, ref } from 'vue'
export const walletState = ref(false) 
export const walletAction = reactive({
    enable: false,
    callback :null,
    message : null,
})
