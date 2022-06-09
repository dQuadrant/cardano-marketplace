<script setup lang="ts">
import { Buffer } from "buffer";
import { RouterView } from "vue-router";
import { ref } from 'vue'
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import {decodeAssetName, listProviders, walletValue} from "@/scripts/wallet";
import type {CIP30Provider} from "@/types";
import {BigNum} from "@emurgo/cardano-serialization-lib-asmjs";
import {getAssetDetail} from "@/scripts/blockfrost";

const open = ref(true)

</script>

<template>
  <div class="">
  <nav class="
    pl-5
          w-full
          flex flex-wrap
          items-center
          justify-between
          py-2
          bg-gray-100cod
          text-gray-500
          hover:text-gray-700
          focus:text-gray-700
          shadow-lg
          navbar navbar-expand-lg navbar-light
          sticky
          ">
    <div class="collapse navbar-collapse flex-grow items-center" id="navbarSupportedContent">
      <!-- Left links -->
      <ul class=" inline navbar-nav flex flex-column pl-0 list-style-none mr-auto">

        <li class="nav-item px-2">
          <a class="nav-link active" aria-current="page" href="/">Marketplace</a>
        </li>
        <li class="nav-item  border-l-2 border-l-gray-300 pl-2">
          <a class="nav-link text-gray-500 hover:text-gray-700 focus:text-gray-700 p-0" @click="open=true">Wallet</a>
        </li>
      </ul>
      <!-- Left links -->
    </div>
    <!-- Collapsible wrapper -->
  </nav>
  <RouterView class="flex-grow" />
  <footer class="bg-gray-200 text-center lg:text-left">
    <div class="text-gray-700 text-center p-4" style="background-color: rgba(0, 0, 0, 0.2);">
      Simple Marketplace |
      <a class="text-gray-800" href="https://github.com/dquadrant/kuber">Powered by Kuber</a>
    </div>
  </footer>
  </div>
  <!-- This example requires Tailwind CSS v2.0+ -->


  <!-- This example requires Tailwind CSS v2.0+ -->
    <TransitionRoot  as="template" :show="open">
      <Dialog as="div" class="relative z-10" @close="open = false">
        <TransitionChild as="template" enter="ease-in-out duration-300" enter-from="opacity-0" enter-to="opacity-100" leave="ease-in-out duration-300" leave-from="opacity-100" leave-to="opacity-0">
          <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" />
        </TransitionChild>
        <div class="fixed inset-0 overflow-hidden">
          <div class="absolute inset-0 overflow-hidden">
            <div class="pointer-events-none fixed inset-y-0 right-0 flex max-w-full pl-10">
              <TransitionChild as="template" enter="transform transition ease-in-out duration-300 sm:duration-400" enter-from="translate-x-full" enter-to="translate-x-0" leave="transform transition ease-in-out duration-300 sm:duration-400" leave-from="translate-x-0" leave-to="translate-x-full">
                <DialogPanel class="pointer-events-auto relative w-screen max-w-md">
                  <div class="flex h-full flex-col overflow-y-scroll bg-white py-6 shadow-xl">


                    <div  class="px-4 sm:px-6">
                      <div v-if="curProvider">
                        <img v-if="curProvider.icon" class="inline  w-12 h-12 mr-2 " :src="curProvider.icon" />
                        <img v-else class="inline  w-12 h-12 mr-2" src="/cardano.png" />
                        <span class="text-lg font-medium text-blue-900">{{curProvider.name}}</span>
                        <button @click="disconnectProvider" class="float-right h-full"> <img class="inline text-red-600 h-4 w-4" src="/disconnect.svg"></button>
                      </div>
                      <DialogTitle v-else class="text-lg font-medium text-blue-900"> Connect Wallet </DialogTitle>
                    </div>
                    <div class="relative mt-6 flex-1 px-4 sm:px-6">
                      <div v-if="curProvider">
                        {{renderLovelace(balance.lovelace) }}  Ada

                        <div v-for="asset in balance.multiAssets">
                          <img  :alt="asset.tokenName +'_img'" v-if="asset.image" :src="asset.image" />
                        <span v-if="asset.name" class="text-blue-900 text-xl font-extrabold"> {{ asset.name }}  </span>

                        <div v-else class="text-blue-700 font-extrabold"> {{ asset.policy.substring(0, 8) }}...{{
                              asset.tokenName
                            }}
                          </div>
                        </div>

                        </div>
                      <div v-else class="flex" v-for="provider in this.providers">
                        <button  @click="activate(provider)" class="flex-grow content-start text-left focus:border-b-orange-400 focus:text-blue-900 focus:border-0 focus:m-0 focus:text-lg ">
                          <img v-if="provider.icon" class="inline  w-12 h-12 mr-2 " :src="provider.icon" />
                          <img v-else class="inline  w-12 h-12 mr-2" src="/cardano.png" />
                          <span>{{provider.name}}</span>
                        </button>
                      </div>
                    </div>
                  </div>
                </DialogPanel>
              </TransitionChild>
            </div>
          </div>
        </div>
      </Dialog>
    </TransitionRoot>
  </template>
