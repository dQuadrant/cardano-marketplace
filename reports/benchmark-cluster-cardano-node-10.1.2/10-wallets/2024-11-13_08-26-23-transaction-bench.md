# Benchmark Report
<style>
  .highlight {
    background-color: #f8d7da;
  }
</style>
### Transaction times

<table border="1">
<tr><th> </th>
<th>Primary Sale</th>
<th>Primary Buy</th>
<th>Secondary Sale</th>
<th>Withdraw</th>
<th>Total Time</th>
</tr>
<tr><th>Average</th><td>13.393</td><td>7.488</td><td>7.406</td><td>7.207</td><td>35.495</td></tr>
<tr><th>Std Deviation</th><td>0.009</td><td>0.010</td><td>0.370</td><td>0.318</td><td>0.054</td></tr>
</table>

### Time Details

<table border="1">
<thead>
<tr>
<th>Run ID</th>
<th>Primary Sale</th>
<th>Primary Buy</th>
<th>Secondary Sale</th>
<th>Withdraw</th>
</tr>
</thead>
<tr>
<td>0</td>
<td>13.388</td>
<td>7.484</td>
<td class="highlight">8.460</td>
<td>6.302</td>
</tr>
<tr>
<td>1</td>
<td>13.384</td>
<td class="highlight">7.504</td>
<td>7.273</td>
<td class="highlight">7.305</td>
</tr>
<tr>
<td>2</td>
<td>13.383</td>
<td class="highlight">7.506</td>
<td>7.294</td>
<td class="highlight">7.321</td>
</tr>
<tr>
<td>3</td>
<td>13.387</td>
<td>7.487</td>
<td>7.308</td>
<td class="highlight">7.281</td>
</tr>
<tr>
<td>4</td>
<td>13.390</td>
<td>7.484</td>
<td>7.285</td>
<td class="highlight">7.291</td>
</tr>
<tr>
<td>5</td>
<td class="highlight">13.404</td>
<td>7.477</td>
<td>7.283</td>
<td class="highlight">7.336</td>
</tr>
<tr>
<td>6</td>
<td>13.387</td>
<td class="highlight">7.495</td>
<td>7.286</td>
<td class="highlight">7.296</td>
</tr>
<tr>
<td>7</td>
<td class="highlight">13.404</td>
<td>7.477</td>
<td>7.301</td>
<td class="highlight">7.318</td>
</tr>
<tr>
<td>8</td>
<td class="highlight">13.404</td>
<td>7.484</td>
<td>7.274</td>
<td class="highlight">7.295</td>
</tr>
<tr>
<td>9</td>
<td class="highlight">13.399</td>
<td>7.486</td>
<td>7.296</td>
<td class="highlight">7.329</td>
</tr>
</table>

## Transaction Details

<style>
  .highlight {
    background-color: #f8d7da;
  }
</style>
<table border="1">
<thead>
<tr>
<th rowspan=2 >Run ID</th>
<th rowspan=2>Tx Name</th>
<th rowspan=2>Tx Hash</th>
<th rowspan=2>Fee</th>
<th colspan=2>Execution Units</th>
</tr>
<tr>
<th> Mem </th>
<th> Cpu </th>
</tr>
</thead>
<tr>
<td>0</td>
<td>Primary Sale</td>
<td>e80c2d7bb8db8f6e49e826f0c1a22f43ee01c034686ea8cdac5472c28d7da67a</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>0</td>
<td>Primary Buy</td>
<td>34a2a61874daf9e2aa3551924bd699be1a86dbc53c7dc6d55def6c6f2b17eb77</td>
<td>335747</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>0</td>
<td>Secondary Sale</td>
<td>e71bf201ec4075111b1f7a8b89325c0274dc4cf94941123586dc49bfc7cc601f</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>0</td>
<td>Withdraw</td>
<td>a55bbb936291d80d2fd1b2a4e5ece329aaa37920d3e340f096fcf04c2e1f6a87</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
<tr>
<td>1</td>
<td>Primary Sale</td>
<td>e064f464292909eddfd5159f696fde0e5b6b6a1533b18d4d7981863d6357d9d0</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>1</td>
<td>Primary Buy</td>
<td>868c47053a0f42adb707f09dc83bdc68371ad7a43293f05d605e5a3cc416852d</td>
<td>335791</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>1</td>
<td>Secondary Sale</td>
<td>6fb7c6ca5e04accb51bbdcd12f600809419e85d6b5a52b0a8a1933d904fab934</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>1</td>
<td>Withdraw</td>
<td>4d542d063361e9471bc77d12c491ac0dac2a21f0d67dfb204aba54a93d514af9</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
<tr>
<td>2</td>
<td>Primary Sale</td>
<td>43ecd895271519ad88709f71f8a5cdd41e30742a4754d64fbd6b0a7ba61cea4a</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>2</td>
<td>Primary Buy</td>
<td>a593fdb3b3d9aea3f1e6d598f02716aced968bbc393b5d0b485e5bc67b51b96b</td>
<td>335791</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>2</td>
<td>Secondary Sale</td>
<td>1cd6e4c701f3d6e3327d9d21fdfd1699880028fab5f1e6d890b1f75362af6b73</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>2</td>
<td>Withdraw</td>
<td>b3c258de8a3ac09c1d079af86fe1d17d7427d0cff7e7c03cb054b3e4196b2b54</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
<tr>
<td>3</td>
<td>Primary Sale</td>
<td>3e0b397009cf85bc6c55cbb5d59e026081d9804bf7d55a1012966a00f69265a6</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>3</td>
<td>Primary Buy</td>
<td>07c86717746d4d188de4bd08d5991cc6a768282a097e0be80f98f7329be37272</td>
<td>335791</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>3</td>
<td>Secondary Sale</td>
<td>509b60dc736e8602a29b4d28f4768c593d57f8959428218a9c56f0836bdceb09</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>3</td>
<td>Withdraw</td>
<td>b8b979ee97ab306858387a733be22c12785d319679d400db069cc7546c9df791</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
<tr>
<td>4</td>
<td>Primary Sale</td>
<td>b815a9211bb69a521228c842423176b5bdec8a0f9c1b556c8a9e0c3859722adf</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>4</td>
<td>Primary Buy</td>
<td>8247e4fcf7c86088c2e605204836bde1b54cc2b9ba7ad0daf042807b6a0d04f0</td>
<td>335791</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>4</td>
<td>Secondary Sale</td>
<td>cdd67a4a8683317c497d3cf0d3826ce98e3ef7dcc23fba7ca72dc5775b1118de</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>4</td>
<td>Withdraw</td>
<td>22a37dabbb7c1cedb59b1ff902f64622040ad9b12a205dea4f40a293f3cbdbb6</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
<tr>
<td>5</td>
<td>Primary Sale</td>
<td>f77d5f952e802526cc66217d7e15aaba1aa506749a6ac46074ffc5e0dd53d5eb</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>5</td>
<td>Primary Buy</td>
<td>be4db0d65e5c7860d3e5dea7225e27be2146683527eb91706d3dfc160935b284</td>
<td>335791</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>5</td>
<td>Secondary Sale</td>
<td>d8339c4479817c6024758d038eb75a68ec6c590ce48005fbc3537493261411bb</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>5</td>
<td>Withdraw</td>
<td>6c9e40403b8d5a6fb906a3375521ad72d56fc2bb3b5e0a9875e1fb7a0c3510f8</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
<tr>
<td>6</td>
<td>Primary Sale</td>
<td>8cb473cc637cb2f2f9679747ab71958baaed076d42be2462ea9aabd72facd9af</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>6</td>
<td>Primary Buy</td>
<td>b3390421c8315be0fb7ef2dd6788a6dcbe86ee380787c4d7615c2203dfdcdec5</td>
<td>335791</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>6</td>
<td>Secondary Sale</td>
<td>7b81f220fef9d261a8c6978eb86162fb6da055f1d1219724cf1ee8fa3696daaa</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>6</td>
<td>Withdraw</td>
<td>68b9893bb0d66c1df141396cb64abe22311e6c772bf09efe6583e06be5ac7159</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
<tr>
<td>7</td>
<td>Primary Sale</td>
<td>019736534b311de1a17bf5ef066339f588db26e1fe933665351078f15e11df84</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>7</td>
<td>Primary Buy</td>
<td>700c5a99af7ad41920165a921248ab5c96154b01f20261a511b37309e032aace</td>
<td>335791</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>7</td>
<td>Secondary Sale</td>
<td>3213a73ec8062944caba0dc3cba98acd5b7eeb8a719fdd30f4862371c91003f0</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>7</td>
<td>Withdraw</td>
<td>61419538d0e5aa5569e6661bea7c68359ca9615a808b3bfc875bc25bc0713b0a</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
<tr>
<td>8</td>
<td>Primary Sale</td>
<td>44439d30924b9ac4feb23d108f5d2770aca734a9fc322d2d3b261a220e99ddf5</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>8</td>
<td>Primary Buy</td>
<td>d5a42b065300a5191886c460fdf6eeb32426511ea36c16b72a1a020999fe459d</td>
<td>335791</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>8</td>
<td>Secondary Sale</td>
<td>9c52c561bdc8ac93f609cb670f28aa6dabdf86bc0614985ba278008520195cfc</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>8</td>
<td>Withdraw</td>
<td>25c53c2f4be218d76dca2ded8ffe4203850a8e73d7df63d0a9caee9df10c262b</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
<tr>
<td>9</td>
<td>Primary Sale</td>
<td>97c8282b47992b7b7ef68d972899284c37bcf474d8609b447b194397fd82790f</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>9</td>
<td>Primary Buy</td>
<td>1cbc6f7a5f762ad509015b3af708131b36a56dbd7d7f53c0400caa1f7111c386</td>
<td>335791</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>9</td>
<td>Secondary Sale</td>
<td>74491f5914f37b40e458929e4fd8215a3f99d1eb9bd922289418093d9450d20a</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>9</td>
<td>Withdraw</td>
<td>2fd05171e8adfa35c2f80ca946975a3d1fd78cf9b6b24eaa196a27970b74f9a1</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
</table>
