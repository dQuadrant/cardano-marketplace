<script setup lang="ts">
import {sellNftState} from "../scripts/sotre";
</script>

<template>
    <div v-if="sellNftState" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full">
      <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="p-2">
          <h1 class="">Sell NFT</h1>
          <input v-model="amount" placeholder="Enter the amount"/>
        </div>
        <div
            class="border-2 border-teal-200 border-radius-5 m-2 p-2 inline"
            @click="sellNft">Sell</div>
      </div>
    </div>
</template>

<script lang="ts">

import {callKuberAndSubmit} from "@/scripts/wallet";

export default {
  props:['provider'],
  computed:{
  },
  create(){

  },
  methods:{
    sellNft(){
      console.log("current provider: ", this.$props.provider);
      const body = {
        "selections":["addr_test1qrhu4z4vqw0nlar99kmua6n6y0cz5j2jsjymhtqgxegxkasf8cskcguz4x2ax5mcz659rtxjcc835vdudetfk5z2a88s7jam7e"],
        "outputs": [{
          "address": "addr_test1qrc5qx5wwglhngr7e0qq64uhfw7c5hat6j3t6umwkcum0hxwj6q89rgh6mtnue56pvf4h2xh85gjq8303mj45fmuvafqwrj4wm",
          "value": "10A"
        }]
      };
      callKuberAndSubmit(this.provider, JSON.stringify(body));
    }
  },
  data(){
    return {
      amount: "",
    }
  }
}
</script>

