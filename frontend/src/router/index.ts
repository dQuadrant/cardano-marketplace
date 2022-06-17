import { createRouter, createWebHistory } from 'vue-router'
import Listing from '@/components/Listing.vue'
import Wallet from '@/components/Wallet.vue'
import Offer from '@/components/Offer.vue'


console.log(import.meta.env.BASE_URL)

const pathregex  = new RegExp('.*')
const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      // @ts-ignore
      path: '/',
      name: 'home',
      component: Listing
    },
    {
        path:"/offers",
        name : "offers",
        component: Offer
    },
    {
        path:"/wallet",
        name : "walet",
        component: Wallet
    }
  ]
})

export default router
