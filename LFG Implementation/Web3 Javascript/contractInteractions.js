const ERC20_ADDRESS = "0x441C3c2f4a92f1B90F916811514ebDDbBD3BFf4F";
const CT_ADDRESS = "0xe8387e8222f733142038fb362af3ad12f1170d16";
const ERC20contract = new web3.eth.Contract(ERC20_ABI, ERC20_ADDRESS);
const CTcontract = new web3.eth.Contract(CT_ABI, CT_ADDRESS);
let error, circulation, locked, amount, denomination;

checkNetworkAndWallet();

async function checkNetworkAndWallet() {
  if (window.ethereum) {
    const web3 = new Web3(window.ethereum);
    try {
      const accounts = await web3.eth.getAccounts();
      const networkType = await web3.eth.net.getNetworkType();
      if (networkType != 'main') {
        document.getElementById('network-name').innerHTML = `<p style="text-align:center"><em>Please switch to Main network.</em></p>`;
      } else {
        document.getElementById('network-name').innerHTML = `<p style="text-align:center">Current network: Main.</p>`;
        if (accounts.length > 0) {
          document.getElementById('connect-button').style.display = "none";
        } else {
          document.getElementById('connect-button').style.display = "block";
        }
      }
    } catch (error) {
      console.error("Error getting accounts or network type:", error);
    }
  } else {
    console.log("Ethereum provider not available.");
  }
}

async function updateStats() {
  console.log("Attempting to update statistics");
  try {
    circulation = await CTcontract.methods.valueInCirculation().call({
    }, function(err, res) {
      if (err) {
        console.log(err);
        return
      }
    });
  } catch (errorMessage) {
    error = true;
  }
  if (error) {
    console.log("Circulation was not retrieved");
  } else {
    circulation = Number(circulation).toLocaleString()
    console.log("Circulation: " + circulation);
    document.getElementById("circulation").innerHTML = `<h6>${circulation}</h6>`;
  }
  try {
    locked = await CTcontract.methods.valueLockedByContract().call({
    }, function(err, res) {
      if (err) {
        console.log(err);
        return
      }
    });
  } catch (errorMessage) {
    error = true;
  }
  if (error) {
    console.log("Locked value was not retrieved");
  } else {
    locked = Number(locked).toLocaleString()
    console.log("Locked: " + locked);
    document.getElementById("locked").innerHTML = `<h6>${locked}</h6>`;
  }
}

async function approveButton() {
  console.log("Attempting to approve ERC-20");
  amount = parseInt(document.getElementById('approved-amount').value);
  console.log(amount);
  amount = BigInt(amount * 10**18);
  console.log(amount);
  try {
    circulation = await ERC20contract.methods.approve(CT_ADDRESS, amount).send({
        from: currentAccount
    }, function(err, res) {
      if (err) {
        console.log(err);
        return
      }
    });
  } catch (errorMessage) {
    error = true;
  }
  if (error) {
    console.log("Approval was not successfull");
  } else {
    console.log("Approval sent");
  }
}

async function checkAllowance() {
  console.log("Attempting to check approvals");
  try {
    amount = await ERC20contract.methods.allowance(currentAccount, CT_ADDRESS).call({
    }, function(err, res) {
      if (err) {
        console.log(err);
        return
      }
    });
  } catch (errorMessage) {
    error = true;
  }
  if (error) {
    console.log("Allowance was not retrieved");
  } else {
    amount = Number(amount / 10**18).toLocaleString();
    console.log(`Allowance: ${amount}`);
    document.getElementById('allowance').innerHTML = `<p>Allowance is set to <strong>${amount}</strong> $LFG.</p>`;
  }
}

async function denomAllButton() {
  console.log("Attempting to DENOMINATE ALL");
  amount = parseInt(document.getElementById('denom-all-amount').value);
  console.log(amount);
  try {
    await CTcontract.methods.DENOMINATE_ALL(amount).send({
        from: currentAccount
    }, function(err, res) {
      if (err) {
        console.log(err);
        return
      }
    });
  } catch (errorMessage) {
    error = true;
  }
  if (error) {
    console.log("Denominate All was not successfull");
  } else {
    console.log("Denomination Successful");
  }
}

async function denomIntoButton() {
  console.log("Attempting to DENOMINATE INTO TOKEN");
  amount = parseInt(document.getElementById('denom-into-amount').value);
  denomination = parseInt(document.getElementById('denom-into-token').value);
  console.log(amount);
  console.log(denomination);
  try {
    await CTcontract.methods.DENOMINATE_INTO_TOKEN(amount, denomination).send({
        from: currentAccount
    }, function(err, res) {
      if (err) {
        console.log(err);
        return
      }
    });
  } catch (errorMessage) {
    error = true;
  }
  if (error) {
    console.log("Denominate Into Token was not successfull");
  } else {
    console.log("Denominate Into Token was Successful");
  }
}

async function liquidateAllButton() {
  console.log("Attempting to LIQUIDATE ALL");
  try {
    await CTcontract.methods.LIQUIDATE_ALL().send({
        from: currentAccount
    }, function(err, res) {
      if (err) {
        console.log(err);
        return
      }
    });
  } catch (errorMessage) {
    error = true;
  }
  if (error) {
    console.log("Liquidate All was not successfull");
  } else {
    console.log("Liquidation Successful");
  }
}

async function liquidateFromButton() {
  console.log("Attempting to LIQUIDATE FROM TOKEN");
  amount = parseInt(document.getElementById('liquidate-from-amount').value);
  denomination = parseInt(document.getElementById('liquidate-from-token').value);
  console.log(amount);
  console.log(denomination);
  try {
    await CTcontract.methods.LIQUIDATE_FROM_TOKEN(amount, denomination).send({
        from: currentAccount
    }, function(err, res) {
      if (err) {
        console.log(err);
        return
      }
    });
  } catch (errorMessage) {
    error = true;
  }
  if (error) {
    console.log("Liquidate From Token was not successfull");
  } else {
    console.log("Liquidate From Token was Successful");
  }
}