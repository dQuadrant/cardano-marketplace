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
<tr><th>Average</th><td>5.270</td><td>1.961</td><td>3.247</td><td>4.397</td><td>14.875</td></tr>
<tr><th>Std Deviation</th><td>0.028</td><td>0.026</td><td>0.041</td><td>0.020</td><td>0.024</td></tr>
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
<td>5.267</td>
<td>1.938</td>
<td class="highlight">3.286</td>
<td>4.373</td>
</tr>
<tr>
<td>1</td>
<td>5.220</td>
<td class="highlight">1.986</td>
<td class="highlight">3.320</td>
<td>4.377</td>
</tr>
<tr>
<td>2</td>
<td>5.241</td>
<td class="highlight">1.964</td>
<td class="highlight">3.283</td>
<td class="highlight">4.423</td>
</tr>
<tr>
<td>3</td>
<td class="highlight">5.274</td>
<td class="highlight">1.982</td>
<td class="highlight">3.251</td>
<td>4.365</td>
</tr>
<tr>
<td>4</td>
<td class="highlight">5.292</td>
<td>1.949</td>
<td>3.200</td>
<td class="highlight">4.417</td>
</tr>
<tr>
<td>5</td>
<td>5.259</td>
<td>1.960</td>
<td>3.247</td>
<td class="highlight">4.411</td>
</tr>
<tr>
<td>6</td>
<td class="highlight">5.281</td>
<td>1.946</td>
<td>3.214</td>
<td class="highlight">4.398</td>
</tr>
<tr>
<td>7</td>
<td>5.252</td>
<td class="highlight">2.011</td>
<td>3.225</td>
<td class="highlight">4.407</td>
</tr>
<tr>
<td>8</td>
<td class="highlight">5.311</td>
<td>1.923</td>
<td class="highlight">3.255</td>
<td>4.396</td>
</tr>
<tr>
<td>9</td>
<td class="highlight">5.300</td>
<td>1.949</td>
<td>3.192</td>
<td class="highlight">4.408</td>
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
<td>849c9fe11239e55be99a59ae8b53ddb346f64035ab4c6b0bdf81855a6275cd3d</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>0</td>
<td>Primary Buy</td>
<td>93dae101286b392e6ce3abdd99d8ad4aa155f11331315b8ab5be63669468300f</td>
<td>335747</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>0</td>
<td>Secondary Sale</td>
<td>88ae4e0d75e33d49d35fdb94e6671c69907096c63526e8c8a8a75bc702481c21</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>0</td>
<td>Withdraw</td>
<td>f3483fced3e0a9c913985f42102e9ce5404be71c8a69371275908441a4f7a54f</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
<tr>
<td>1</td>
<td>Primary Sale</td>
<td>10c440a6e2709ffd515d4f6e1af1ca2ac05e69f422cd24a0cc1aca0e3c848c8d</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>1</td>
<td>Primary Buy</td>
<td>360dfc54c2f788254d70a52a23a94a489b89491b401fb36a0dfc92cdeb286926</td>
<td>335747</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>1</td>
<td>Secondary Sale</td>
<td>63d5cd0b18f5917d176378798c2c3d570a049ca0bca4fe40ffa8bfc243bb4533</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>1</td>
<td>Withdraw</td>
<td>6eec608d3e60933f8ed673a393eeb712408a3fc9ee6a8ff9fa8644e17de7c47d</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
<tr>
<td>2</td>
<td>Primary Sale</td>
<td>2c398e6e195a195c0ea9782ddc8a337d627198315408f224b1c83a377a760a53</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>2</td>
<td>Primary Buy</td>
<td>8e084f0f90ebb43295dcb105afe58a288b43986f1abe087f117890148390331d</td>
<td>335835</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>2</td>
<td>Secondary Sale</td>
<td>effa75f5da35d6fd7a35ca092b5dbf7fd9266a1f4bcc0e69b6650261417748f6</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>2</td>
<td>Withdraw</td>
<td>86838e52ff222bdca358cd11dbe41a52a5c7388f3070b7a254e5d3effbb9019e</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
<tr>
<td>3</td>
<td>Primary Sale</td>
<td>259ef013b4e9673894226520ab63b20a67ef40ec1ef8f3bb7ad35bb1bd1cd9a0</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>3</td>
<td>Primary Buy</td>
<td>5f08027a322101ccec29d7aedaec8882aecc48fa1725969fbfd6b69490573cfb</td>
<td>335835</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>3</td>
<td>Secondary Sale</td>
<td>13bc70467e78d6eea000ba2601ed332a8a7b60998feaabc87bf2537f3915cc7e</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>3</td>
<td>Withdraw</td>
<td>1c0a28ef7cbe634e70fec438e246d554c2a0cbb4e2f4d0835191c3fd9306ce60</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
<tr>
<td>4</td>
<td>Primary Sale</td>
<td>710ade336d7dd27d40e5175947464eb57638547392a45252525ee38245efb40d</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>4</td>
<td>Primary Buy</td>
<td>add82249b02b9a0e77dd1f29cff331f70c4e683b1d884b4ff5b1cff4978b2bfd</td>
<td>335835</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>4</td>
<td>Secondary Sale</td>
<td>786751f74c45b27173db82fd3c7f112ded0fb2aaec1d9b306c31b0be57631c07</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>4</td>
<td>Withdraw</td>
<td>d3f4e1ae06288e2913ffe63d1de92b754db9ded86438cb9e203c784d54ff8374</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
<tr>
<td>5</td>
<td>Primary Sale</td>
<td>3cbec0ae29cac6bdcba0daf51ff2896b415e4cf73ed8d89b0039896962542307</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>5</td>
<td>Primary Buy</td>
<td>be50218c9b3739f513c8bc1a515d0bdcc8be7c55c194faf6e8bff6acd6286cb7</td>
<td>335835</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>5</td>
<td>Secondary Sale</td>
<td>999ffe4550ef820cc8ea769a333d8ff4a64497e1ea5479d06fd55230f60caa34</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>5</td>
<td>Withdraw</td>
<td>76d0a45f454881243e0d67bf08e4f490ed2d0edddaec04725c01aaa793b2939e</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
<tr>
<td>6</td>
<td>Primary Sale</td>
<td>4fcd015bb42cd63fb2e2ac71e0f0b82c5defaebe6529ed94eda4e307f2f11a61</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>6</td>
<td>Primary Buy</td>
<td>3c419e06d5a32ea9b577906758b3e41b597a24a6ea07dab9e3cde21ddc0df6fa</td>
<td>335835</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>6</td>
<td>Secondary Sale</td>
<td>3c16fb5e2d6c7408b6cf84b7c75d6dea527750f9dde110bc90ad7062f54276e4</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>6</td>
<td>Withdraw</td>
<td>488b429717cdc6437181355549c5968099ee4e3c437aa961812c8d06434e68f3</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
<tr>
<td>7</td>
<td>Primary Sale</td>
<td>1d7be3c17cd009db792e4a5f001cbe3c472d51397251b58566c14e435e896bc0</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>7</td>
<td>Primary Buy</td>
<td>14da63ec1ad3430aa0c6c2b6317dcc69bdb277c18596a1fa1ad542c1271475c8</td>
<td>335835</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>7</td>
<td>Secondary Sale</td>
<td>1043bd3fff6a540a09be4c2a1367363aaee4f6629a65d27ee44ab2f556907e4d</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>7</td>
<td>Withdraw</td>
<td>305983d9c2a648357b6724ea4c46bd01630257b96b7fc5ce8e224266bd5bc2b4</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
<tr>
<td>8</td>
<td>Primary Sale</td>
<td>8c080f08a4ae2b3ccabfb7edc7c4ce65d2e403fbaa2ffd2151d96e8066785f23</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>8</td>
<td>Primary Buy</td>
<td>9aed175310edecebf404e3afaff069e57ca2c74c8a7416137818b59b8e7a367b</td>
<td>335835</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>8</td>
<td>Secondary Sale</td>
<td>1c9bb4c2c3b3eb504e51cd782271849899ecc15c3dbd3837b2e8983ce2239731</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>8</td>
<td>Withdraw</td>
<td>654f8b35326dd8fc6f6c99d7d20aa6923b6d4b10f685a7dd7969db105ce8a27a</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
<tr>
<td>9</td>
<td>Primary Sale</td>
<td>b2cd491106c1fe0b740470682664b2f2481d7cd69f7de2e4ebd3f0bfa73dd9c6</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>9</td>
<td>Primary Buy</td>
<td>6990a311c0d3248a8e59280e3085c653a8a44c9f9a53ed9e639ef32b254e956f</td>
<td>335835</td>
<td>1992720</td>
<td>536441539</td>
</tr>
<tr>
<td>9</td>
<td>Secondary Sale</td>
<td>ee7708dce4a50f473acdbbd963d006c1f1ecb75fb86133f8e6fc3bc9631c1af6</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>9</td>
<td>Withdraw</td>
<td>c30f84c75eb700324d39037768afd07a65dc5ad105de7eb9b406a951e575a888</td>
<td>314559</td>
<td>1733544</td>
<td>468293773</td>
</tr>
</table>
