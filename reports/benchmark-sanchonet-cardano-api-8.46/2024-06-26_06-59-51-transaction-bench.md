# Benchmark Report (Simple Marketplace - PlutusV3)

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
</tr>
<tr><th>Average</th><td>58.657</td><td>96.613</td><td>73.984</td><td>84.463</td></tr>
<tr><th>Std Deviation</th><td>79.957</td><td>98.591</td><td>89.042</td><td>92.509</td></tr>
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
<td>11.180</td>
<td>27.214</td>
<td>20.568</td>
<td class="highlight">222.518</td>
</tr>
<tr>
<td>1</td>
<td>39.360</td>
<td>19.577</td>
<td>11.071</td>
<td class="highlight">211.285</td>
</tr>
<tr>
<td>2</td>
<td>9.368</td>
<td>29.296</td>
<td>18.950</td>
<td>13.384</td>
</tr>
<tr>
<td>3</td>
<td>9.374</td>
<td>29.831</td>
<td>20.118</td>
<td class="highlight">224.383</td>
</tr>
<tr>
<td>4</td>
<td>9.220</td>
<td>30.461</td>
<td>18.316</td>
<td class="highlight">222.420</td>
</tr>
<tr>
<td>5</td>
<td>10.775</td>
<td>29.440</td>
<td>17.251</td>
<td class="highlight">264.854</td>
</tr>
<tr>
<td>6</td>
<td>9.240</td>
<td>29.399</td>
<td>20.668</td>
<td class="highlight">221.870</td>
</tr>
<tr>
<td>7</td>
<td>10.231</td>
<td>29.590</td>
<td>17.934</td>
<td class="highlight">223.424</td>
</tr>
<tr>
<td>8</td>
<td>11.176</td>
<td>28.968</td>
<td>17.849</td>
<td class="highlight">223.690</td>
</tr>
<tr>
<td>9</td>
<td>10.763</td>
<td>29.380</td>
<td>19.090</td>
<td class="highlight">222.575</td>
</tr>
<tr>
<td>10</td>
<td>9.364</td>
<td>29.909</td>
<td>18.371</td>
<td class="highlight">222.769</td>
</tr>
<tr>
<td>11</td>
<td>9.240</td>
<td>30.903</td>
<td>19.365</td>
<td class="highlight">221.814</td>
</tr>
<tr>
<td>12</td>
<td>39.387</td>
<td>17.996</td>
<td>12.389</td>
<td class="highlight">212.036</td>
</tr>
<tr>
<td>13</td>
<td>9.369</td>
<td>29.971</td>
<td>19.184</td>
<td class="highlight">225.290</td>
</tr>
<tr>
<td>14</td>
<td>9.655</td>
<td>29.735</td>
<td>18.331</td>
<td>12.060</td>
</tr>
<tr>
<td>15</td>
<td>9.655</td>
<td>29.679</td>
<td>19.405</td>
<td class="highlight">226.799</td>
</tr>
<tr>
<td>16</td>
<td>9.655</td>
<td>29.691</td>
<td>19.687</td>
<td class="highlight">223.331</td>
</tr>
<tr>
<td>17</td>
<td>9.599</td>
<td>29.789</td>
<td>19.581</td>
<td class="highlight">221.444</td>
</tr>
<tr>
<td>18</td>
<td>9.654</td>
<td>29.705</td>
<td>18.414</td>
<td>15.538</td>
</tr>
<tr>
<td>19</td>
<td>10.227</td>
<td>29.422</td>
<td>18.681</td>
<td>11.205</td>
</tr>
<tr>
<td>20</td>
<td>39.380</td>
<td>18.031</td>
<td>12.639</td>
<td class="highlight">211.123</td>
</tr>
<tr>
<td>21</td>
<td>39.359</td>
<td>18.284</td>
<td class="highlight">223.995</td>
<td>41.627</td>
</tr>
<tr>
<td>22</td>
<td>9.363</td>
<td>31.243</td>
<td>18.735</td>
<td class="highlight">222.970</td>
</tr>
<tr>
<td>23</td>
<td>39.293</td>
<td>18.118</td>
<td class="highlight">224.110</td>
<td>62.113</td>
</tr>
<tr>
<td>24</td>
<td>10.762</td>
<td>29.356</td>
<td>19.018</td>
<td class="highlight">353.215</td>
</tr>
<tr>
<td>25</td>
<td>27.430</td>
<td>28.480</td>
<td class="highlight">210.275</td>
<td>42.091</td>
</tr>
<tr>
<td>26</td>
<td>25.450</td>
<td>30.612</td>
<td class="highlight">210.784</td>
<td>41.588</td>
</tr>
<tr>
<td>27</td>
<td>24.401</td>
<td>19.511</td>
<td>11.590</td>
<td class="highlight">341.687</td>
</tr>
<tr>
<td>28</td>
<td>24.518</td>
<td>19.184</td>
<td class="highlight">263.768</td>
<td>36.678</td>
</tr>
<tr>
<td>29</td>
<td>23.412</td>
<td>21.008</td>
<td class="highlight">221.765</td>
<td>62.308</td>
</tr>
<tr>
<td>30</td>
<td>24.554</td>
<td>18.198</td>
<td>12.219</td>
<td class="highlight">253.608</td>
</tr>
<tr>
<td>31</td>
<td>23.587</td>
<td>18.835</td>
<td>11.978</td>
<td class="highlight">255.298</td>
</tr>
<tr>
<td>32</td>
<td>25.154</td>
<td>18.877</td>
<td class="highlight">222.280</td>
<td>62.316</td>
</tr>
<tr>
<td>33</td>
<td>24.855</td>
<td>18.823</td>
<td class="highlight">222.916</td>
<td>40.680</td>
</tr>
<tr>
<td>34</td>
<td>25.437</td>
<td>18.245</td>
<td class="highlight">224.873</td>
<td>42.279</td>
</tr>
<tr>
<td>35</td>
<td>24.398</td>
<td>19.373</td>
<td class="highlight">222.822</td>
<td>41.418</td>
</tr>
<tr>
<td>36</td>
<td>44.364</td>
<td class="highlight">221.818</td>
<td>42.139</td>
<td>20.459</td>
</tr>
<tr>
<td>37</td>
<td>25.150</td>
<td>17.391</td>
<td>13.017</td>
<td class="highlight">252.983</td>
</tr>
<tr>
<td>38</td>
<td>25.296</td>
<td>18.423</td>
<td class="highlight">225.642</td>
<td>38.042</td>
</tr>
<tr>
<td>39</td>
<td>25.385</td>
<td>18.244</td>
<td>11.872</td>
<td class="highlight">212.987</td>
</tr>
<tr>
<td>40</td>
<td>25.153</td>
<td>17.424</td>
<td>14.279</td>
<td class="highlight">209.463</td>
</tr>
<tr>
<td>41</td>
<td>25.245</td>
<td>18.288</td>
<td>11.590</td>
<td class="highlight">253.151</td>
</tr>
<tr>
<td>42</td>
<td>24.580</td>
<td>19.400</td>
<td class="highlight">222.205</td>
<td>42.088</td>
</tr>
<tr>
<td>43</td>
<td>25.666</td>
<td>17.220</td>
<td>12.671</td>
<td class="highlight">210.626</td>
</tr>
<tr>
<td>44</td>
<td>42.392</td>
<td class="highlight">223.633</td>
<td>43.037</td>
<td>19.383</td>
</tr>
<tr>
<td>45</td>
<td>43.097</td>
<td class="highlight">222.326</td>
<td>43.567</td>
<td>21.072</td>
</tr>
<tr>
<td>46</td>
<td>25.437</td>
<td>18.605</td>
<td>10.639</td>
<td class="highlight">253.861</td>
</tr>
<tr>
<td>47</td>
<td>27.169</td>
<td class="highlight">239.362</td>
<td>41.309</td>
<td class="highlight">241.344</td>
</tr>
<tr>
<td>48</td>
<td>24.519</td>
<td>19.901</td>
<td class="highlight">222.045</td>
<td>62.733</td>
</tr>
<tr>
<td>49</td>
<td>25.244</td>
<td>17.852</td>
<td>12.340</td>
<td class="highlight">215.029</td>
</tr>
<tr>
<td>50</td>
<td>13.235</td>
<td>15.678</td>
<td>10.944</td>
<td class="highlight">212.002</td>
</tr>
<tr>
<td>51</td>
<td>27.472</td>
<td>12.499</td>
<td class="highlight">252.698</td>
<td>32.941</td>
</tr>
<tr>
<td>52</td>
<td>14.177</td>
<td>25.192</td>
<td class="highlight">291.367</td>
<td class="highlight">100.040</td>
</tr>
<tr>
<td>53</td>
<td>11.876</td>
<td>27.746</td>
<td class="highlight">291.658</td>
<td>66.784</td>
</tr>
<tr>
<td>54</td>
<td>12.976</td>
<td>27.815</td>
<td class="highlight">251.531</td>
<td class="highlight">104.900</td>
</tr>
<tr>
<td>55</td>
<td>13.344</td>
<td class="highlight">237.838</td>
<td>41.144</td>
<td>33.774</td>
</tr>
<tr>
<td>56</td>
<td>12.110</td>
<td>27.434</td>
<td class="highlight">254.467</td>
<td>31.620</td>
</tr>
<tr>
<td>57</td>
<td>28.227</td>
<td>12.776</td>
<td class="highlight">252.574</td>
<td>21.431</td>
</tr>
<tr>
<td>58</td>
<td>28.719</td>
<td class="highlight">222.925</td>
<td>40.681</td>
<td>22.866</td>
</tr>
<tr>
<td>59</td>
<td>27.773</td>
<td>12.785</td>
<td class="highlight">251.933</td>
<td>21.946</td>
</tr>
<tr>
<td>60</td>
<td>12.919</td>
<td>27.303</td>
<td class="highlight">211.509</td>
<td>42.618</td>
</tr>
<tr>
<td>61</td>
<td>28.619</td>
<td class="highlight">225.742</td>
<td>59.588</td>
<td>15.227</td>
</tr>
<tr>
<td>62</td>
<td>12.795</td>
<td class="highlight">239.565</td>
<td>39.914</td>
<td>21.539</td>
</tr>
<tr>
<td>63</td>
<td>28.003</td>
<td>12.374</td>
<td class="highlight">252.203</td>
<td>21.115</td>
</tr>
<tr>
<td>64</td>
<td>29.332</td>
<td class="highlight">225.193</td>
<td>38.951</td>
<td>21.816</td>
</tr>
<tr>
<td>65</td>
<td>28.193</td>
<td class="highlight">222.990</td>
<td>41.312</td>
<td>21.815</td>
</tr>
<tr>
<td>66</td>
<td>27.778</td>
<td class="highlight">223.870</td>
<td>61.844</td>
<td>12.027</td>
</tr>
<tr>
<td>67</td>
<td>27.731</td>
<td>11.410</td>
<td class="highlight">213.116</td>
<td>41.808</td>
</tr>
<tr>
<td>68</td>
<td>12.690</td>
<td>26.760</td>
<td class="highlight">212.294</td>
<td>40.581</td>
</tr>
<tr>
<td>69</td>
<td>39.742</td>
<td class="highlight">254.164</td>
<td>20.071</td>
<td>11.246</td>
</tr>
<tr>
<td>70</td>
<td>28.100</td>
<td class="highlight">225.724</td>
<td>61.362</td>
<td>13.129</td>
</tr>
<tr>
<td>71</td>
<td>28.719</td>
<td class="highlight">264.791</td>
<td>30.633</td>
<td class="highlight">165.095</td>
</tr>
<tr>
<td>72</td>
<td>13.810</td>
<td>26.654</td>
<td class="highlight">253.046</td>
<td class="highlight">103.710</td>
</tr>
<tr>
<td>73</td>
<td>29.026</td>
<td class="highlight">223.296</td>
<td>41.168</td>
<td>32.244</td>
</tr>
<tr>
<td>74</td>
<td>9.330</td>
<td>18.859</td>
<td class="highlight">222.995</td>
<td>42.394</td>
</tr>
<tr>
<td>75</td>
<td>25.910</td>
<td class="highlight">211.450</td>
<td>61.908</td>
<td>13.789</td>
</tr>
<tr>
<td>76</td>
<td>14.351</td>
<td class="highlight">221.949</td>
<td>63.136</td>
<td>83.381</td>
</tr>
<tr>
<td>77</td>
<td>12.421</td>
<td class="highlight">224.357</td>
<td>40.943</td>
<td>33.096</td>
</tr>
<tr>
<td>78</td>
<td>12.421</td>
<td class="highlight">226.402</td>
<td>61.227</td>
<td>15.645</td>
</tr>
<tr>
<td>79</td>
<td>13.097</td>
<td>12.840</td>
<td class="highlight">210.577</td>
<td>63.090</td>
</tr>
<tr>
<td>80</td>
<td>14.210</td>
<td class="highlight">222.519</td>
<td>62.341</td>
<td>14.313</td>
</tr>
<tr>
<td>81</td>
<td>24.036</td>
<td class="highlight">214.504</td>
<td>59.886</td>
<td>12.183</td>
</tr>
<tr>
<td>82</td>
<td>24.753</td>
<td class="highlight">253.648</td>
<td>22.001</td>
<td>10.115</td>
</tr>
<tr>
<td>83</td>
<td>25.937</td>
<td class="highlight">212.551</td>
<td>60.779</td>
<td>10.091</td>
</tr>
<tr>
<td>84</td>
<td>25.815</td>
<td class="highlight">272.880</td>
<td>11.151</td>
<td>5.772</td>
</tr>
<tr>
<td>85</td>
<td>26.003</td>
<td class="highlight">252.776</td>
<td>30.999</td>
<td>5.808</td>
</tr>
<tr>
<td>86</td>
<td>12.797</td>
<td class="highlight">287.496</td>
<td>9.167</td>
<td>7.426</td>
</tr>
<tr>
<td>87</td>
<td>25.908</td>
<td class="highlight">210.561</td>
<td>63.539</td>
<td>9.861</td>
</tr>
<tr>
<td>88</td>
<td>25.809</td>
<td class="highlight">253.209</td>
<td>20.155</td>
<td>10.993</td>
</tr>
<tr>
<td>89</td>
<td>24.507</td>
<td class="highlight">252.809</td>
<td>22.724</td>
<td>10.375</td>
</tr>
<tr>
<td>90</td>
<td>25.752</td>
<td class="highlight">252.710</td>
<td>21.610</td>
<td>15.801</td>
</tr>
<tr>
<td>91</td>
<td>24.649</td>
<td class="highlight">211.523</td>
<td>44.413</td>
<td>18.974</td>
</tr>
<tr>
<td>92</td>
<td>25.366</td>
<td class="highlight">255.074</td>
<td>19.628</td>
<td>10.244</td>
</tr>
<tr>
<td>93</td>
<td class="highlight">238.475</td>
<td>60.069</td>
<td>11.608</td>
<td>5.744</td>
</tr>
<tr>
<td>94</td>
<td>26.209</td>
<td class="highlight">252.840</td>
<td>31.820</td>
<td>72.276</td>
</tr>
<tr>
<td>95</td>
<td>24.547</td>
<td class="highlight">286.433</td>
<td>56.189</td>
<td>49.287</td>
</tr>
<tr>
<td>96</td>
<td>14.460</td>
<td class="highlight">221.985</td>
<td class="highlight">74.411</td>
<td class="highlight">105.615</td>
</tr>
<tr>
<td>97</td>
<td>24.215</td>
<td class="highlight">253.092</td>
<td>21.707</td>
<td>14.110</td>
</tr>
<tr>
<td>98</td>
<td>13.041</td>
<td>13.327</td>
<td class="highlight">252.778</td>
<td>20.069</td>
</tr>
<tr>
<td>99</td>
<td>14.192</td>
<td class="highlight">224.579</td>
<td>38.932</td>
<td>20.529</td>
</tr>
<tr>
<td>100</td>
<td class="highlight">221.299</td>
<td>40.960</td>
<td>33.121</td>
<td>55.676</td>
</tr>
<tr>
<td>101</td>
<td>9.958</td>
<td class="highlight">252.948</td>
<td>34.726</td>
<td>54.812</td>
</tr>
<tr>
<td>102</td>
<td class="highlight">227.126</td>
<td>37.131</td>
<td>31.747</td>
<td>56.331</td>
</tr>
<tr>
<td>103</td>
<td>9.135</td>
<td class="highlight">254.431</td>
<td>20.596</td>
<td>13.558</td>
</tr>
<tr>
<td>104</td>
<td class="highlight">224.209</td>
<td>39.355</td>
<td>32.080</td>
<td>5.696</td>
</tr>
<tr>
<td>105</td>
<td class="highlight">223.558</td>
<td>39.270</td>
<td>31.242</td>
<td>7.518</td>
</tr>
<tr>
<td>106</td>
<td class="highlight">223.779</td>
<td>60.242</td>
<td>11.229</td>
<td>55.832</td>
</tr>
<tr>
<td>107</td>
<td class="highlight">221.617</td>
<td>42.009</td>
<td>31.528</td>
<td>55.888</td>
</tr>
<tr>
<td>108</td>
<td class="highlight">223.569</td>
<td>38.822</td>
<td>21.033</td>
<td>12.376</td>
</tr>
<tr>
<td>109</td>
<td class="highlight">223.699</td>
<td>60.460</td>
<td>67.616</td>
<td>16.191</td>
</tr>
<tr>
<td>110</td>
<td>9.669</td>
<td class="highlight">252.645</td>
<td>22.859</td>
<td>10.431</td>
</tr>
<tr>
<td>111</td>
<td class="highlight">221.528</td>
<td>42.038</td>
<td>32.424</td>
<td>56.189</td>
</tr>
<tr>
<td>112</td>
<td class="highlight">221.171</td>
<td>62.765</td>
<td>10.921</td>
<td>5.614</td>
</tr>
<tr>
<td>113</td>
<td class="highlight">223.241</td>
<td>61.755</td>
<td>10.227</td>
<td>5.703</td>
</tr>
<tr>
<td>114</td>
<td class="highlight">221.765</td>
<td>62.490</td>
<td>10.666</td>
<td>56.606</td>
</tr>
<tr>
<td>115</td>
<td class="highlight">221.782</td>
<td>42.195</td>
<td>21.381</td>
<td>10.241</td>
</tr>
<tr>
<td>116</td>
<td class="highlight">221.170</td>
<td>63.826</td>
<td>9.750</td>
<td>5.643</td>
</tr>
<tr>
<td>117</td>
<td class="highlight">263.767</td>
<td>30.735</td>
<td>7.262</td>
<td>50.777</td>
</tr>
<tr>
<td>118</td>
<td class="highlight">223.811</td>
<td>59.427</td>
<td>15.310</td>
<td>52.856</td>
</tr>
<tr>
<td>119</td>
<td class="highlight">223.849</td>
<td>59.594</td>
<td>15.156</td>
<td>69.253</td>
</tr>
<tr>
<td>120</td>
<td class="highlight">223.699</td>
<td>60.855</td>
<td>14.597</td>
<td class="highlight">160.075</td>
</tr>
<tr>
<td>121</td>
<td class="highlight">221.744</td>
<td>63.428</td>
<td>9.271</td>
<td>5.484</td>
</tr>
<tr>
<td>122</td>
<td class="highlight">221.841</td>
<td>43.596</td>
<td>18.000</td>
<td>11.791</td>
</tr>
<tr>
<td>123</td>
<td class="highlight">221.889</td>
<td>43.391</td>
<td>17.958</td>
<td>11.683</td>
</tr>
<tr>
<td>124</td>
<td class="highlight">221.171</td>
<td>43.221</td>
<td>19.290</td>
<td>11.550</td>
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
<td>1dc38eab42f07d5ca6a785cd8d25c75c4fe22bb20de10370f7c892c27a31100d</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>0</td>
<td>Primary Buy</td>
<td>1cba4380adda9f1b4658000460bf58d09dee5be6da3b3fe555d6309171fbc792</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>0</td>
<td>Secondary Sale</td>
<td>bb9f977e951c486267265a6d2e1921aa82c77c899cd6f01080134b11bf2d503f</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>0</td>
<td>Withdraw</td>
<td>aff65041fe68615074dae4ddbb083d5da1e9f72ee74cb9995283d63aa879ee35</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>1</td>
<td>Primary Sale</td>
<td>aa92314fa52266dcf51e4db4c6e6108aa04b649de66ade90c457af055979023c</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>1</td>
<td>Primary Buy</td>
<td>e8b58c8df4f8f60b4d85fb58d1e978287981fd1e46bb7ba8d1a03f49c4eb4e98</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>1</td>
<td>Secondary Sale</td>
<td>ffbfb272ced8492d556280aaa018adbb75acbb83d2520a2bf5cd85ad0f7b08e6</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>1</td>
<td>Withdraw</td>
<td>f5dfd3d9e4e7332af48d483739d61d0e04a85051af53147367c7bf612542154f</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>2</td>
<td>Primary Sale</td>
<td>064bfa9a51305a1e12da379dc5f62e69952c0a4036bb913104dc5a3a871fd5bb</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>2</td>
<td>Primary Buy</td>
<td>c6ae8aaa84f74c6fb4ec44e9e6cd36bf17cffd990319be11772364eeb593bffb</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>2</td>
<td>Secondary Sale</td>
<td>e3d4c6275c4e80b3ef8df27fecc20f4c6e2cdb4a59afb0ef7a4a76f638723b27</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>2</td>
<td>Withdraw</td>
<td>363e99e694eb4a4ad8267873b27e60ed2af7c7c65384d1d56a201c2ed7f8bc19</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>3</td>
<td>Primary Sale</td>
<td>0fcb5d469a95c2ea171120ba790127349b6b4a0029d1fcadb603a49bc7469f80</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>3</td>
<td>Primary Buy</td>
<td>fb1387a3a85717a8190d25cf000bca83a34651094cf8e03027f36dea010d4d9a</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>3</td>
<td>Secondary Sale</td>
<td>43aca71491b3d7015c76ac415dcb7540613c95cc43f7168dc03061eac7b8caf0</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>3</td>
<td>Withdraw</td>
<td>0508192f7303ac165b27bbf69533dbe3c24577644c83de9de9066acbbbfdcc6a</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>4</td>
<td>Primary Sale</td>
<td>17ee458c15dfbf85d6fda9ae48c81bdd67bd8b65a723086a332597da33cf68b7</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>4</td>
<td>Primary Buy</td>
<td>946a0375c5ee840a2f52433579a73d77e1c62f024afdc976b9e0a956612faada</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>4</td>
<td>Secondary Sale</td>
<td>50dbbfa88267593a9fef8df292d63a0c8d8a3d46d2a7c626384a47a589dd5ad8</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>4</td>
<td>Withdraw</td>
<td>8f4f920285b07103e5655624f537258d7af135c06673d0e9ada8d08efec161e3</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>5</td>
<td>Primary Sale</td>
<td>68fc1bd3eea06c3b729d59013195f122b5e214fbf1dbaaaba086e2cb7cd965f4</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>5</td>
<td>Primary Buy</td>
<td>7e7851a63134c11847a6aedfa9d1f45d068805eae5a492824bdd29be92d91e32</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>5</td>
<td>Secondary Sale</td>
<td>4ddf4f44ff9639fc12530f89eaf179c0cd3ecc8797da85253383a8cefcb69fb9</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>5</td>
<td>Withdraw</td>
<td>1e513c60aeb4b43650f15418ba8e9b81bffd98db221276ebe6e73acd856dcf3c</td>
<td>593923</td>
<td>1236668</td>
<td>348547128</td>
</tr>
<tr>
<td>6</td>
<td>Primary Sale</td>
<td>d5300712df413933455db89c7e0cf6cef7da0039b57c08f916c0cd497d495a25</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>6</td>
<td>Primary Buy</td>
<td>3966e13196021649a4d6f1d16c6c263a73786bfa6aa8a5d8e4e1b086076686f3</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>6</td>
<td>Secondary Sale</td>
<td>182500314e10bb383c0b6eb2f504c409075848f4d9a53608d1d7c07a5d465640</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>6</td>
<td>Withdraw</td>
<td>26bfeaf7dc74c851f8982770bc2a3db8e06eed0465f3fb44264a8999044876ac</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>7</td>
<td>Primary Sale</td>
<td>b415965a2a1e4d49982ed050fe17e7672b604707749b85a61d9e36a8475dfd7b</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>7</td>
<td>Primary Buy</td>
<td>a6800d2968b1e70076f68742072f07ad2f073d1eeb17aac5f82909979213132f</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>7</td>
<td>Secondary Sale</td>
<td>462b15f206c57533c81ac36d256fcdab7329ae546e6fd23e543f1551576f74f4</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>7</td>
<td>Withdraw</td>
<td>dcabc767f15bdab2c4d24cb9035a57f6b63a1716d2379b88f0ae59a2841a7db8</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>8</td>
<td>Primary Sale</td>
<td>7fec553c67cd233cef976dae01d5c0a5ce14c3ce247de1d2e7d57ec04a96daa8</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>8</td>
<td>Primary Buy</td>
<td>27472695d1a10057b9d1d1f83d7e24cbb74e70edf868d05da84ebbff87f5cd8e</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>8</td>
<td>Secondary Sale</td>
<td>20dddc7fb6cea0c0d313932c3aca94f4cc6298373cadd9c55389211d642998e8</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>8</td>
<td>Withdraw</td>
<td>717ade01d05ac6505fdada44cd9fd58bbd6727d601a1d45ec705f18cdeeaa6cb</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>9</td>
<td>Primary Sale</td>
<td>b0eca17ce0380993122233716fefab2079c6df22fd4ad8ebf68f0dce28a2b46e</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>9</td>
<td>Primary Buy</td>
<td>7168f19faf39859fa108112bd29c24a3f57c6cab3de2b7c24cac5cbd7527910e</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>9</td>
<td>Secondary Sale</td>
<td>5decb43a64c8546dd52f3e714e255fd9df6d7174282c6d2c2719d131dd1932a2</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>9</td>
<td>Withdraw</td>
<td>96352efcfc65a317e8adf1590eab6d05b860b2272c9743b03dbb852935f700f0</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>10</td>
<td>Primary Sale</td>
<td>855b8982fe825d60c6edf49e58a06d6ec82d92f21c5e876ff2486ae8794e7015</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>10</td>
<td>Primary Buy</td>
<td>36082615fdc0f1c46a85133d71db8f2993f558a944d493dbbc73a9fd8b5d087e</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>10</td>
<td>Secondary Sale</td>
<td>0dfd9c3b9f2514063b1ddf06df1795f6425636e28cbe62ef51400e343b70ed78</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>10</td>
<td>Withdraw</td>
<td>09949e756031c184037b9f330784cf71c72e576b92f29c90671d4765ef52e1d8</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>11</td>
<td>Primary Sale</td>
<td>bc37dfd14aebb8b9fe668c02d6392035482bef458f9a7f12026ab1f0084e4ba0</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>11</td>
<td>Primary Buy</td>
<td>abf29840ec247f9bf18fbd33be6153da00e27aaffbb4ea4d86cafba51e044699</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>11</td>
<td>Secondary Sale</td>
<td>9b6f205e040d80f53cb09945912c39932863f721caf8172d86f841dd1e8fbd28</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>11</td>
<td>Withdraw</td>
<td>f183f98ac6c16bcbc33d239a04641f1c787d060ac1a54ab120509ffc67c903af</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>12</td>
<td>Primary Sale</td>
<td>37cc421c6e973fe5df38e42afcb0234ed20732cf6ca75fc23699015ab5e08e48</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>12</td>
<td>Primary Buy</td>
<td>0938723e9cc19ea944621500ce12b0d1c5dbf006b07d3db8c3a54c8bc9df7262</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>12</td>
<td>Secondary Sale</td>
<td>9b49ffa76578931ea57f5a2fbb214090027885f0978da9e62d46faf3b48593e8</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>12</td>
<td>Withdraw</td>
<td>24c3092068df0ba0b8cdfe0bbe62dd8e0fb06ee3439ef1173f734aadfe10b82a</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>13</td>
<td>Primary Sale</td>
<td>769132e5bb5d752660f069886446ac4cd3da52ea0881f1ccd3d3ce3a127ead45</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>13</td>
<td>Primary Buy</td>
<td>a41f6100075489d56c6d87a44f70293679808ba5b31e260f175fcf28470f1d77</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>13</td>
<td>Secondary Sale</td>
<td>8578f27faa89fe5fb6c798eb35faebaee69f982fbdb8bf87e3a345cf7030bdc0</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>13</td>
<td>Withdraw</td>
<td>7313d9d3a5e372018d061080c0a316d162539525aef57c30cb68598ada912ea7</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>14</td>
<td>Primary Sale</td>
<td>88d3e6dab47a221d6020dc6e8fda81e0940fe59447aa60be2fae9b521df7aa8f</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>14</td>
<td>Primary Buy</td>
<td>e7144e590749085d2d2f398b9e2cfddca21f0595fca2ce4e8b3de2151046694a</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>14</td>
<td>Secondary Sale</td>
<td>577995d5846b93051cbed75bad7cd5c224e2416b7daf34458573abe13f7dcae0</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>14</td>
<td>Withdraw</td>
<td>04c9975196f062f0b7a1a93f3dd18d9f8e980d9621fa4ce341da886b5d3c2e4e</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>15</td>
<td>Primary Sale</td>
<td>22a6f82b9134989e23a27aa8aa15473e42a177d0184ba09e0de4ab6a36b7bb78</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>15</td>
<td>Primary Buy</td>
<td>6f0437b879fac67ea409594dc866218d71a3c64d064e450c83ace063a6110203</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>15</td>
<td>Secondary Sale</td>
<td>417a1848a10d5111e187d12d7df3ebf65e020ea60cc868911490e7a1f392dc4b</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>15</td>
<td>Withdraw</td>
<td>0541261a4ce1fe1da7c6447fd846b6f28a97e5d21b869b44f4a42857bcad36ec</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>16</td>
<td>Primary Sale</td>
<td>301697abd30fecd64ec98d47136e9edd8295dc9ba5184352cd2f60e1f1860574</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>16</td>
<td>Primary Buy</td>
<td>818a71c4c5df832c2749d8b7c54fd8919f0e50c2ae5758510c7c197b7230ecdf</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>16</td>
<td>Secondary Sale</td>
<td>4e7e24db5ca0e81ab689436596e29ae1619054b749c00fdcfd3ecf1ef81bc741</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>16</td>
<td>Withdraw</td>
<td>e6cbbb34ac7836f8e5952bd9e0a96d5db072b4c5aa910ea3c127965d3f10717d</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>17</td>
<td>Primary Sale</td>
<td>f30bb9907144124059311393c629d580ffaa70a210aa448160e1f0d97aa89394</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>17</td>
<td>Primary Buy</td>
<td>225198734247f385b8c811f9a412b67bb6293ce2450a15f3d1bb280b1f1e0aac</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>17</td>
<td>Secondary Sale</td>
<td>52d928de861405b0adf1b9825022b24cf2af61ffb9a12feff9d9a8fcecd72c05</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>17</td>
<td>Withdraw</td>
<td>d873b64fe6ff82d4d7eeaa591cd8c48e881faec614269f447baef3f55a332af1</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>18</td>
<td>Primary Sale</td>
<td>a36bca4cb53e063cc5c388c1443d4cbc0406b378e64a8892cbd7c809ba30dcf9</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>18</td>
<td>Primary Buy</td>
<td>d5f44acb26f1cfde3b11a19e02f6d9786690df8b8952e98e6519f30e4d442485</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>18</td>
<td>Secondary Sale</td>
<td>7d7799a0a725160ba5cb69e68a60ed53129ce3f248c106f1881aead38779cbe1</td>
<td>177601</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>18</td>
<td>Withdraw</td>
<td>a334d6eedcb776a76c70d4bba551d3d87175d6a6ef2a3e05a5775a53b1ea7114</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>19</td>
<td>Primary Sale</td>
<td>a5e47042b277add7c4ce0a5a641a4478ec8ab097cb66a1c953a7c08885329b1a</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>19</td>
<td>Primary Buy</td>
<td>26dd2c4cc4e1e550cd4d5ebfe2064f1ac57fc16d9efe7a832e22943341db5786</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>19</td>
<td>Secondary Sale</td>
<td>88a0ae49183181a2b69b2ec413e90dae524769442e05c277e402fc850cd33eb2</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>19</td>
<td>Withdraw</td>
<td>0220883576e947d433b225a02a166c711c4d4be65a56c2cad032f06933ecd284</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>20</td>
<td>Primary Sale</td>
<td>1f829492d1cac7751e66b6733a009086bb34c60b89922951dbf42f1c4a5647b3</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>20</td>
<td>Primary Buy</td>
<td>b8a052b34dbaf165dd23c8b4fc7b6bcb400b2ed714fbd2e14058e0c61fbc9662</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>20</td>
<td>Secondary Sale</td>
<td>86c92f02ef3e536af166ec6d857e6ddd250d75faae29bad66c64827014a19252</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>20</td>
<td>Withdraw</td>
<td>3a53423e9135fd3f26825b703b3fa2b29585d0de00445b404b2a890e826daba2</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>21</td>
<td>Primary Sale</td>
<td>0608caa6cfe6205ab9654388673ee708080d23c8e4fb9fcca1da7d30ef9818c2</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>21</td>
<td>Primary Buy</td>
<td>db6e28377372db1ad5eaba0bfd2cf95b999dd071f55e4ab6c0957ce3494089d5</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>21</td>
<td>Secondary Sale</td>
<td>75eab4f4d13b18c65d5ef86c18720461dd02a3d8b6301df8ae259b8c332a6702</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>21</td>
<td>Withdraw</td>
<td>70a741a2f0ff44679afdb9bf5452b9229cf54263ddf7c4a2bc5384be0e0136b4</td>
<td>593923</td>
<td>1236668</td>
<td>348547128</td>
</tr>
<tr>
<td>22</td>
<td>Primary Sale</td>
<td>2c21208cad863f65ad365eb8d58ce028b1359e82aec1a37c6162d11cac7b7732</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>22</td>
<td>Primary Buy</td>
<td>14f1eb8daf0b361c5e9d83cad09dec0afcc79279a1ae84e5b830897ce363c815</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>22</td>
<td>Secondary Sale</td>
<td>95eaa91ab1a07838787c8d60acd69f285b92cbe4c9caa7a371d66d80078a7fbc</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>22</td>
<td>Withdraw</td>
<td>74f0d32ea5d36dea249031dd0d7c5742c5721b0e821d6113f76bf02498c9e479</td>
<td>593923</td>
<td>1236668</td>
<td>348547128</td>
</tr>
<tr>
<td>23</td>
<td>Primary Sale</td>
<td>7a5e68e0c2ec1245d2763b2e07c5d871535b647e8a7c787a95c1ee8cf9d70ca3</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>23</td>
<td>Primary Buy</td>
<td>5edc162ad775c72a32611a2166aa127e340637714b856e65f641974c0cea9a88</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>23</td>
<td>Secondary Sale</td>
<td>2fb98423acd86c140fda1211a78b7e99b8d5b3f5db7cb5378846e40be7209d16</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>23</td>
<td>Withdraw</td>
<td>ef287837118a62cc9d9cf1a4df6a4a9e5bbcf46dc6bf580b848e79a4c34618f3</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>24</td>
<td>Primary Sale</td>
<td>d7d61eb20c0bdcdcb5763b8e87b5361a4dd3f83df800f79a738b942b020fb944</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>24</td>
<td>Primary Buy</td>
<td>e6385bbb9d68166c0ed47014e9a6dacd56839fada39dfa9ca1b302dc1f8b7d60</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>24</td>
<td>Secondary Sale</td>
<td>bab6b6b779b619cb9ee4ca326c19678fed97499c9a169c53ba2c6319a19f7002</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>24</td>
<td>Withdraw</td>
<td>ddb0518eb214fd034c88575ab10f80de00a2a7735a2ab06abf5c5aacefb07f94</td>
<td>593923</td>
<td>1236668</td>
<td>348547128</td>
</tr>
<tr>
<td>25</td>
<td>Primary Sale</td>
<td>b64cec215509e590bee6098b004830f2ed75bfc2f239f7ea23c3d178bf798384</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>25</td>
<td>Primary Buy</td>
<td>c34004004a179c9ca3a2bff026ac1c00fd87f2f5f015fca3ab2e1750202dfbaf</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>25</td>
<td>Secondary Sale</td>
<td>a2824cdd456b5b3c22c8df39d19a54f4284b650d3b913e9ad4e102d949a693ba</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>25</td>
<td>Withdraw</td>
<td>4f0178083e835576561fa5251b8b976b0de4645aaa8f273321e55e77acd1033c</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>26</td>
<td>Primary Sale</td>
<td>1f60202715c0af76211980dc00bc714d4892d4b92d902c67ff05039ff96ec097</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>26</td>
<td>Primary Buy</td>
<td>6f0ade861e28bfb09c7e576c66813431bfd269400c525652ada9575ddac4bc38</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>26</td>
<td>Secondary Sale</td>
<td>cb1a2729a32d9880ae508bc417941d6075d045213b31fe668fcd37f882d1e598</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>26</td>
<td>Withdraw</td>
<td>e3d7522d437ddac28dd7a0027401d82b9cc92271f63d3145331bc426f292bb8f</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>27</td>
<td>Primary Sale</td>
<td>5ff29f50c93b65f1d963b3ab49880741080472b075c6776202814f3013decb2f</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>27</td>
<td>Primary Buy</td>
<td>fea5a51ae4cd717743412b2ea47e170a718aac8a66460209d0856ffe94000bfb</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>27</td>
<td>Secondary Sale</td>
<td>599f1679480f534013eeb536e88d0921b4b006be2321a6e5100671ad9e554a49</td>
<td>181077</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>27</td>
<td>Withdraw</td>
<td>2f4bfeaf94f3495bddae04b538e199972a249598285e27d86d867b2bf00c5fec</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>28</td>
<td>Primary Sale</td>
<td>ceedd63d7067cf577733a0eb576e0610eab43f406cf719ca5b64bd2fdabfccbe</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>28</td>
<td>Primary Buy</td>
<td>7b019d126cf3ebe572f5731769e237406eb9dcd15eca85e66e5124047090871b</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>28</td>
<td>Secondary Sale</td>
<td>bb7ced49e4c87370414fbe6f18d84f316d275117b117ae206809e75c2adeff05</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>28</td>
<td>Withdraw</td>
<td>3ebcc53660aa2275b07973ef1f6e006cf1fba13127929e9b49eebeccd4731d9f</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>29</td>
<td>Primary Sale</td>
<td>2e1a2ec68186754b51dc2443d2d827a78440e697201a98ae6ba77f5dae4df05c</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>29</td>
<td>Primary Buy</td>
<td>7e5d81948f614fe1bba41415e783ca1a7fd4ef285cb3ddfdcf2824d5935f18eb</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>29</td>
<td>Secondary Sale</td>
<td>ea86f6e6b04bab3d31d5785d3c7c6b889d67b52b88a529380b5caf7bf414dc85</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>29</td>
<td>Withdraw</td>
<td>673f68c981ee021db2e565091ce69fcc612ed1048e097d8c5fe7f20b98699b3d</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>30</td>
<td>Primary Sale</td>
<td>99fe0d453e0beff0fc980b6312ce39760510fe646dc26a797487c461cc3b8f7b</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>30</td>
<td>Primary Buy</td>
<td>f5b6a98473d37242104f41052276697ffff2cab2675791220ea4f6d8904f1e79</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>30</td>
<td>Secondary Sale</td>
<td>eba19431d5560bb8017d1fc51c1c73cb915f19230857960d24c8a19a9aa7d4df</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>30</td>
<td>Withdraw</td>
<td>f530d94437cb0c7505b5745e7b1d0432adb8b18675ae71711dce24b81a4f3aab</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>31</td>
<td>Primary Sale</td>
<td>f0a88cb10e2f64d39c55aec30b9a33db3783c9eadcd39aee83df9b6adb00ba48</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>31</td>
<td>Primary Buy</td>
<td>04591d80731ccfa34e89e80ac76282708914de133bfd01e68b5d417295fb2438</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>31</td>
<td>Secondary Sale</td>
<td>17fe13839ff18a7ac6d5ca672ab03f0def3ca2f9424cb156bad01e494c74f7e6</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>31</td>
<td>Withdraw</td>
<td>81a33f06d6621d8889840b8b64ec102458069049334e2df2e8c445dbc5e834cb</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>32</td>
<td>Primary Sale</td>
<td>6392e845acb614f4ed10d2a513654fbc9d48cd99a6938bbd3a488ae697d5d869</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>32</td>
<td>Primary Buy</td>
<td>b512450ce2fdabd9ec884a9bddec2c8800599da892e4ff41c6003c9cfef71456</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>32</td>
<td>Secondary Sale</td>
<td>f17dcfffce8ac054bcee2f18d5b08fba52542685386174caa0ccb931129fa3e1</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>32</td>
<td>Withdraw</td>
<td>bf5b9d0e7cbf3d0e12666fc33c7972f5a2e856650c92c8003be40edc44e3ee3d</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>33</td>
<td>Primary Sale</td>
<td>f8f1a93c339a52aead20e542a48da81bd5d4a1ec0a31d5158f8e55487df4892e</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>33</td>
<td>Primary Buy</td>
<td>1955e1809ef2851766e236b814054ccd5e545307a08b53b08f2d74c8b09ebf89</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>33</td>
<td>Secondary Sale</td>
<td>02198b751009c2cb7f84e7ca70efd89cf770f2ca0dcdd36950161efef598ad1c</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>33</td>
<td>Withdraw</td>
<td>7c2a04765ced3a32c95954a9232db95482c77b73cb09a4647b7cbcdd8f8a7caa</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>34</td>
<td>Primary Sale</td>
<td>4147376daffa5319c470a9e8830253713b2f19745ef31412850de58379f1558e</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>34</td>
<td>Primary Buy</td>
<td>1d349f2722f97bc89232917d45d31add4bdaaf29d3b6f5f289b4abed1ef69cc0</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>34</td>
<td>Secondary Sale</td>
<td>a7664bdafdde29e459e1eecd7f857113387c8a046ca98783b0b5b1e762440ae4</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>34</td>
<td>Withdraw</td>
<td>8252c4449f014f427fdc3fc1b890846bb1c7a4ccaed297f725a936176570fde0</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>35</td>
<td>Primary Sale</td>
<td>c9aed3facaed8ff294fe4ff59636cbadaa44dce3fd6db4856340f813201800dc</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>35</td>
<td>Primary Buy</td>
<td>757261c3ef9b89fc19527c243c3e17cbf67bccbe4838b27de02fe35151d84444</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>35</td>
<td>Secondary Sale</td>
<td>6da0ceab9f805d4eecbdb4e6bc18b592aec8c4ada6b25ecc7cd46094fd3928c1</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>35</td>
<td>Withdraw</td>
<td>f9d6e71a65787c27a3f827f52c2d4f13963d43b52b439e63df3424dc2e7b1df7</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>36</td>
<td>Primary Sale</td>
<td>a31ef54252b8a80c571fdc633587e7e58e9df804342b4689660143df21e33036</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>36</td>
<td>Primary Buy</td>
<td>dc7bd1edef5c1b998e5ff491aada51787abdcb26a46b99c0a9ec0df80e7e2c8a</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>36</td>
<td>Secondary Sale</td>
<td>d4a04c3cf40aa37aa72ed596d0e8cd21d235da044f95b60956167226172deb1f</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>36</td>
<td>Withdraw</td>
<td>a43d45426f3980f2b49d420b4f9a427f3e1e315598d747dfeac9ae0f5ef325c3</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>37</td>
<td>Primary Sale</td>
<td>36f3e789c3d8d38caa210edc1f5341cf2213b49fec051c40355f64117e8fc4d2</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>37</td>
<td>Primary Buy</td>
<td>2598cb107b4a20474223e75c1c5a3a0dc843fba4f65448bcef18f7d07d280a4a</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>37</td>
<td>Secondary Sale</td>
<td>d3096ada2d4b3530fd8214f7e97c84d7fc082c2068d6382aff0b7551dcfe3a0c</td>
<td>181077</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>37</td>
<td>Withdraw</td>
<td>6d3d279fc42d941fd12ab49a4e8347006cbf643cf9b52b6874f2d8641b0c248e</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>38</td>
<td>Primary Sale</td>
<td>dc41b6756de11a7f2e1fd5449620eee9e1519a5d08e9d806e00f92ad275f9510</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>38</td>
<td>Primary Buy</td>
<td>c6c0b260d4798da485657691915ad6f40416a1f2a447d8ab8344cf7f65ca07ef</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>38</td>
<td>Secondary Sale</td>
<td>aad041100611f48f1651d772f525c6e87e597dfc65fec6633b6171d654938927</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>38</td>
<td>Withdraw</td>
<td>669bc0609cc3e46454f664788424a0af493faa47520ea1bb20c7d625062e7c99</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>39</td>
<td>Primary Sale</td>
<td>11d2abac0418b5d14efb6eb9deb96333b22422322ea0c78950e51ea309a86258</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>39</td>
<td>Primary Buy</td>
<td>b755d442caf65cf726575e7cd625942b74a79f341bd8a2e416ed28839d7dee1e</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>39</td>
<td>Secondary Sale</td>
<td>0b7dbc804d01e09c78602be9555977dbe186702325edca5cd07770dd659ddbdf</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>39</td>
<td>Withdraw</td>
<td>829829ec12efd482bfec54cc1ae34f016c8c01765223ba2ad6798f0dd80a35bd</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>40</td>
<td>Primary Sale</td>
<td>459dfb938157db997a4599831f5774b6e7447f2c357e729f7b426ecf44086976</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>40</td>
<td>Primary Buy</td>
<td>66efe237828374fb4e6f35d44d9609d1b52a1ec52f8361900919574d6b45f6cb</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>40</td>
<td>Secondary Sale</td>
<td>3458c2b61cc78a26472a5f458f9dc8d0485ab736b10dd889cf7114a7bb7844a7</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>40</td>
<td>Withdraw</td>
<td>37792ebaa416143e16b02e655dc272a0d849348f98fe78bb46e8958700b95c2b</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>41</td>
<td>Primary Sale</td>
<td>082357c0ca8199e4646815e16bd7250f5839d18c2056a8d3739e4d0f97963b2a</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>41</td>
<td>Primary Buy</td>
<td>dbab222b25ef85212a66c6ae853b3caf08e51f641168a4c211f5a5dbd104ba41</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>41</td>
<td>Secondary Sale</td>
<td>146c1aa7edc6fd0d658b5263fac52f033372f3e1cff24fff5f20a316b8b1cc3e</td>
<td>177601</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>41</td>
<td>Withdraw</td>
<td>42bdad5b7259c8c8f8a344872f5d618079fdf6788882a991cdf30714ce635a06</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>42</td>
<td>Primary Sale</td>
<td>9be24ae853302ff90f502f6fc5486735b212b42a97c5697f1d80cfb66c2c6ea0</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>42</td>
<td>Primary Buy</td>
<td>8a53c1d94f92e9ed0fd1ee567e59de0838cfa9b4aebdfe3b27c72093e78dd001</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>42</td>
<td>Secondary Sale</td>
<td>39f99ae15e0948333e07b7ca7141ce57aa854e6d23ae3da7a3882baeb02439c7</td>
<td>177601</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>42</td>
<td>Withdraw</td>
<td>a332a880632a80b668dfbcc262ef0856b4bc3cada12655618f7fc0846eac4821</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>43</td>
<td>Primary Sale</td>
<td>c65156a8e16001faf46d24ffa84c7b28dd542d499b248b050ec825a6668d4549</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>43</td>
<td>Primary Buy</td>
<td>183c44f4e2010ea72e9a77e3d12dc574349c1dc773c1b3cb752c2848acd5636f</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>43</td>
<td>Secondary Sale</td>
<td>d01ef6d4b7e12261cc6b3e6ecca0859a395d176eba9783f91dabc50c8fdd7668</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>43</td>
<td>Withdraw</td>
<td>ecfcbd8b57d2c291288a51a841e681054ffc0c8d014ced381987c3c9a6c505c6</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>44</td>
<td>Primary Sale</td>
<td>6242a2c26e9b93206ebad86893340afb22e6a7bc04fbc93b136239f1295dbc0f</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>44</td>
<td>Primary Buy</td>
<td>07c4443cd4fe2874ebe6ea8b863bd5deb1d988a8b9fd3d839f374b4d45455311</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>44</td>
<td>Secondary Sale</td>
<td>0fb37555f93651fad16c65304a6e1f6a3266479805cd36bd465eeed773082b83</td>
<td>177601</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>44</td>
<td>Withdraw</td>
<td>ede8ee03ba0bb4d23044cdb4d9defdbb4d3a39cc5927fbbfa1dcf2d9b7044447</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>45</td>
<td>Primary Sale</td>
<td>7fab09707d0f8cb836bfab3519024303c51d5eb1e2e9e05a4be433c6740b058c</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>45</td>
<td>Primary Buy</td>
<td>a8034ba71c2643d1d0a4e621fe57d167ba2685f4bbc450f15c3de48b396bbd3b</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>45</td>
<td>Secondary Sale</td>
<td>06fad98c0b1b22e542fe96910e67b434d43b96d1682ce8e7e204fc2e7d392346</td>
<td>181121</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>45</td>
<td>Withdraw</td>
<td>41267d37356fbff21962619c7015993317d643d1d226abce07a1c8b72c026d0e</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>46</td>
<td>Primary Sale</td>
<td>9ea7390f7223fad3843560fd07c9b10c14ed553619354579c1ea879d215c66d6</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>46</td>
<td>Primary Buy</td>
<td>ec29c351fe91194b9ed099527fa13bd01964d2acf8ff6c4d85cbbcaddda01882</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>46</td>
<td>Secondary Sale</td>
<td>abb8377bb497f67a2af2eb254c5822325a6914339f617be1ca2adfec60abe124</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>46</td>
<td>Withdraw</td>
<td>ab5387d4cb1d19b78a44611f02cf0dfd191b639a5393a26670de9e7f9aac3093</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>47</td>
<td>Primary Sale</td>
<td>9f7db3b4955c2d5dc03653b8e0e8537214f09cb91e8474fb11c736f7cc9e6894</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>47</td>
<td>Primary Buy</td>
<td>9d44d23827c75d541aee52b8b5284b570b4312c9a62b479ca8109356975a3cdd</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>47</td>
<td>Secondary Sale</td>
<td>5d27eb3ed7d25968da2b949c1a67c6876ce1321980e67333e95ed3b39a6627da</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>47</td>
<td>Withdraw</td>
<td>748e92370732f56ea9e12e6c4ac408ec97e49cf8a8c94e8eff63ea6e0a4ff4a3</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>48</td>
<td>Primary Sale</td>
<td>14760b90ad675667ee6a340143f82a9ac3a7d8730ad71aa67a451a934e6008c5</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>48</td>
<td>Primary Buy</td>
<td>88d7365149cb5c7fd2d5d029d6fb0b84aa704f1a5d5a3749bceb1177f349fc55</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>48</td>
<td>Secondary Sale</td>
<td>a2b514681e42ad17d8a6c0216aa3d3d7a23ce7bd5622abf291dc2114d3f5cfab</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>48</td>
<td>Withdraw</td>
<td>138d6c5f532a51a7bf2e93e190c0c9ffa78b4f0e96baca634373681615021413</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>49</td>
<td>Primary Sale</td>
<td>e6b7a16cedf0e0a5d3188e5bd2481ec985ab01807f0a943e65cfb88eeb3bfd9e</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>49</td>
<td>Primary Buy</td>
<td>489f4b20e13235d86a712610b2edffdad644bc21e0d7183ea8b05d13f25f1c87</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>49</td>
<td>Secondary Sale</td>
<td>c23f96ca0e9af8ce840b899c64253343204fb382a498e48c5ff9778b9a5ef244</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>49</td>
<td>Withdraw</td>
<td>b1dd3f133c0fdaff4ec85a90b6f11e3c425764d0d5f1b4fbfbbbb4c7c7934c54</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>50</td>
<td>Primary Sale</td>
<td>2408b384037177cb90698f9fb8cff4e0d1b54054c02a6d36f4c11fee685323c4</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>50</td>
<td>Primary Buy</td>
<td>088375db51973dc244ef4884587baf246cedd8af8dbcf06c47cc417a325dbb2f</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>50</td>
<td>Secondary Sale</td>
<td>c25693f2aae832a3ccc6e4dab772c65f5937c15d94f1177cb9e417d61ba8c474</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>50</td>
<td>Withdraw</td>
<td>b3950e6a7b7be5b4cd2a2fd1ec8d730e875ed7d1ea6ff3239cc952d91b96c3eb</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>51</td>
<td>Primary Sale</td>
<td>7860cf8bf55199e8171f96cc1466bb3e88e315bb8b23459ea6b7947a8949bef1</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>51</td>
<td>Primary Buy</td>
<td>db857138c4eac07791e98e5369a34dacba40c41b55cf32ffe17d334c9e277a56</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>51</td>
<td>Secondary Sale</td>
<td>606beb6f203dc17429343d9e96d3769b3d8a848e3ab9f0ba69c9cbe8a1c9b727</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>51</td>
<td>Withdraw</td>
<td>b77ceeb4c2e5f031434f3a7b68a567949c98fcecd5b163f01e47ab08f177e22c</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>52</td>
<td>Primary Sale</td>
<td>86085854545a45f588c22f91ecb082c8b7211737f8a1df1344aef7241e0b7e04</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>52</td>
<td>Primary Buy</td>
<td>49e28d84499160f9b976a4a19d82f90dd9e69011cc89cdb06fdb91373595e4c3</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>52</td>
<td>Secondary Sale</td>
<td>aeed065387c73b0bde97be39744c487caad2c2985df282b3ce901d4d813104e5</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>52</td>
<td>Withdraw</td>
<td>e404d79cb812eb0f19571067885a9e79a34938083d9f1057806f750717623652</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>53</td>
<td>Primary Sale</td>
<td>6e22f6d71a47c630b9e0e0de9d39bcd5642bfd8fd901a44c6dbb070bce0d7f57</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>53</td>
<td>Primary Buy</td>
<td>c5ab4834217fec6b2a9dc0ccd20fc57898fe401a4a45ed70daf7d026954db1bf</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>53</td>
<td>Secondary Sale</td>
<td>feb89eed7b6cc65a2606fe99c0e032a1957755ed81e9bf8d162237afc693cf80</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>53</td>
<td>Withdraw</td>
<td>b942d7b7bf609da58627c0623e6789116acc14f724d78c65fbef00e740116c00</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>54</td>
<td>Primary Sale</td>
<td>b038b14253e308dc76dc4b65619d93204c58016f2c45032b3f744d84a2d716aa</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>54</td>
<td>Primary Buy</td>
<td>fed71b2f13be56fd4b5b0814ad34752b618fbd23dd2ca59ba12412a6e824c946</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>54</td>
<td>Secondary Sale</td>
<td>404a32be6b536bf45e29647218753913a10d30221b6c0cf8544b71aaae4ed74f</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>54</td>
<td>Withdraw</td>
<td>67c1ccb99a18c054aa265b6fbf76050a186f6002b990efa73ef6050a7178fb7d</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>55</td>
<td>Primary Sale</td>
<td>13516cac996e76159354e466eb24cca76246fe8cd86fdc629270bc3179bcce16</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>55</td>
<td>Primary Buy</td>
<td>7d8e2aa091a1c33864d8d0cc7d3441e233b616a7a605c5d2a58adba4f3efe813</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>55</td>
<td>Secondary Sale</td>
<td>2949ca3f81477c32491a2c1397308377f39dfa65e4d84288411623adad57f47e</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>55</td>
<td>Withdraw</td>
<td>3b28ce35f74fcc92fec3277c04880713bb798a5cf52061cbda513b3332618c6d</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>56</td>
<td>Primary Sale</td>
<td>f28df2c92ef1ef3e1874dd43038e9c4c5a7172ffce78a0eaad34cf99710c384b</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>56</td>
<td>Primary Buy</td>
<td>8ea1449541927697e06626583772cecae17971e12ceeadfa66b1736272438a53</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>56</td>
<td>Secondary Sale</td>
<td>bfbed0188eacdd7a0714338ad466a8469f199195a0935dc9f3826e904bc213db</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>56</td>
<td>Withdraw</td>
<td>5c519370cf2bbb46ea7abea2bbe7897f8638edfab60f2858d99817b9c4bc3add</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>57</td>
<td>Primary Sale</td>
<td>ca6070476061d555483bb27264596923cb1d956bd3eb9e82ba4395a76ff8376d</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>57</td>
<td>Primary Buy</td>
<td>493ad1835997859b6b6a0f85712cb402e75a8da20585e71c64d7f9d66add9d54</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>57</td>
<td>Secondary Sale</td>
<td>26457648d32c40c453464ab17fe841d884c31829fa5510810e575177418ba947</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>57</td>
<td>Withdraw</td>
<td>6577b4145458801069688112dad4a5f124d3d4abc0370955a764950e20d0b58f</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>58</td>
<td>Primary Sale</td>
<td>2e1b3a2f864b9610b3144e9a2895a9e69b3d395a314b2492d65c5d73aa293174</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>58</td>
<td>Primary Buy</td>
<td>f9d00f0522a431035bc41ed5d601709b867d7f73c40f805c826fbee0ca8226c0</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>58</td>
<td>Secondary Sale</td>
<td>6cc1ce9b937bc715818bf2d1d74acfbd7feb43e23dbdbbc75517ef0b86f99e23</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>58</td>
<td>Withdraw</td>
<td>5a1ecec0ee73194b1e32d80338c9db1ee762b7772f2eb5c541864c15d9f82fa6</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>59</td>
<td>Primary Sale</td>
<td>6e1702f32fdd113c1ea90864ddeaecda9067fea22defc1caa148b773653b84a3</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>59</td>
<td>Primary Buy</td>
<td>13cce47087bf1f557c315994a5140638175ca072d5f5cd25bc52b66b572c3ea3</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>59</td>
<td>Secondary Sale</td>
<td>bde4bbb8c577e00b7e663b2fcc66323944965cc1170d8098b2830b3ce4208875</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>59</td>
<td>Withdraw</td>
<td>7c9bc6a2b29bcc8e94fe64bda58a14b1e9cec8ed462451ef5ff367b66340d426</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>60</td>
<td>Primary Sale</td>
<td>a89306b7931de2f2b675cf6177a4913938395df7af7ae576c1e771da6f360138</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>60</td>
<td>Primary Buy</td>
<td>2b78f1c3abf5b83715bb62693636cdaf496bdecc5afa5ac9f464f9c41c04631c</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>60</td>
<td>Secondary Sale</td>
<td>56ce43612f761ba0f0f5448f9b8d7d6c8b24ca44bdfdf2f577f75cf36089eb7c</td>
<td>177601</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>60</td>
<td>Withdraw</td>
<td>3a2c2a0fefc3a9d01cbdfa6a8757f35413bd540fe0f823bacf17633fe2ed823a</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>61</td>
<td>Primary Sale</td>
<td>cc0ee233a3f5f7ed90f4b966cbe7e0fac7517dfe87beb09d6e64f87cf331bb1e</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>61</td>
<td>Primary Buy</td>
<td>f000628204d5e3d53c44546241f9f9347b365c5fef51270048eae81e2bbd1bab</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>61</td>
<td>Secondary Sale</td>
<td>403cb65e984f7006271e85a9d1529cabfbdd1cb9cfc636672740912618fe558d</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>61</td>
<td>Withdraw</td>
<td>cb53ef426b61ecb212c4151e4fbf0d0d24ceec5146a1c05906c749166ef24011</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>62</td>
<td>Primary Sale</td>
<td>ad35c559384ca230e85818615ead13700a458b846b1d417b8586bcf24396bd51</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>62</td>
<td>Primary Buy</td>
<td>db5fd37820cb699d884c1c1c7287f710089f71b1180ace01df5af6539fa90142</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>62</td>
<td>Secondary Sale</td>
<td>2c403438237b8c234afee3793c7de07c00006ca3a59531c6ca7ffefbd563a2d0</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>62</td>
<td>Withdraw</td>
<td>69cc7ef7d05d124c86323f1e6a5fb3e9fd1fbfee340fd2a9dc85b7c3dc102933</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>63</td>
<td>Primary Sale</td>
<td>054b81b498ae52d5fb7f27bb6389024a7ee4ad6e216fd8807454f62a1a23bb84</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>63</td>
<td>Primary Buy</td>
<td>e188103d676bfc06ec4ad9771aeb4612e53eaadaea129904522d44a712ae89db</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>63</td>
<td>Secondary Sale</td>
<td>7ef8c765a4a40a6daab397f642999e22ece011607f0248afa22e032bd8400cef</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>63</td>
<td>Withdraw</td>
<td>614584555cfd40d904b50064df3220044eab42077b37dc7fd2f31c14bab24f69</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>64</td>
<td>Primary Sale</td>
<td>ba3332dab9c21a87f6af5e6ee169809e9c247482afea621100e45edc01022395</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>64</td>
<td>Primary Buy</td>
<td>3caad202cf491671f805b6b65d02d2e528ae22e2ad8c1ebb568eccb34b590c45</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>64</td>
<td>Secondary Sale</td>
<td>bfac9ce65d29a1c6df3a6178ba6b9197d0bb4511af6ade9a3420e42e2c955413</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>64</td>
<td>Withdraw</td>
<td>64abc9b40f58006709bc7c6bcbd251ebf48c50139ea7f52384b17671c69a84ec</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>65</td>
<td>Primary Sale</td>
<td>fdb0cf8fb17a83a2029423f38220fc03109949a6a268c828c88882a0ca062911</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>65</td>
<td>Primary Buy</td>
<td>f00353261323d9a32baedb135d9da93f173bcc774f84a9677d46c7d581bbbc97</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>65</td>
<td>Secondary Sale</td>
<td>cb516b6e6852820c565a9222e415685f1f9fe2153eccd4fa1081deeca19c5f97</td>
<td>177601</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>65</td>
<td>Withdraw</td>
<td>d455ac07cd23213ca50039073b145fcdad1c162640406e51c4a7eed9463a3f7a</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>66</td>
<td>Primary Sale</td>
<td>b66682fa85d647892e3c9528b5135c66e5815beabf4207f604351daf30733c20</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>66</td>
<td>Primary Buy</td>
<td>b1380f35be2fe19791e073229e14869410942ac5651c30a7fbef351f95944d7d</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>66</td>
<td>Secondary Sale</td>
<td>4f0c6b9416102870feaf5677303b57718819cc64055eb9d91fd8b250b492d5d0</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>66</td>
<td>Withdraw</td>
<td>d2a3788ba483a0fe178e475b0baddac64c53f28f7c8a5b997e010466edea9738</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>67</td>
<td>Primary Sale</td>
<td>38a96fd6253088f113f78d33adcff6a44034697a970eafdf8d60d4f00418c9ae</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>67</td>
<td>Primary Buy</td>
<td>6c201bb6517ebe67188e3a85470f4d1678f2e8e82f13c4247558e3e0d123512c</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>67</td>
<td>Secondary Sale</td>
<td>c95ee430b9d055c4d693957ded386d321464a96e5770e07ac9df7efbc9b5f706</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>67</td>
<td>Withdraw</td>
<td>c4517067ff73277b41e5335738c410c2611ca19d0552fd2361cf97b822d18a41</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>68</td>
<td>Primary Sale</td>
<td>f094b597e156f0ce99f283d9e70e6e2a740e2af14089b566d8d4a995a7466e11</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>68</td>
<td>Primary Buy</td>
<td>f7c13565cb0955527c993ab9e1a29652d8c326ad91418ce7e326bbaaae8be483</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>68</td>
<td>Secondary Sale</td>
<td>3d1e2112f153b741977e478ab0c8243fffc0c07ffc1db5395a6279e29013c635</td>
<td>177601</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>68</td>
<td>Withdraw</td>
<td>34b0199035ad9610900eeaa8b5922c1376c557b10cd73a8c19e2327ffbaabf97</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>69</td>
<td>Primary Sale</td>
<td>9a9ba535be017b4c78169c4be12ae6f46b2a4129ffd5f6c2a2da1da90975ad9f</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>69</td>
<td>Primary Buy</td>
<td>cb91dfa047beb48b2f38a3122c85b46dd6b83dbc0b4975a73b0155944fd6e9a0</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>69</td>
<td>Secondary Sale</td>
<td>397bd0e544d8a439eb9e72f423aa40306180bbfeb84a602e8c3e3bf91c9c350a</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>69</td>
<td>Withdraw</td>
<td>783f47a106bf203a8d3431b840b20bab8f23217b4b07517744874ec4b709ec80</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>70</td>
<td>Primary Sale</td>
<td>6bd580fd4ef01d35ad7c39945f36fbb82014bbd223242b0577e787be689b6d58</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>70</td>
<td>Primary Buy</td>
<td>28fac1e63d53f803f391b53e08c2d28e39e98b1af2f956e31fc9bb2ab8a4fb50</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>70</td>
<td>Secondary Sale</td>
<td>fb8c4368157f725bdaa9bcd3053edb6a4f0809746febea06f739199a4086108e</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>70</td>
<td>Withdraw</td>
<td>9dda2cca8ad385e364400dfcb560462204d5051df46f34930902c37b11e38ce0</td>
<td>593923</td>
<td>1236668</td>
<td>348547128</td>
</tr>
<tr>
<td>71</td>
<td>Primary Sale</td>
<td>2ac06f12d63f88638ba44967270eba22bf6a12e1db5b00f9c59f05a636988e41</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>71</td>
<td>Primary Buy</td>
<td>a1cde658130de96b1d2c7df64a4c2b483856594736ae4d157e2242d007702753</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>71</td>
<td>Secondary Sale</td>
<td>d6d3cc6f2d7318c05584b339dab5ba52bace76d4e3495d009501d5bce98e0503</td>
<td>181077</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>71</td>
<td>Withdraw</td>
<td>0dd1b1b2ea296d6425f34e62838cd7692cc658158728728e869ae1e22d06e9ab</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>72</td>
<td>Primary Sale</td>
<td>f4283d4a4735e6fc6cc9ed5f5e5881cb38f223a8efca8cc265a1bcbf36905e58</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>72</td>
<td>Primary Buy</td>
<td>232e815bce604fe13bb33f62c4925fc1a1a38649e100f93d5521b8deaa1b80d7</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>72</td>
<td>Secondary Sale</td>
<td>cc5c3ff779c2c47fc968a4d39f1f85749a0ee4e18041704d20e0460b6d963c6f</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>72</td>
<td>Withdraw</td>
<td>cb30ede82697c75d607feaac8e2576621e0059850942dcc41f93bef26441433f</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>73</td>
<td>Primary Sale</td>
<td>405cea118327584a69e358a08692889c040a09d572ea957e7acbde85fb622fdf</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>73</td>
<td>Primary Buy</td>
<td>33071cc86a955d76cca4994bda2f6e17c7718fa4388bb3630f4f3f3fa812f04b</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>73</td>
<td>Secondary Sale</td>
<td>38641f67993425fd80cc6e7343aa26d50dbc25230b62853cca80c444d1760b21</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>73</td>
<td>Withdraw</td>
<td>3ce59e3481f1e05eeb7296348f336d791d7ab8c26b7884cde5a2ad91d9d9ff78</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>74</td>
<td>Primary Sale</td>
<td>86841956cbedaca4001cc1e7d84cf4573052b6ab51e1cded9c97b022edc69e3f</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>74</td>
<td>Primary Buy</td>
<td>27acfa3ea57f2706e814b35f0685cadd4604f77abfdc57eae24a8752de9c0a31</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>74</td>
<td>Secondary Sale</td>
<td>b20c102d71aed65ffaf191e6c76af7e4af111a74fdbbba38d25949de5ba76049</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>74</td>
<td>Withdraw</td>
<td>09c39f3ffc21337581bd3d0c4795b01464376c4425a476b3016c17eb50afb53c</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>75</td>
<td>Primary Sale</td>
<td>d7bbd5ea3a35f7039f54ce570874f9f83973266864666f31618cd1199d39cdfc</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>75</td>
<td>Primary Buy</td>
<td>dfa02133159729125325b1733c6d19811a54bfadcbf3b1f40c8a522017f999e7</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>75</td>
<td>Secondary Sale</td>
<td>ea1a8eccce163081818b3a89aa1264621b1dd0397e616338be92f823d1958cd3</td>
<td>181077</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>75</td>
<td>Withdraw</td>
<td>87161859625d3639014ca89084da86ba39b27e40e3677311b7a9390ab6738e96</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>76</td>
<td>Primary Sale</td>
<td>274b05fe5ceb7c4b4fc565d439023303d4a14ee76f334453dbce4693778be955</td>
<td>181077</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>76</td>
<td>Primary Buy</td>
<td>a868901e035853676b48b58b161054580779beb226e463eb8fbcff1817ce5ffa</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>76</td>
<td>Secondary Sale</td>
<td>0662f299edacadd55b4b34750cd227f7e739ba5be4b218d75ca545cf12960f04</td>
<td>181121</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>76</td>
<td>Withdraw</td>
<td>4f2fb4df4bf020a93da8dae1463d1eb22dd3ef590c8cccade7d5e68cdd888db6</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>77</td>
<td>Primary Sale</td>
<td>94ecbd76f45838b7baea230fab79f7cb937869b51afa70f2605a1d0e3cd39b22</td>
<td>181077</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>77</td>
<td>Primary Buy</td>
<td>983e005b58b656e05c98962459f89541544074a00e0be3fed5781a202a3f4f9c</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>77</td>
<td>Secondary Sale</td>
<td>08544f2b9882526ba1b6d1f043724988dbd2a4b2c06dfab5713acb69128679bb</td>
<td>179185</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>77</td>
<td>Withdraw</td>
<td>58bd2cad00eaa8dc5f90136bb21cdd4904c5318eadee68177f27c81236025211</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>78</td>
<td>Primary Sale</td>
<td>24ee08b52941d957f607885a93114ed1c6cf83c345f23ebcb044ebdb3c6634c9</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>78</td>
<td>Primary Buy</td>
<td>a9029b91247802deb4bc79aec8eae57b2a41068bb41cf84cec69ee2e870bf893</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>78</td>
<td>Secondary Sale</td>
<td>50b41e86db61113b8932d2d680dcc3c8eeb8cacb3d936cc1ab201e93f4371d4e</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>78</td>
<td>Withdraw</td>
<td>18ab617bdad41bd1b8a4d2f4051ce3557d77971e035408833f9553acdbb6586a</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>79</td>
<td>Primary Sale</td>
<td>d7452dea15d9bbb7c960dda454c6b79419915a8a885fa3e1ab244153e816e156</td>
<td>181077</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>79</td>
<td>Primary Buy</td>
<td>393f31ed437a228eac262303e8ea23e813845154a9fb298a1bd44cbfe34eb7fd</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>79</td>
<td>Secondary Sale</td>
<td>d064cddb993b9006e9007a549b0c620660682aaa56d3c508c7eaac24ffd8e2ca</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>79</td>
<td>Withdraw</td>
<td>e9b43395d01f5b7bb30be8dfaa98ef772ce4fb27559a6d5b935b52c86c472a7a</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>80</td>
<td>Primary Sale</td>
<td>5dcd86260c4589b1a61c10321c901eb50b24602341a1ef7510ea0df8b3695e39</td>
<td>181077</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>80</td>
<td>Primary Buy</td>
<td>96042ccafc24baaaa5fa482ef53b6bd6ad781987db6764170ec91b6683d84c18</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>80</td>
<td>Secondary Sale</td>
<td>6de1a9bb80384c269e984bfcb104dae573824ef204766430c84aaa8ca5390cfc</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>80</td>
<td>Withdraw</td>
<td>fdcf42eb2444dd8da95fb401e3beb69084e0cf567d2e996b952f6bf249a2b614</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>81</td>
<td>Primary Sale</td>
<td>bb07c16a4a35365ed8b289921f1420440b5b473d5018867a844fd851310b9f39</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>81</td>
<td>Primary Buy</td>
<td>cfabd504221eb85ca984d546cd98c01936fd2153294bacb8b6580c2c08daba3c</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>81</td>
<td>Secondary Sale</td>
<td>2d1225bdb97117584d7540f5106236dcd8f7e9fa3fa2c79e53c8d5ebdd46220c</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>81</td>
<td>Withdraw</td>
<td>1d2c3badde44eaa0f8940de50fea05d3deb58629d83c058e220cf0443c65f1e7</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>82</td>
<td>Primary Sale</td>
<td>fdb73ae2379da0d4ee21374b4a58ab110bc965070c4705b52b3bbd19219549dc</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>82</td>
<td>Primary Buy</td>
<td>ee7ea08cd97ad15abc683c92b2b6040910a91603609861ac5b552f2c3f6e2cce</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>82</td>
<td>Secondary Sale</td>
<td>c041ca46c959d557660938880f0e9c9fb64a6447ac58d7f12c3a985ee0ae5b66</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>82</td>
<td>Withdraw</td>
<td>1bc4c0702a61885604203c6486bb4e07d137d74c90b8794979323033b6468a23</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>83</td>
<td>Primary Sale</td>
<td>161f5b8a38b013e294e3bc1012e9a6929c771f0499e8abf782affd8ac18911a8</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>83</td>
<td>Primary Buy</td>
<td>d9632269ac4bf7b386024429f5a0aaaccdc471c82cf8d01360b1835506ea4f5b</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>83</td>
<td>Secondary Sale</td>
<td>cee0316c17b89b1f532e31747ee3eb2f11fa0c76480cdb5f1b34ffd92aa87c33</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>83</td>
<td>Withdraw</td>
<td>7022c882ba15f4965b6b39efb2130487088dad3b83ccb78f407a9368e8a6de17</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>84</td>
<td>Primary Sale</td>
<td>bb6a925cf4a62080268ca637d5d581dafdadf59efc3c493082bd6eea94e173df</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>84</td>
<td>Primary Buy</td>
<td>f643ec2759cc22232bb1e74cd092279d239f952ffa8978db45163bded87edfdd</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>84</td>
<td>Secondary Sale</td>
<td>1ef7a3aa15c3f095de5c94cd774f0048834156bbdeebe735b2508e4fbc7f9319</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>84</td>
<td>Withdraw</td>
<td>54ce746e532bf6008c9c1652aadfcdeafeb6c5d634daa54c1211056a2efff003</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>85</td>
<td>Primary Sale</td>
<td>d7c67cd96fa95171187770411f760e1023e3f83a6d22d7e35aa10670bfd6614b</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>85</td>
<td>Primary Buy</td>
<td>58f51717dbac406f7b4a02fb1676b439ac57fcd74b818c10dc7b64febf1eb067</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>85</td>
<td>Secondary Sale</td>
<td>624ffd08ff28f127088070d80590041f48f3b8b5cce7123b935740c2b992f443</td>
<td>181077</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>85</td>
<td>Withdraw</td>
<td>f966f60a41315ec9d112537842051adeb1f95c9dffdd0d24d4513c34de301284</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>86</td>
<td>Primary Sale</td>
<td>037fe08572fe3bcbe9f219061c74d7c8cd52a9ad36015b7a10d18cd9dc2e1374</td>
<td>181121</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>86</td>
<td>Primary Buy</td>
<td>7f10590b5191a3da8e561c556c628650110f85195e2e3adde03eac50080028e5</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>86</td>
<td>Secondary Sale</td>
<td>9027ae0158a640b48046cf77961bc6941b035de8cb0e28aa453104918dc3ddce</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>86</td>
<td>Withdraw</td>
<td>3e7d7487fecb288039edc3ce910f4d0fbbdee93b38432ffe40c9989ff79ef9e6</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>87</td>
<td>Primary Sale</td>
<td>c2bac3dcf490536cf02c0ef6aba92e87be22f89a819a99989c99549684e304fa</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>87</td>
<td>Primary Buy</td>
<td>d8cd58671215b43a1b0c1a33e791171f6f1616c25db11c246708fd44f45f13cb</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>87</td>
<td>Secondary Sale</td>
<td>6862e2430d588ca869051dba383432c17337ce24942a89e0dbae60beaaba8d8c</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>87</td>
<td>Withdraw</td>
<td>14adaa5e265a9eb171b35841d6d48237e000f0702a8ed6a6bfba527762c0fcf9</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>88</td>
<td>Primary Sale</td>
<td>91e178244ca463602dfb92ccb767b3b7c4c520f9102a0b6cf139cef57c81a014</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>88</td>
<td>Primary Buy</td>
<td>da1e62131f68e821b8d45e73656a403a8e8e74eb8f368cab8eca0c5e99cbc9fc</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>88</td>
<td>Secondary Sale</td>
<td>afaf5a55f37f53a864cb84184973f38366ae41bf05c7ddbf28cb929128ba1df4</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>88</td>
<td>Withdraw</td>
<td>f45ff8334b5d1c7ab248155d504a57160d6a1a53b1b4e845165501b4cf064a0b</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>89</td>
<td>Primary Sale</td>
<td>117bcb5beb5d9ddd59398f0592bce2f8286d249265efeecc450a3741cd99b18e</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>89</td>
<td>Primary Buy</td>
<td>cbd0dc3a6663bf4694830681ca212e87bcd245389eb9c1f9dad4e759862b3601</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>89</td>
<td>Secondary Sale</td>
<td>1133f8af7d906e063a8eb44ebcd7e8b0b0057685edb6556cefc83765c2f7974f</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>89</td>
<td>Withdraw</td>
<td>88ba7285c5120d326217b9abb953de3c41800c02222aaf865f24ebb52a9240ec</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>90</td>
<td>Primary Sale</td>
<td>71986f85df4812a8e7f80c54660166b3b7b472a46575f0312e29ace79d8a614c</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>90</td>
<td>Primary Buy</td>
<td>eda483af257fd013755e301a1678db87befdb130bc5502d73dd16e2edb20dae9</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>90</td>
<td>Secondary Sale</td>
<td>3046679ccdf8091bae6f03249e1de0b6462e0e590c3491a6036cafbc364ef232</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>90</td>
<td>Withdraw</td>
<td>e6f43d97764c4b0e1f6d9597c9341d189f4d084f180e35471a8534c1b5f5419b</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>91</td>
<td>Primary Sale</td>
<td>b7be0e4d29a14ebb4c8fb27f54e49d2244fa1b0e37405465ad81cccafe0973fc</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>91</td>
<td>Primary Buy</td>
<td>3d0b6bd80314663091b88327a25ba81e0e491a18baafa6f2f3201759c3ccd1ad</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>91</td>
<td>Secondary Sale</td>
<td>0563a54d80fa000364985825b81ffb285cf05c0ef876e43ba39dc9b1034419e3</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>91</td>
<td>Withdraw</td>
<td>22e026c10964fc787c94ee7510d6204bb6df5ea417005a97fc02d1550984a2d0</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>92</td>
<td>Primary Sale</td>
<td>162e7e89851fbbef6ab800f8a115d41ffcfeaec649b81b0c7543a3a8752d894f</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>92</td>
<td>Primary Buy</td>
<td>6ac1c71e300e655d33ca57a64dd1f6207e38127c507f058b57965e368b31971d</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>92</td>
<td>Secondary Sale</td>
<td>aa31ad487b3e7ba8168192b4c43c77df9fe842819922c10e465917cb3bfba906</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>92</td>
<td>Withdraw</td>
<td>c67be4d778521ab1e87db62e5d8f662f45f7758ff3bb99692c130c4a97592eac</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>93</td>
<td>Primary Sale</td>
<td>c512b5dd02df057262ae5a2749b81a429a753560a78bcb7ad3722474cc9d9bf9</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>93</td>
<td>Primary Buy</td>
<td>323994d99f9ef73a87c24afb344323e67775ec528d15d7ceeaa2c7a78ff35a32</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>93</td>
<td>Secondary Sale</td>
<td>f732662b8fccdd4dc74c07fe765356097e74a52538193fcbff47ca5fe7439caf</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>93</td>
<td>Withdraw</td>
<td>228fc0d979bdaea87c2897e441075ceb9d7c8f53684405fdf3d89dee56e3c38f</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>94</td>
<td>Primary Sale</td>
<td>310012aa1761b02cd2d524cbd4587c88e08d6d8f27226336ad37c8a9c144e073</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>94</td>
<td>Primary Buy</td>
<td>1d13505b44bafa5f8357d1aff42c330ea00422da013739da3dba281686622b93</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>94</td>
<td>Secondary Sale</td>
<td>7ea725c2171cd9a75fa6358f45b8ef6e7ff3fd95dea8c28d8ee5ad51d4119836</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>94</td>
<td>Withdraw</td>
<td>36fa23c49cc4fb2e287dc932bba6c381cc37ac68d9a4360c9139d86caf964b3a</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>95</td>
<td>Primary Sale</td>
<td>7eb4f880db034eba4a9f4e32d1f4149af970828ba2dc4259ea61b3646784de27</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>95</td>
<td>Primary Buy</td>
<td>8ee790b01bf8602947c8568c658fafcee674d8bd735a3f39883d1158d9860e0d</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>95</td>
<td>Secondary Sale</td>
<td>855434079aaad5c493dd31cae8db33aa7b15a8be0615d49f758fd56de1690c84</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>95</td>
<td>Withdraw</td>
<td>d1681f54cdf109ba80ac314ae901fa44ceea538e6a36b5d2f1227fd14e6c9459</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>96</td>
<td>Primary Sale</td>
<td>343d07e0db0fa08e951d712e27943c945f2a8978827781e9978f103ad0b50fa0</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>96</td>
<td>Primary Buy</td>
<td>7eb884d25f0610c69f1167c1d6234b6660aa0961319af3a9c963037cf4b3c82a</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>96</td>
<td>Secondary Sale</td>
<td>eff1bc1d8fbde21a01c76ff67c3de18c66656595356bc67a6df3e4e3bc01f62d</td>
<td>181077</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>96</td>
<td>Withdraw</td>
<td>e4604d0aed1a36a7cd6dc20bb233c9dcaa72a7a989dd57505cf58b011ca822d4</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>97</td>
<td>Primary Sale</td>
<td>f3d0e7d894bdd5a9fb4534710c70a0189dccb7c606910cf18090fde174590b05</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>97</td>
<td>Primary Buy</td>
<td>3eb857d7f1c57cff63e98c9ff19d9a97fa36b97d4856bc05924f20a4d2cd3373</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>97</td>
<td>Secondary Sale</td>
<td>c8022b443a606a859faa932ca2d85279887e808243cb7c9bacee29b78c6e6fbf</td>
<td>179141</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>97</td>
<td>Withdraw</td>
<td>97c0eaa9565d8680d4b1a44db23e46907e82371d1f8b9b88e8dce16ad22c372e</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>98</td>
<td>Primary Sale</td>
<td>1e232b6f715da0ab335699468372c747eb01f0cfefc4a1e5c91f47906ae3812e</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>98</td>
<td>Primary Buy</td>
<td>fbe74487760cc5f43a2b586d3c9f2303bdada5ea76b4120846dcf1894aec8d0c</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>98</td>
<td>Secondary Sale</td>
<td>4520ca27897c16fcc37d78c6119a17a03ff54e9f1351289f7ba879864b5c33a8</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>98</td>
<td>Withdraw</td>
<td>9d8f0c688f5109446a2ec53508a8f3596101a7324349b6ae7c2b68a4f10df45f</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>99</td>
<td>Primary Sale</td>
<td>efdd71137b9f1f0740b40a4a2c3873fd6502ba44fcb1fb4887f3042736ac9941</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>99</td>
<td>Primary Buy</td>
<td>b89da0f66461b937c442f8d8bd3379e80dfb9cc274e9b6d02884bb7fcf02c711</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>99</td>
<td>Secondary Sale</td>
<td>a97a9ffb9e5ff880f7eff197b8031c12c71d582b829e6d67dcd10e1d69e9732b</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>99</td>
<td>Withdraw</td>
<td>30d4db9d90dcffe72363a5deabe7a431e4d06dd0b9a99c2d581b485fd39fdc8f</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>100</td>
<td>Primary Sale</td>
<td>65b9dbb733a0b70899b4d50fa50108dc4d866d8b1330f1bd31d79af76a25ba52</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>100</td>
<td>Primary Buy</td>
<td>fc5693cdc8fcc6dd5b0c656d794ca3a1d1f653969682012db8553482b7f5fc4e</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>100</td>
<td>Secondary Sale</td>
<td>af251ae5d56628493769aa147820caf99e2d2a885ef0730b25b6c1ebb793b64c</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>100</td>
<td>Withdraw</td>
<td>d78f19aaabf8b9d35f9dbb07ea067aa8db83d3b40a1614350e197deb8430ab7c</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>101</td>
<td>Primary Sale</td>
<td>107a51e25fb7e7de7d258ffbca652fdbd2064862a1405f531ffe4c5e225e20bb</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>101</td>
<td>Primary Buy</td>
<td>274591c5b65337e918006e4599f3da04ffdc5d0abb9c00589ef460f170194635</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>101</td>
<td>Secondary Sale</td>
<td>cfb62e7fbe5e9530c8dec9c74491047b5aa17681541d68a4a7c610d3566e3ac2</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>101</td>
<td>Withdraw</td>
<td>74f985d07a70a2013a78420dac1bc9b285b53df3ee26524265339952dc8b91ac</td>
<td>593923</td>
<td>1236668</td>
<td>348547128</td>
</tr>
<tr>
<td>102</td>
<td>Primary Sale</td>
<td>41ee2686268c7c0c731b2f840df01a7d8ee1f4ef3848ca88a73dd9521a455463</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>102</td>
<td>Primary Buy</td>
<td>a79746065c52f21b9c748f99881bc4d978329ec18852ed005015febf05ffcdf0</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>102</td>
<td>Secondary Sale</td>
<td>6038cb7e84b7cd35047a31e06d3e11db37fbcdaa6bb9c7a58e03341e535846e7</td>
<td>181077</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>102</td>
<td>Withdraw</td>
<td>aec972acdb98270e13bd062926a15a9fb000779789a4ba1efeb1b4c752400bca</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>103</td>
<td>Primary Sale</td>
<td>bdfbf3fca8e06b3e167aa7cdbdc5a6f8c0a4e2ba78cad7740050b342729f892f</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>103</td>
<td>Primary Buy</td>
<td>8cb7543fda520ea7c683143acb28c5a621418741143db88f6d06d963113eec3d</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>103</td>
<td>Secondary Sale</td>
<td>1950508a578e74b8fc949142acad366e40f29f4790e41c3a09ef639973596e57</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>103</td>
<td>Withdraw</td>
<td>524627186ed268c4c897b13bd2ee2fd0fc9dd3f0cbed860e8e5f0879cda13709</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>104</td>
<td>Primary Sale</td>
<td>a64c1be6c58750335becc6c493c26c9c6d2384ddd49076a71042b2a5266d0191</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>104</td>
<td>Primary Buy</td>
<td>5bc55ca27ec150168a1c31a75d2e728b01baf4c19d39438cbc2497c4b8796938</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>104</td>
<td>Secondary Sale</td>
<td>ff1cf18b058b0e1ccefd40c3837162bf6888dfbaa30bec077113a14c87744b1c</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>104</td>
<td>Withdraw</td>
<td>fd4b6bdb83af5fe7c845bffc7546d047d257c5f14d68f736ad44c16096b3b892</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>105</td>
<td>Primary Sale</td>
<td>6d5d4bddc03b4408b8b3d3056ec2ed39c09f3db705e2b0fcebdc826a4d777b74</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>105</td>
<td>Primary Buy</td>
<td>5348b32781c52c18b6483c203ced8149921c076673e21b58b764ab1417458a57</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>105</td>
<td>Secondary Sale</td>
<td>2bd322068f4facf5ff324000a4f707b82dfb68356de1567a30f6ccc60c88d6a1</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>105</td>
<td>Withdraw</td>
<td>4f66605257448ad773d415c73b5f69ec79f018227a88c11201d3151ad50d56f2</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>106</td>
<td>Primary Sale</td>
<td>853fb101d15b5f89b8c2d532ca83736f11c0ae461887eb3501c85c23b550a94d</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>106</td>
<td>Primary Buy</td>
<td>957f99f6ae2d9e753a9f8e044bae439c722240914015953f9555f6c937e5505d</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>106</td>
<td>Secondary Sale</td>
<td>cd87aec59d03c40b53b6e16fed442c5d0b8afec01d610547bb947bcdd4a10cbc</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>106</td>
<td>Withdraw</td>
<td>23d9a16f8034bfe4ce172a8ebfed1414854514cccf72a57f51f707332522d9d1</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>107</td>
<td>Primary Sale</td>
<td>10a1bcdf538ca306cf27be23cde4d6cce65c5f3ee8021f49418f06ebc8541ee4</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>107</td>
<td>Primary Buy</td>
<td>1de8fab6b118a001026e90e8837d92b477378353200530c46ebaffc649043db9</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>107</td>
<td>Secondary Sale</td>
<td>82a38243d37e015c91bf96d3eebf338f00f8e9284592d11f883b2dfb3be963b8</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>107</td>
<td>Withdraw</td>
<td>577e1ec621a70d42036c0a67fdd5b93c0e71efe248fdf02149f4881af70f22b2</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>108</td>
<td>Primary Sale</td>
<td>83b2177e5015122347b66ceb4688fdae239c29541048b905404a1ef50cde7a0f</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>108</td>
<td>Primary Buy</td>
<td>d70f550ac60815149e639edf80892f710da45ff34c91a384796983db726e5bce</td>
<td>621824</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>108</td>
<td>Secondary Sale</td>
<td>a3d3d07cca60042c3f2d3cc9d6165a23d2445af0b0987cd04df5e04005a7716b</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>108</td>
<td>Withdraw</td>
<td>6a3c52a89406d085452aa88a8a877cddf70c0b6f4680492ddb92ed136b0535f5</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>109</td>
<td>Primary Sale</td>
<td>5748e5ff7bdc13b0ab6d0717671bd9732742a220cfd00bbd454f2df9a5e301da</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>109</td>
<td>Primary Buy</td>
<td>b28255c31e0084bfaf006ac5b077472ff76ecf08621c1c9daa9a7d34d4753366</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>109</td>
<td>Secondary Sale</td>
<td>f8b515c41129e220708cb80623f03eb0c3a870552fa9c190d3a963ae26e4ba9b</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>109</td>
<td>Withdraw</td>
<td>114ed69dcb5e6986067a7d396dd126be7c88649d03496fc8e8be846242db43bd</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>110</td>
<td>Primary Sale</td>
<td>cbebe266f5aa6c0f843ad9b346356f8431519fa886aa0c94764f6fedacfe21ed</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>110</td>
<td>Primary Buy</td>
<td>ba1b4d7a866f0212db35429660207111786e1b3403c8651a4dccd8bb92964ed2</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>110</td>
<td>Secondary Sale</td>
<td>295b25b85d94e18c13bad6380208746923e5c4090faffc3bac670dfe21325bee</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>110</td>
<td>Withdraw</td>
<td>e08a19ad2cd1a2c47a70b211db7d62ae9d71cc59cf96abebe7479d30eaa58c01</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>111</td>
<td>Primary Sale</td>
<td>0b8b27b7247070039320d334df2b752051b9bab80ae4c543154913083055314a</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>111</td>
<td>Primary Buy</td>
<td>c60b4fcd220bc8c8e35b8f1baebd0995a5e5fbc796fbfdedeb63b0edbbcb727a</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>111</td>
<td>Secondary Sale</td>
<td>247a644cd8f929f5d105c8b9d74e6f4360007e7b3462309a9b9d8a7835fbcd18</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>111</td>
<td>Withdraw</td>
<td>6afa472e840118f967d8306cf51a7a705c89b54fbe5d08972b4fb31ba41a098a</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>112</td>
<td>Primary Sale</td>
<td>f7f8666c072fdb0297ed4fa35088f5de4385f661db8a7e9bf034e5b956d323b4</td>
<td>181165</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>112</td>
<td>Primary Buy</td>
<td>96f9496c569d29435bf1a72f01f9699957c53c689aa50b9ea25a5dff602cb441</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>112</td>
<td>Secondary Sale</td>
<td>a1f70912d7b9c288279b94e5e6cf5e6861a8edd7c4f4d08eed7c309ea3e3313a</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>112</td>
<td>Withdraw</td>
<td>fb9bc07153a88e34b5e1eec9286034814bd3e5b0b134c3b8707e47862b4f0368</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>113</td>
<td>Primary Sale</td>
<td>3fb731aafe9c578ec9e472f5e028c2ac3c955456f9c2cf4a6216b3f7b654ef3c</td>
<td>181121</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>113</td>
<td>Primary Buy</td>
<td>07c494c43f9322851ee90b4df294f144f7f1bf227c5db7b526bfa225f21d39e1</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>113</td>
<td>Secondary Sale</td>
<td>0f29a85804b7caa7be18ec293138a6194778872f6d6c39e70b44697b1286892f</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>113</td>
<td>Withdraw</td>
<td>b88278498af062948c2157974279338a5e971d29a760a0402509b9fe79fee680</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>114</td>
<td>Primary Sale</td>
<td>cf0ead888ef1bfabf24b8c72d0a850107641ee61a48b037142a7c5c4e8e56028</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>114</td>
<td>Primary Buy</td>
<td>c252235985f177641a0b4f34ca9f25b6e6a3a6859e734ccf725ccedba1cf6e62</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>114</td>
<td>Secondary Sale</td>
<td>c68ff9b1c01141014bc0f32fd941391947907555e46e1f945b55f39531665d01</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>114</td>
<td>Withdraw</td>
<td>4470e453f2ed8b3879b0ab0ea1c5aad71402a222e873fb38f64a693f7bb11dea</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>115</td>
<td>Primary Sale</td>
<td>695fbd7d9fc89f3a8037b008911afe7c62eda7e0e4c266bd536e4a3b0dede221</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>115</td>
<td>Primary Buy</td>
<td>f1202b54d24e1083b51232cf598a1499ba37a1c13cefdc08a6b184ad17bb8b36</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>115</td>
<td>Secondary Sale</td>
<td>dd60ee03ee6b50ea062135e917dd9c3535ea2ffa091cb1646d82718047a10530</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>115</td>
<td>Withdraw</td>
<td>29beb78151e9ebb6eb2e1ecda0b4b9897b1169275f894ff599ce05fa60d49354</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>116</td>
<td>Primary Sale</td>
<td>aedf2d28cd127310a8fa2fd26a928bf43783c55d7606db12eb1c35d1a50587b3</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>116</td>
<td>Primary Buy</td>
<td>b98a523b722b6ad4f5f7d72165777ecc74a15759c5849fe7717bdd23cfc84ce0</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>116</td>
<td>Secondary Sale</td>
<td>a39a0ecad17c29b46898c4c03c4d12b4c0c1aedc740c5746e3d5eb50a71479a8</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>116</td>
<td>Withdraw</td>
<td>320505f188463c7e371188e8a1252d93c2891425ea575543bc41272337daa672</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>117</td>
<td>Primary Sale</td>
<td>d2d44cdc666aa37042aadccb45ffdb2131ac9a2df144f2bdd5f8f2b84f606e53</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>117</td>
<td>Primary Buy</td>
<td>41c7ec43bb64053736a2fbf924f4e6f55702aeef9036e6db10a56bb817d5a065</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>117</td>
<td>Secondary Sale</td>
<td>e14b31de241c0f2fae5592580994ea2a510304e6a44fbe68aca8e1c926ae018b</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>117</td>
<td>Withdraw</td>
<td>b896ebf492c3cdbae1149332640c2f09d5e936d99f9b903405fb7d2cdfd58046</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>118</td>
<td>Primary Sale</td>
<td>4838b172f1604cc01552cf7940308044bc737d736e6aac56d876415ff50b2dbb</td>
<td>181165</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>118</td>
<td>Primary Buy</td>
<td>9f8ebd1d1e1360ec878de1b1364962165b786fc4163ca536d26e1c85d5b12b1d</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>118</td>
<td>Secondary Sale</td>
<td>cafe5b1a4bbff6e688e96bd30169de12054aa6f8fe121267ab32e2d6ce6f4692</td>
<td>181121</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>118</td>
<td>Withdraw</td>
<td>99f92b294411dfc02b6a029b6a204223242d7a1c60ceb11d0b9aefd6c369599f</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>119</td>
<td>Primary Sale</td>
<td>dd1cca5b527fb33a669f21c72ed7af243be0292b4ed26a85e3c5df5472c1a13c</td>
<td>181165</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>119</td>
<td>Primary Buy</td>
<td>d255f0df31db98824e50b6b1d9b0993907444f9e7ea3216dd29771ad7ea08d76</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>119</td>
<td>Secondary Sale</td>
<td>1670719bae9e739ca9e4e18f882176b523b2a28214f427cbf473ec79ea56104c</td>
<td>181077</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>119</td>
<td>Withdraw</td>
<td>edf4333e5e8e7b3616744f47bdcc4d1ae32ccb78b9d556d69df7bc11cacf50b5</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>120</td>
<td>Primary Sale</td>
<td>bf04aecf258445ebbe58a95fa19bb45f8311f3808b9381f6f582034f334cfb42</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>120</td>
<td>Primary Buy</td>
<td>ec2ceef054988eac09b155fd1ca90a9683e8741f65490e773ae20a0f96c336a9</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>120</td>
<td>Secondary Sale</td>
<td>1c90ca46befeb4a38fb56e8431b5cd0ea777cca378b5bb4dae2f5bcd783f7112</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>120</td>
<td>Withdraw</td>
<td>bca0e56c00d0554163d648e9a232f26f4ba9b8a98f9eda1667c3c5851c5e390c</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>121</td>
<td>Primary Sale</td>
<td>2ba726b46d7022f37a0fd985ce9a6a4f61303dbf3e13ad11d81162a1b33ea37c</td>
<td>181121</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>121</td>
<td>Primary Buy</td>
<td>34aa2f61bb575fb7209d4fe98f7c09c310f462df4adf5a5cf9e0d2b2c3ec7cae</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>121</td>
<td>Secondary Sale</td>
<td>f40fbe152d8982d23282ea4494ed9b4bd1b10089da31d590341045dd050448ba</td>
<td>181077</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>121</td>
<td>Withdraw</td>
<td>12f6728c198dc29137413520cc4e7b74c385987e4d20819f128378b26e2bfc82</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>122</td>
<td>Primary Sale</td>
<td>d13e00f0c720e71438c3c24833a9c732b3e29fa26b39a9a13acdbc5d141ee277</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>122</td>
<td>Primary Buy</td>
<td>044005a113a7995a15a23eb10228827cd3fc8c891b17f25d81c90ee7cd854c9c</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>122</td>
<td>Secondary Sale</td>
<td>951a1e324e7a643f1b1f6614bd62b4e28c50a17b88ba379d107ddd95c3314e6a</td>
<td>179493</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>122</td>
<td>Withdraw</td>
<td>ba2420ea18444c90059ba42331bc00cecab5b0ff3fbfe8463024d49d17747ef0</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>123</td>
<td>Primary Sale</td>
<td>deaf9714478410e0a01da21d279a2ea79762a0f3fd66dc23d3cdb5a2f6c3e1a9</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>123</td>
<td>Primary Buy</td>
<td>05b919ee256ef00152db15941c90205a7d4d1aba013890ad053bef0dcba0b9dd</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>123</td>
<td>Secondary Sale</td>
<td>062700c6ac1dd7688fe6bd29effe100e055a45ddb8b060634f2647f1a0753dce</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>123</td>
<td>Withdraw</td>
<td>5a7a80f4a1e964603ce9c1748638f52b19d85f3f377e7bcbdbca123fff9e6ef4</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
<tr>
<td>124</td>
<td>Primary Sale</td>
<td>3cf0c0c63ac8f023d8714caf3cf2a76774c98f8c181a33952afac0abd6a62a89</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>124</td>
<td>Primary Buy</td>
<td>5760ae5669008db7d974267f914683f2f9cad7c4235beaa6bffc592246d1912f</td>
<td>621868</td>
<td>1583068</td>
<td>439997362</td>
</tr>
<tr>
<td>124</td>
<td>Secondary Sale</td>
<td>91b8f204897d2c48e5d116ab9a81a7b3f53d74c0bb4a071be30693d954775c11</td>
<td>177557</td>
<td>-</td>
<td>-</td>
</tr>
<tr>
<td>124</td>
<td>Withdraw</td>
<td>d534276048d0cd75696d6f64ffaf02d9bcc4f50ebfe1f284265ffc258b7ae310</td>
<td>596433</td>
<td>1269376</td>
<td>357180045</td>
</tr>
</table>
