pragma solidity ^0.4.8;

contract ParityProofOfSMSInterface {
    function certified(address _who) constant returns (bool);
}

contract ProofOfReadToken {
    
    ParityProofOfSMSInterface public proofOfSms;
    
    //maps reader addresses to a map of story num => have claimed readership
    mapping (address => mapping(uint256 => bool)) public readingRegister;
    
    //article hash to key hash
    mapping (string => bytes32) articleKeyHashRegister; 
    
    //story num to article hash
    mapping (uint256 => string) public publishedRegister; 
    
    uint256 public numArticlesPublished;
    address public publishingOwner;
    bool public shieldsUp;
    string ipfsGateway;

    
    /* ERC20 fields */
    string public standard = "Token 0.1";
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    /* Initializes contract with initial supply tokens to the creator of the contract */
    function ProofOfReadToken(string tokenName, uint8 decimalUnits, string tokenSymbol) {
        publishingOwner = msg.sender;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        ipfsGateway = "http://ipfs.io/ipfs/";
        proofOfSms = ParityProofOfSMSInterface(0x9ae98746EB8a0aeEe5fF2b6B15875313a986f103);
    }
    
    /* Publish article */
    function publish(string articleHash, bytes32 keyHash) {
        if (msg.sender == publishingOwner) {
            publishedRegister[numArticlesPublished] = articleHash;
            articleKeyHashRegister[articleHash] = keyHash;
            numArticlesPublished++;
        }
    }
    
    /* Claim token */
    function claimReadership(uint articleNum, string key) {
        if (shieldsUp && !proofOfSms.certified(msg.sender)) 
             throw; // Missing sms certification
        if (balanceOf[msg.sender] + 1 < balanceOf[msg.sender])
            throw; // Check for overflows
        if (readingRegister[msg.sender][articleNum])
            throw; //reader already claimed this article
        if (keccak256(key) != articleKeyHashRegister[publishedRegister[articleNum]]) {
            throw; //incorrect key or article does not exist
        }
            
        readingRegister[msg.sender][articleNum] = true;
        balanceOf[msg.sender] += 1;
        totalSupply++;
    }
    
    /* Check if an address has read a given article */
    function hasReadership(address toCheck, uint256 articleNum) public returns (bool) {
        return readingRegister[toCheck][articleNum];
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
        if (_to == 0x0) throw;                                // Prevent transfer to 0x0 address.
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;     // Check allowance
        balanceOf[_from] -= _value;                           // Subtract from the sender
        balanceOf[_to] += _value;                             // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
    function updateIpfsGateway(string gateway) {
        if (msg.sender == publishingOwner)
            ipfsGateway = gateway;
    }
        
    function setSmsCertificationRequired(bool enable) {
        if (msg.sender == publishingOwner)
            shieldsUp = enable;
    }
}
