// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IERC1155Receiver {
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data)
        external returns (bytes4);

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data)
        external returns (bytes4);
}

contract ERC1155 {
    mapping (uint tokenId => mapping (address user => uint balance)) s_balance;
    mapping (address owner => mapping (address manager => bool approved)) s_operatorApproval;
    mapping (uint => string) public s_TokenUri;
    mapping (uint tokenId => uint total) public s_TotalSupply;

    string public constant Collection_Name = "HiSolidity";
    string public constant SYMBOL = "HISOLC";
    address public immutable OWNER;
    uint256 private s_tokenIdCounter;

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    constructor() {
        OWNER = msg.sender;
        s_tokenIdCounter = 0;
    }

    // ---------------------- View Functions ----------------------

    function balanceOf(address _owner, uint256 _id) external view returns (uint256) {
        require(_owner != address(0), "Invalid address");
        return s_balance[_id][_owner];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory) {
        require(_owners.length == _ids.length, "Length mismatch");
        uint256[] memory balances = new uint256[](_owners.length);
        for (uint i = 0; i < _owners.length; i++) {
            balances[i] = s_balance[_ids[i]][_owners[i]];
        }
        return balances;
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return s_operatorApproval[_owner][_operator];
    }

    function uri(uint256 _id) external view returns (string memory) {
        return s_TokenUri[_id];
    }

    // ---------------------- Approval Function ----------------------

    function setApprovalForAll(address _operator, bool _approved) external {
        s_operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    // ---------------------- Transfer Functions ----------------------

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external {
        require(_from == msg.sender || s_operatorApproval[_from][msg.sender], "Not authorized");
        require(_to != address(0), "Invalid recipient");

        uint256 fromBalance = s_balance[_id][_from];
        require(fromBalance >= _amount, "Insufficient balance");

        s_balance[_id][_from] -= _amount;
        s_balance[_id][_to] += _amount;

        emit TransferSingle(msg.sender, _from, _to, _id, _amount);

        // Check if _to is a contract
        if (_isContract(_to)) {
            require(
                IERC1155Receiver(_to).onERC1155Received(msg.sender, _from, _id, _amount, _data) ==
                    IERC1155Receiver.onERC1155Received.selector,
                "Receiver rejected tokens"
            );
        }
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external {
        require(_from == msg.sender || s_operatorApproval[_from][msg.sender], "Not authorized");
        require(_to != address(0), "Invalid recipient");
        require(_ids.length == _amounts.length, "Length mismatch");

        for (uint i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            uint256 amount = _amounts[i];

            require(s_balance[id][_from] >= amount, "Insufficient balance");
            s_balance[id][_from] -= amount;
            s_balance[id][_to] += amount;
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);

        if (_isContract(_to)) {
            require(
                IERC1155Receiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _amounts, _data) ==
                    IERC1155Receiver.onERC1155BatchReceived.selector,
                "Receiver rejected batch"
            );
        }
    }

    // ---------------------- Minting Function ----------------------

    function mint(address _to, uint256 _amount, string memory _uri) external returns (uint256) {
        require(msg.sender == OWNER, "Only owner can mint");
        require(_to != address(0), "Invalid recipient");

        uint256 newTokenId = s_tokenIdCounter++;
        s_balance[newTokenId][_to] = _amount;
        s_TotalSupply[newTokenId] = _amount;
        s_TokenUri[newTokenId] = _uri;

        emit TransferSingle(msg.sender, address(0), _to, newTokenId, _amount);
        emit URI(_uri, newTokenId);

        return newTokenId;
    }

    // ---------------------- Internal Helper ----------------------

    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}
