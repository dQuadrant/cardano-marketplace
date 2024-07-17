# Test Transaction Report
<style>
  .improved {
    background-color: #d4edda;
  }
  .declined {
    background-color: #f8d7da;
  }
</style>

### Simple Market

| - | ScriptBytes |
| --- |  --- |
| V2 | 4599 |
| V3 | 8118 |
| V3 Lazy | 7239 |

<table border="1">
<thead>
  <tr>
    <th rowspan="3">Test Name</th>
    <th colspan="3">Ex-Units (Mem)</th>
    <th colspan="3">Ex-Units (CPU)</th>
    <th colspan="3">Fee</th>
    <th colspan="3">Tx Bytes</th>
  </tr>
  <tr>
    <th>V2</th>
    <th>V3</th>
    <th>V3 Lazy</th>
    <th>V2</th>
    <th>V3</th>
    <th>V3 Lazy</th>
    <th>V2</th>
    <th>V3</th>
    <th>V3 Lazy</th>
    <th>V2</th>
    <th>V3</th>
    <th>V3 Lazy</th>
  </tr>
</thead>
<tr>
  <td>Mint Native Asset</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>197929</td>
<td class="improved">194761</td>
<td class="improved">193177</td>
<td>867</td>
<td class="improved">795</td>
<td class="improved">759</td>
</tr>
<tr>
  <td>Create reference script UTxO</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>374237</td>
<td class="declined">530657</td>
<td class="improved">491981</td>
<td>4874</td>
<td class="declined">8429</td>
<td class="improved">7550</td>
</tr>
<tr>
  <td>Place on Sell</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>203341</td>
<td>203341</td>
<td>203341</td>
<td>990</td>
<td>990</td>
<td>990</td>
</tr>
<tr>
  <td>Withdraw</td>
<td>392854717</td>
<td class="improved">262872340</td>
<td class="improved">229380652</td>
<td>1447666</td>
<td class="improved">1196886</td>
<td class="improved">1046572</td>
<td>493749</td>
<td class="declined">624743</td>
<td class="improved">574979</td>
<td>5048</td>
<td class="declined">8567</td>
<td class="improved">7688</td>
</tr>
<tr>
  <td>Buy</td>
<td>507343034</td>
<td class="improved">358360316</td>
<td class="improved">284767862</td>
<td>1899058</td>
<td class="improved">1665762</td>
<td class="improved">1336864</td>
<td>529149</td>
<td class="declined">659782</td>
<td class="improved">596822</td>
<td>5073</td>
<td class="declined">8592</td>
<td class="improved">7713</td>
</tr>
<tr>
  <td>Withdraw with RefScript</td>
<td>453872773</td>
<td class="improved">300088646</td>
<td class="improved">266596958</td>
<td>1670844</td>
<td class="improved">1364938</td>
<td class="improved">1214624</td>
<td>378886</td>
<td class="declined">402933</td>
<td class="improved">378660</td>
<td>477</td>
<td>477</td>
<td>477</td>
</tr>
<tr>
  <td>Buy with RefScript</td>
<td>648825799</td>
<td class="improved">445095365</td>
<td class="improved">371502911</td>
<td>2419274</td>
<td class="improved">2058626</td>
<td class="improved">1729728</td>
<td>439031</td>
<td class="declined">456318</td>
<td class="improved">418849</td>
<td>543</td>
<td>543</td>
<td>543</td>
</tr>
</table>

### Configurable Market

| - | ScriptBytes |
| --- |  --- |
| V2 | 3725 |
| V3 | 7989 |
| V3 Lazy | 7369 |

<table border="1">
<thead>
  <tr>
    <th rowspan="3">Test Name</th>
    <th colspan="3">Ex-Units (Mem)</th>
    <th colspan="3">Ex-Units (CPU)</th>
    <th colspan="3">Fee</th>
    <th colspan="3">Tx Bytes</th>
  </tr>
  <tr>
    <th>V2</th>
    <th>V3</th>
    <th>V3 Lazy</th>
    <th>V2</th>
    <th>V3</th>
    <th>V3 Lazy</th>
    <th>V2</th>
    <th>V3</th>
    <th>V3 Lazy</th>
    <th>V2</th>
    <th>V3</th>
    <th>V3 Lazy</th>
  </tr>
</thead>
<tr>
  <td>Mint Native Asset</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>193177</td>
<td class="declined">197929</td>
<td class="improved">194761</td>
<td>759</td>
<td class="declined">867</td>
<td class="improved">795</td>
</tr>
<tr>
  <td>Create reference script UTxO</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>335781</td>
<td class="declined">524981</td>
<td class="improved">497701</td>
<td>4000</td>
<td class="declined">8300</td>
<td class="improved">7680</td>
</tr>
<tr>
  <td>Place on Sell</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>203341</td>
<td>203341</td>
<td>203341</td>
<td>990</td>
<td>990</td>
<td>990</td>
</tr>
<tr>
  <td>Create market configuration</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>179141</td>
<td>179141</td>
<td>179141</td>
<td>440</td>
<td>440</td>
<td>440</td>
</tr>
<tr>
  <td>Withdraw</td>
<td>180264963</td>
<td class="declined">242637957</td>
<td class="improved">228228652</td>
<td>582806</td>
<td class="declined">1106444</td>
<td class="improved">1039372</td>
<td>390063</td>
<td class="declined">612390</td>
<td class="improved">580201</td>
<td>4174</td>
<td class="declined">8438</td>
<td class="improved">7818</td>
</tr>
<tr>
  <td>Withdraw with RefScript</td>
<td>203610477</td>
<td class="declined">279854263</td>
<td class="improved">265444958</td>
<td>653668</td>
<td class="declined">1274496</td>
<td class="improved">1207424</td>
<td>289261</td>
<td class="declined">394540</td>
<td class="improved">380331</td>
<td>482</td>
<td>482</td>
<td>482</td>
</tr>
<tr>
  <td>Buy</td>
<td>532740306</td>
<td class="improved">518936842</td>
<td class="improved">455008794</td>
<td>1940592</td>
<td class="declined">2482524</td>
<td class="improved">2190640</td>
<td>499584</td>
<td class="declined">719278</td>
<td class="improved">668744</td>
<td>4305</td>
<td class="declined">8610</td>
<td class="improved">7949</td>
</tr>
<tr>
  <td>Buy with RefScript</td>
<td>588253693</td>
<td class="improved">549977615</td>
<td class="improved">535568310</td>
<td>2112056</td>
<td class="declined">2622368</td>
<td class="improved">2555296</td>
<td>408271</td>
<td class="declined">498917</td>
<td class="improved">484708</td>
<td>644</td>
<td>644</td>
<td>644</td>
</tr>
</table>
