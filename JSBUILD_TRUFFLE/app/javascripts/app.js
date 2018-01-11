// Import the page's CSS. Webpack will know what to do with it.
import "../stylesheets/home.css";

// Import libraries we need.
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract'

// Import our contract artifacts and turn them into usable abstractions.
import proofofreadtoken_artifacts from '../../build/contracts/ProofOfReadToken.json'

// ProofOfReadToken is our usable abstraction, which we'll use through the code below.
var ProofOfReadToken = contract(proofofreadtoken_artifacts);

// The following code is simple to show off interacting with your contracts.
// As your needs grow you will likely need to change its form and structure.
// For application bootstrapping, check out window.addEventListener below.
var accounts;
var account;
var whichNet = "0";

window.App = {
  start: function() {
    var self = this;

    // Bootstrap the ProofOfReadToken abstraction for Use.
    ProofOfReadToken.setProvider(web3.currentProvider);

    // Get the initial account balance so it can be displayed.
    web3.eth.getAccounts(function(err, accs) {
      if (accs.length == 0) {
          self.setNetwork("Please Unlock Metamask")
        self.setAddress("error");
        stopAccountInterval();
        //alert("There was an error fetching your accounts.");
        account = accounts[0];
        return;
      }

      accounts = accs;
      account = accounts[0];

      self.setAddress(account);
    // Get the connected network ID so it can be displayed.
    web3.version.getNetwork((err, netId) => {
      if (err != null || netId == undefined) {
        stopAccountInterval();
        self.setNetwork("Error")
      }
      switch (netId) {
        case "1":
          self.setNetwork("Main Ethereum")
          console.log('This is mainnet')
          whichNet = "1";
          break
        case "42":
          self.setNetwork("Kovan")
          console.log('This is the Kovan test network.')
          setStatus("Contract not available on the Kovan network.")
          break
        case "3":
          self.setNetwork("Ropsten")
          console.log('This is the Ropsten test network.')
          setStatus("Contract not available on the Ropsten network.")
          break
        case "4":
          self.setNetwork("Rinkeby")
          console.log('This is the Rinkeby test network.')
          whichNet = "4";
          break
        default:
          self.setNetwork("Error")
          console.log('This is an unknown network with id=' + netId) 
      }
      if (whichNet == "4" || whichNet == "1")
      	self.refreshBalance();
      	self.setSMSVerificationRequired();
    })
    }); 
  },

  setNetwork: function(netId) {
    var networkElement = document.getElementById("network");
    networkElement.innerHTML = netId;
  },
  

  setAddress: function(address) {
    var addressElement = document.getElementById("address");
    addressElement.innerHTML = address;
  },

  setStatus: function(message) {
    var status = document.getElementById("status");
    status.innerHTML = message;
  },

  setSMSVerificationRequired: function() {
    var self = this;
    console.log("net:" + whichNet);

    var proofOfReadToken;
    ProofOfReadToken.deployed().then(function(instance) {
      proofOfReadToken = instance;
      return proofOfReadToken.shieldsUp.call(account, {from: account});
    }).then(function(value) {
      var smsVerificationRequiredElement = document.getElementById("smsVerificationRequired");
      smsVerificationRequiredElement.innerHTML = value.valueOf();
   }).catch(function(e) {
      console.log(e);
      self.setStatus("Error getting sms verification required; see log.");
   });
  },

  refreshBalance: function() {
    var self = this;
    console.log("net:" + whichNet);

    var proofOfReadToken;
    ProofOfReadToken.deployed().then(function(instance) {
      proofOfReadToken = instance;
      console.log("entered Correctly");
      return proofOfReadToken.balanceOf.call(account, {from: account});
    }).then(function(value) {
      console.log("balance:" + value.valueOf());
      var balance_element = document.getElementById("balance");
      balance_element.innerHTML = value.valueOf() + " POR";
   }).catch(function(e) {
      console.log(e);
      self.setStatus("Error getting balance; see log.");
    });
  },

  claimReadership: function() {
    var self = this;

    var articleNum = parseInt(document.getElementById("articleNum").value);
    var articleKey = document.getElementById("articleKey").value;

    this.setStatus("Initiating transaction... (please wait)");

    var proofOfReadToken;
    ProofOfReadToken.deployed().then(function(instance) {
      proofOfReadToken = instance;
      return proofOfReadToken.claimReadership(articleNum, articleKey, {from: account});
    }).then(function() {
      self.setStatus("Transaction complete!");
      self.refreshBalance();
    }).catch(function(e) {
      console.log(e);
      self.setStatus("Error sending coin; see log.");
    });
  }
};

window.addEventListener('load', function() {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    console.warn("Using web3 detected from external source. If you find that your accounts don't appear or you have 0 MetaCoin, ensure you've configured that source properly. If using MetaMask, see the following link. Feel free to delete this warning. :) http://truffleframework.com/tutorials/truffle-and-metamask")
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
    showTokenInformation(true);
  } else {
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    stopAccountInterval();
    showTokenInformation(false);
    var acc = document.getElementsByClassName("accordion");
    for (var i = 0; i < acc.length; i++) {
      acc[i].onclick = function(){
        this.classList.toggle("active");
        var panel = this.nextElementSibling;
    if (panel.style.maxHeight){
      panel.style.maxHeight = null;
    } else {
      panel.style.maxHeight = panel.scrollHeight + "px"; 
    }
}
}
    setNetworkOff();
  }

  App.start();
});

// Unfortunate solution for detecting account changes
// was proposed by Metamask: 
// https://github.com/MetaMask/faq/blob/master/DEVELOPERS.md 
var accountInterval = setInterval(function() {
  if (accounts == undefined || accounts.length == 0) return;
  if (web3 == 'undefined') return;
  if (accounts.length == 0) return;
  if (web3.eth.accounts[0] !== account) {
    App.start(); 
  }
}, 100);

function stopAccountInterval() {
  clearInterval(accountInterval);
}

function showTokenInformation(show) {
  var tokenDisplayDiv = document.getElementById('tokenDisplay');
  var tokenExplanationDiv = document.getElementById('tokenExplanation');
  
    if (show) {
        tokenDisplayDiv.style.display = 'block';
        tokenExplanationDiv.style.display = 'none';
    } else {
        tokenDisplayDiv.style.display = 'none';
        tokenExplanationDiv.style.display = 'block';
    }
}

  function setNetworkOff() {
    var networkElement = document.getElementById("network");
    networkElement.innerHTML = "Not Connected to Ethereum Network";
  }
