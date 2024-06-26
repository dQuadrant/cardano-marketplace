# Test Transaction Report
<style>
  .improved {
    background-color: #d4edda;
  }
  .declined {
    background-color: #f8d7da;
  }
</style>

### Simple Market (Single Script)
<table border="1">
<thead>
  <tr>
    <th rowspan="2">Test Name</th>
    <th colspan="2">Ex-Units (Mem)</th>
    <th colspan="2">Ex-Units (CPU)</th>
    <th colspan="2">Fee</th>
    <th colspan="2">Tx Bytes</th>
  </tr>
  <tr>
    <th>V2</th>
    <th>V3</th>
    <th>V2</th>
    <th>V3</th>
    <th>V2</th>
    <th>V3</th>
    <th>V2</th>
    <th>V3</th>
  </tr>
</thead>
<tr>
  <td>Mint Native Asset</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>332261</td>
<td>332261</td>
<td>3920</td>
<td>3920</td>
</tr>
<tr>
  <td>Create reference script UTxO</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>374413</td>
<td class="declined">488769</td>
<td>4878</td>
<td class="declined">7477</td>
</tr>
<tr>
  <td>Place on Sell</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>201361</td>
<td>201361</td>
<td>945</td>
<td>945</td>
</tr>
<tr>
  <td>Withdraw</td>
<td>405388323</td>
<td class="improved">317076469</td>
<td>1498042</td>
<td class="improved">1129900</td>
<td>497823</td>
<td class="declined">584526</td>
<td>5054</td>
<td class="declined">7652</td>
</tr>
<tr>
  <td>Buy</td>
<td>515692034</td>
<td class="improved">392098180</td>
<td>1935358</td>
<td class="improved">1413816</td>
<td>532021</td>
<td class="declined">607329</td>
<td>5077</td>
<td class="declined">7675</td>
</tr>
<tr>
  <td>Withdraw with RefScript</td>
<td>466682379</td>
<td class="improved">364975651</td>
<td>1722420</td>
<td class="improved">1299152</td>
<td>516641</td>
<td class="declined">599197</td>
<td>488</td>
<td>488</td>
</tr>
<tr>
  <td>Buy with RefScript</td>
<td>576986090</td>
<td class="improved">439997362</td>
<td>2159736</td>
<td class="improved">1583068</td>
<td>550839</td>
<td class="declined">622000</td>
<td>511</td>
<td>511</td>
</tr>
</table>

### Configurable Market  (Multi Script)
<table border="1">
<thead>
  <tr>
    <th rowspan="2">Test Name</th>
    <th colspan="2">Ex-Units (Mem)</th>
    <th colspan="2">Ex-Units (CPU)</th>
    <th colspan="2">Fee</th>
    <th colspan="2">Tx Bytes</th>
  </tr>
  <tr>
    <th>V2</th>
    <th>V3</th>
    <th>V2</th>
    <th>V3</th>
    <th>V2</th>
    <th>V3</th>
    <th>V2</th>
    <th>V3</th>
  </tr>
</thead>
<tr>
  <td>Mint Native Asset</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>332217</td>
<td>332217</td>
<td>3919</td>
<td>3919</td>
</tr>
<tr>
  <td>Create reference script UTxO</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>336001</td>
<td class="declined">367197</td>
<td>4005</td>
<td class="declined">4714</td>
</tr>
<tr>
  <td>Place on Sell</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>201361</td>
<td class="declined">203297</td>
<td>945</td>
<td class="declined">989</td>
</tr>
<tr>
  <td>Create market configuration</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>179317</td>
<td>179317</td>
<td>444</td>
<td>444</td>
</tr>
<tr>
  <td>Withdraw</td>
<td>186901421</td>
<td class="improved">162557664</td>
<td>607754</td>
<td class="improved">515792</td>
<td>392288</td>
<td class="declined">416423</td>
<td>4181</td>
<td class="declined">4890</td>
</tr>
<tr>
  <td>Withdraw with RefScript</td>
<td>210522935</td>
<td class="improved">183508377</td>
<td>679816</td>
<td class="improved">578424</td>
<td>399602</td>
<td class="declined">423000</td>
<td>488</td>
<td>488</td>
</tr>
<tr>
  <td>Buy</td>
<td>552474306</td>
<td class="improved">420119748</td>
<td>2026392</td>
<td class="improved">1467000</td>
<td>506178</td>
<td class="improved">495554</td>
<td>4310</td>
<td class="declined">5019</td>
</tr>
<tr>
  <td>Buy with RefScript</td>
<td>576095820</td>
<td class="improved">441898461</td>
<td>2098454</td>
<td class="improved">1533232</td>
<td>513271</td>
<td class="improved">502178</td>
<td>612</td>
<td>612</td>
</tr>
</table>
