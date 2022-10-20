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
        <ul class=" navbar-nav flex flex-column pl-0 list-style-none mr-auto">

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
  </template>
