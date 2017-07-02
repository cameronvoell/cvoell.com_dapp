pragma solidity ^0.4.8;

contract ClaimableToken {
    
    string public standard = "Token 0.1";
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
     /* Number of total claimable tokens*/
    uint256 public claimBank;    
    /* Required wait period between token claims*/
    uint256 public waitPeriodSeconds;
    /* Number of unique addresses that have claimed a token*/
    uint256 public uniqueAddresses;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint256) public claimedAtTimestamp;
    mapping (address => bool) public hasClaimed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Claim(address indexed from, uint256 value);
    

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function ClaimableToken(uint256 initialSupply,
                            string tokenName,
                            uint8 decimalUnits,
                            string tokenSymbol,
                            uint256 _waitPeriodSeconds
                            ) {
        claimBank = initialSupply;              // Track tokens claimed
        totalSupply = initialSupply;            // Total suuply stays constant
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        waitPeriodSeconds = _waitPeriodSeconds;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balanceOf[msg.sender] < _value) return false;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) return false; // Check for overflows
        balanceOf[msg.sender] -= _value;                            // Subtract from the sender
        balanceOf[_to] += _value;                                   // Add the same to the recipient
        /* Notify anyone listening that this transfer took place */
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) throw;                                // Prevent transfer to 0x0 address. Use burn() instead
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;     // Check allowance
        balanceOf[_from] -= _value;                           // Subtract from the sender
        balanceOf[_to] += _value;                             // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
    /* Claim coin */
    function claim() {
        if (hasClaimed[msg.sender] && block.timestamp - claimedAtTimestamp[msg.sender] < waitPeriodSeconds) {
            Claim(msg.sender, claimBank);
            throw;  // Check if the sender has alread claimed within wait period
        }
        if (balanceOf[msg.sender] + 1 < balanceOf[msg.sender]) {
            Claim(msg.sender, claimBank);
            throw; // Check for overflows
        }
        if (claimBank <= 0) {
            Claim(msg.sender, claimBank);
            throw; //check if claimBank is empty
        }
        if (!hasClaimed[msg.sender]) {
            hasClaimed[msg.sender] = true;
            uniqueAddresses++;
        }
        claimedAtTimestamp[msg.sender] = block.timestamp;
        claimBank -= 1;                     // Subtract from the claim bank
        balanceOf[msg.sender] += 1;         // Add the token to the recipient
        Claim(msg.sender, claimBank);
    }
    
    /* Check about how many seconds until you can claim another token */
    function checkWaitRemainingSeconds() constant returns (uint256 secondsRemaning) {
        uint256 timePassed = block.timestamp - claimedAtTimestamp[msg.sender];
        if (timePassed >= waitPeriodSeconds) {
            return 0;
        } else {
            return waitPeriodSeconds - timePassed;
        }
    }
}
