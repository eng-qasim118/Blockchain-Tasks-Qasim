// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract ERC20{
    string public constant TOKEN_NAME = "Taraxa";        
    string public constant SYMBOL = "TARA";          
    uint8 public constant DECIMAL = 18;            
    uint256 private  s_totalSupply;
    mapping (address => uint256) private  s_balanceOf;

     mapping(address => mapping(address => uint256)) private  s_allowance; 

    error ERC20__AllowanceNotApproved();
    error ERC20__InvalidAddress();
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (uint _totalSupply){
         s_totalSupply = _totalSupply * 10 ** DECIMAL;
        s_balanceOf[msg.sender]=s_totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);    
    }

    function transfer(address _to , uint256 _value) external returns(bool success) {
            uint TokenValue = _value * 10 ** DECIMAL;
            require(_to!=address(0),"Invalid Receiver");
             require(s_balanceOf[msg.sender]>=TokenValue,"Insufficient balance");
            s_balanceOf[msg.sender] -= TokenValue;
        s_balanceOf[_to] += TokenValue;
        emit Transfer(msg.sender, _to, TokenValue);
        return true;
    }

        function approve(address _spender, uint256 _value) public returns (bool success) {
           uint TokenValue = _value * 10 ** DECIMAL;
        s_allowance[msg.sender][_spender] = TokenValue;

        emit Approval(msg.sender, _spender, TokenValue);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
           if(_from==address(0)||_to==address(0)){
            revert ERC20__InvalidAddress();
           }
           uint TokenValue = _value * 10 ** DECIMAL;
        require(s_balanceOf[_from] >= TokenValue, "Insufficient balance of sender");
        if(s_allowance[_from][msg.sender]==0){
            revert ERC20__AllowanceNotApproved();
        }
        require(s_allowance[_from][msg.sender] >= TokenValue, "Allowance exceeded");

        s_balanceOf[_from] -= TokenValue;
        s_balanceOf[_to] += TokenValue;

        s_allowance[_from][msg.sender] -= TokenValue;

        emit Transfer(_from, _to, TokenValue);
        return true;
    }

    function totalSupply() public view returns (uint256){
        return s_totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
        return s_balanceOf[_owner];
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return s_allowance[_owner][_spender];
    }
}

