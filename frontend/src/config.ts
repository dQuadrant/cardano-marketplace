export const kuberApiUrl = "https://preview.kuberide.com"
export const explorerUrl = "https://preview.cexplorer.io"
export const blockfrost = {
    apiUrl: "https://cardano-sanchonet.blockfrost.io/api/v0",
    apiKey: "sanchonetw63f9C5eJBQg0mfq29zQXTXWGPykAFLo",  // replace the api key
}


export const market= {
    // this adress is obtained by using `market-cli ls` command
    address:  "addr_test1wpuxaj2hl67ete0nchuenhc4utmuevep2umnn7ajm0xdfnsmquxcs",
    script: {
        type: 'PlutusScriptV2',
        description: 'SimpleMarketplaceV2',
        // this cbor hex is obtained by using  `market-cli cat`   command
        cborHex:
            '59133d59133a010000323232323322332232323232323322323232323232323232323232323232323232323232323232323322323222232533500110261350244901035054350032323235003225335350022233500223502a00125029215335005153355335333573466e1cd401088cccd54c04448004c8cd405488ccd405800c004008d404c004cd4050888c00cc008004800488cdc00009a801111a80091111a8021119a801124000490011a8011111111111110062400090010178170817899ab9c491164d756c7469706c652073637269707420696e707574730002e15335333573466e20c8c0b4004ccd54c02c4800488cd54c040480048d400488cd540dc008cd54c04c480048d400488cd540e8008ccd40048cc0f52000001223303e00200123303d00148000004cd54c040480048d400488cd540dc008ccd40048cd54c050480048d400488cd540ec008d5405800400488ccd5540440680080048cd54c050480048d400488cd540ec008d54054004004ccd55403005400800540c4c8d4004888888888888ccd54c0604800488d40088888d401088cd400894cd4ccd5cd19b8f017001045044133504600600810082008503e00a350042200200202e02f102f133573892010f53656c6c6572206e6f7420706169640002e102e153353235001222222222222533533355301c1200133501f225335002210031001503425335333573466e3c03c0040f40f04d40d8004540d4010840f440ecd40108800840bc4cd5ce24811853656c6c6572205369676e6174757265204d697373696e670002e13263202a335738920118536372697074204164647265737320696e2073656c6c65720002a333502223232323333333574800846666ae68cdc39aab9d5004480008cccd55cfa8021281511999aab9f50042502b233335573e6ae89401494cd4c8c8c8c8c8c8c8c8c8c8c8c8c8c8ccccccd5d200711999ab9a3370e6aae7540392000233335573ea01c4a07a46666aae7d4038940f88cccd55cfa8071281f91999aab9f500e25040233335573ea01c4a08246666aae7d4038941088cccd55cfa8071282191999aab9f500e25044233335573ea01c4a08a46666aae7d4038941188cccd55cfa8071282391999aab9f500e25048233335573e6ae89403c94cd4cd40d80dcd5d0a80d90a99a99a81b81c1aba1501b21533533503803a35742a03642a66a666aa07a090a0786ae85406c854cd4ccd540f812540f4d5d0a80d90a99a99a81d8231aba1501b2153353335504004804935742a03642a66a646464646666666ae900108cccd5cd19b8735573aa008900011999aab9f500425057233335573ea0084a0b046666aae7cd5d128029299a991919191999999aba400423333573466e1cd55cea8022400046666aae7d4010941808cccd55cfa8021283091999aab9f35744a00a4a66a66a0be0b86ae85401c854cd4c184d5d0a803909a83289198008018010a8318a831128310328320319282f8309282f1282f1282f1282f03089aba25001135573ca00226ea8004d5d0a80390a99a991919191999999aba400423333573466e1cd55cea8022400046666aae7d4010941848cccd55cfa8021283111999aab9f35744a00a4a66a66a0c00ba6ae85401c854cd4c188d5d0a803909a83309198008018010a8320a83192831833032832128300311282f9282f9282f9282f83109aba25001135573ca00226ea8004d5d0a803909a82e09198008018010a82d0a82c9282c82e02d82d1282b02c1282a9282a9282a9282a82c09aba25001135573ca00226ea8004d5d0a80d90a99a99a81f0269aba1501b21533533355043047505335742a03642a66a666aa08809ea0a86ae85406c854cd4c12cd5d0a80d909a82b091999999999998008068060058050048040038030028020018010a82a0a8298a8290a8288a8280a8278a8270a8268a8260a8258a8250a824928248260258250248240238230228220218210208201281e01f1281d9281d9281d9281d81f09aba25001135744a00226ae8940044d5d1280089aba25001135744a00226ae8940044d5d1280089aba25001135744a00226ae8940044d55cf280089baa00135742a00e42a66a60446ae85401c84d40bc48cc00400c008540b4540b0940b00bc0b80b4940a40ac940a0940a0940a0940a00ac4d5d1280089aab9e50011375400200692010f496e76616c696420636f6e7465787400333502123232323333333574800846666ae68cdc3a8012400446666aae7d40108d40a8488004940a40b08cccd5cd19b875003480008cccd55cfa80291a81589100112815016928148158151281392813928139281381509aab9d5002135573ca00226ea800400d240110496e76616c69642072656465656d657200333502023232323333333574800846666ae68cdc39aab9d5004480008cccd55cfa8021281411999aab9f500425029233335573e6ae89401494cd54cd4c074d5d0a803909a816109198008018010a81510a99a98129aba15007213502d30020011502b1502a2502a02d02c02b2502702925026250262502625026029135744a00226aae7940044dd5000801a4810c496e76616c6964206461746100111222333553004120015029335530071200123500122335502e00235500900133355300412001223500222533533355300c12001323350102233350032200200200135001220011233001225335002102f100102c235001223300a0020050061003133502d004003502a00133553007120012350012232335502f003300100532001355031225335001135500a003221350022253353300c002008112223300200a004130060030023200135502a22112225335001100222133005002333553007120010050040011121222300300411212223001004320013550272211225335001150272213350283004002335530061200100400132001355026221122253350011350060032213335009005300400233355300712001005004001123500122001123500122002122123300100300222333573466e3c00800407807448c88ccccccd5d20009280b9280b918019bac002250172501701a320013550222233335573e00246a030a0424a66a60086ae84008854cd4c010d5d1001909a80d19a8110010008a80c0a80b80d11919191999999aba400423333573466e1cd55cea8022400046666aae7d4010940648cccd55cfa8021280d11999aab9f35744a00a4a66a60226ae85401c854cd4c02cd5d0a803909a80f09198008018010a80e0a80d9280d80f00e80e1280c00d1280b9280b9280b9280b80d09aba25001135573ca00226ea80048c8c8c8c8c8ccccccd5d200311999ab9a3370e6aae7540192000233335573ea00c4a03446666aae7d40189406c8cccd55cfa8031280e11999aab9f50062501d233335573e6ae89401c94cd4c044d5d0a80590a99a999aa80800da8079aba1500b215335323232323333333574800846666ae68cdc3a8012400846666aae7d40109409c8cccd55cf9aba25005235029321222300200435742a00c4a05005605446666ae68cdc3a801a400446666aae7d4014940a08cccd55cf9aba2500625335302535742a00e426a056244460020082a0524a05205805646666ae68cdc3a8022400046666aae7d40188d40a8488800c940a40b0940a00a80a40a0940949409494094940940a04d55cea80109aab9e5001137540026ae85402c854cd4cd4054074d5d0a805909a8118919998008028020018010a8108a8100a80f8a80f1280f01081000f80f00e9280c80d9280c1280c1280c1280c00d89aba25001135744a00226ae8940044d55cf280089baa0011335500100c00a112232233333335748002aa00a4a66a60066eac00884d40580045405154015540155401405cc8004d5407c88c8cccd55cf80111a80b280f9299a98031aab9d5002215335300635573ca00642a66a600c6ae8801484d4064cd4084cd5408c00c0080045405c54058540540604d5d0800889280791919191999999aba400423333573466e1cd55cea8022400046666aae7d4010940508cccd55cfa8021280a91999aab9f35744a00a4a66a60226ae85401c854cd4cd402c040d5d0a803909a80c89198008018010a80b8a80b1280b00c80c00b9280980a9280912809128091280900a89aba25001135573ca00226ea8004488c8c8c8ccccccd5d200211999ab9a3370ea004900011999aab9f500425014233335573e6ae89401494cd4c024d5d0a803109a80b9a80b8008a80a9280a80c00b91999ab9a3370ea006900111999aab9f50052350165015250150182501401601525012250122501225012015135573aa00426aae7940044dd500091919191999999aba400423333573466e1d40092006233335573ea0084a02446666aae7cd5d128029299a98059aba150062135015122223004005150132501301601523333573466e1d400d2004233335573ea00a4a02646666aae7cd5d128031299a98069aba150072135016122223002005150142501401701623333573466e1d40112002233335573ea00c4a02846666aae7cd5d128039299a98059aba150082135017122223001005150152501501801723333573466e1d40152000233335573ea00e4a02a46666aae7cd5d128041299a98091aba15009213501812222300300515016250160190182501401601501401325010250102501025010013135573aa00426aae7940044dd500091919191999999aba400423333573466e1cd55cea8022400046666aae7d4010940448cccd55cfa8021280911999aab9f35744a00a4a66a60146ae85401c854cd4c038d5d0a803909a80b09198008018010a80a0a8099280980b00a80a128080091280792807928079280780909aba25001135573ca00226ea80048c8c8ccccccd5d200191999ab9a3370e6aae75400d2000233335573ea0064a01e46666aae7cd5d128021299a98061aba15005213501200115010250100130122500e0102500d2500d2500d2500d010135573ca00226ea80048c8c8c8c8c8c8ccccccd5d200391999ab9a3370ea004900611999aab9f5007235013122222220032501201523333573466e1d400d200a233335573ea01046a028244444440084a02602c46666ae68cdc3a8022401046666aae7d4024940508cccd55cfa8039280a91999aab9f35744a0104a66a60246ae854030854cd4c044d5d0a805109a80c89111111198008048040a80b8a80b1280b00c80c00b91999ab9a3370ea00a900311999aab9f500a25015233335573ea0124a02c46666aae7cd5d128051299a98099aba1500d215335301435742a018426a03424444444660040120102a0302a02e4a02e03403203046666ae68cdc3a8032400846666aae7d402c940588cccd55cfa8059280b91999aab9f35744a0184a66a60226ae854038854cd4c054d5d0a807109a80d89111111198030048040a80c8a80c1280c00d80d00c91999ab9a3370ea00e900111999aab9f500c25017233335573e6ae89403494cd4c044d5d0a807109a80d0911111118038040a80c1280c00d80d11999ab9a3370ea010900011999aab9f500d25018233335573e6ae89403894cd4c048d5d0a807909a80d8911111118028040a80c9280c80e00d9280b80c80c00b80b00a80a0099280812808128081280800989aab9d5005135744a00626ae8940084d5d1280089aab9e500113754002464646464646666666ae900188cccd5cd19b875002480088cccd55cfa8031280811999aab9f500625011233335573ea00c4a02446666aae7cd5d128039299a98069aba1500a215335300e35742a01442a66a601e6ae85402884d405c488ccc00401401000c54054540505404c9404c05805405004c8cccd5cd19b875003480008cccd55cfa8039280891999aab9f35744a0104a66a601a6ae85402484d4050488c00800c540489404805405094040048044940389403894038940380444d55cea80209aba25001135744a00226aae7940044dd500091999999aba4001250082500825008235009375a0044a01001646464646666666ae900108cccd5cd19b875002480088cccd55cfa8021280611999aab9f35744a00a4a66a60126ae85401884d403c488c00400c540349403404003c8cccd5cd19b875003480008cccd55cfa8029280691999aab9f35744a00c4a66a60146ae85401c84d4040488c00800c540389403804404094030038034940289402894028940280344d55cea80109aab9e50011375400246666666ae90004940189401894018940188d401cdd70010048911919191999999aba400423333573466e1d40092004233335573ea00846a01824440024a01601c46666ae68cdc3a801a400446666aae7d4014940308cccd55cf9aba2500625335300a35742a00e426a01e244460060082a01a4a01a02001e46666ae68cdc3a8022400046666aae7d40188d403848880089403404094030038034030940249402494024940240304d55cea80109aab9e50011375400246464646666666ae900108cccd5cd19b875002480088cccd55cfa80211a8050089280480611999ab9a3370ea006900011999aab9f500523500b0112500a00d2500900b00a2500725007250072500700a135573aa00426aae7940044dd50008911299a98018011080089a8030008909118010018891000891931900199ab9c00100349848004c8004d5402488cd400520002235002225335333573466e3c0080340240204c01c0044c01800cc8004d5402088cd400520002235002225335333573466e3c00803002001c40044c01800c4880084880044488008488488cc00401000c448848cc00400c009220100223370000400222464600200244660066004004003',
    },
}

