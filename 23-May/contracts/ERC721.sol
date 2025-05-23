// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
import {IERC721Receiver} from "./IERC721Receiver.sol";

contract ERC721 {
    string public constant Collection_Name = "HiSolidity";
    string public constant SYMBOL = "HISOLC";
    address public immutable OWNER;

    mapping(address => uint256) private s_balances;
    mapping(uint256 tokenId => address Owner) private s_owners;
    //give approval to someone to use it's nft
    mapping(uint256 tokenId => address approvedAddress)
        private s_tokenApprovals;
    mapping(address => mapping(address => bool)) private s_operatorApprovals;
    uint256 private s_tokenIdCounter;
    mapping(uint => string) private s_TokenUri;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    constructor() {
        OWNER = msg.sender;
        s_tokenIdCounter = 0;
    }

    function balanceOf(address _address) public view returns (uint256) {
        require(_address != address(0), "Zero address not valid");
        return s_balances[_address];
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        address owner = s_owners[_tokenId];
        require(owner != address(0), "Token doesn't exist");
        return owner;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        require(s_owners[tokenId] == from, "Transfer from incorrect owner");
        require(to != address(0), "Transfer to the zero address");

        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Caller is not token owner nor approved"
        );

        transferFrom(from, to, tokenId);

        // Check if 'to' is a contract, then call onERC721Received
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "Receiver not ERC721 compliant"
        );
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Not approved or owner"
        );
        require(s_owners[tokenId] == from, "Wrong from");
        require(to != address(0), "Zero address not allowed");

        _transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public {
        address owner = s_owners[tokenId];
        require(to != owner, "Cannot approve current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "Not authorized"
        );

        s_tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Token doesn't exist");
        return s_tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Can't approve self");
        s_operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view returns (bool) {
        return s_operatorApprovals[owner][operator];
    }

    function mint(address to, string memory _uri) public returns (uint256) {
        require(OWNER == msg.sender, "Not owner");
        require(to != address(0), "Zero address");

        uint256 tokenId = s_tokenIdCounter;
        s_tokenIdCounter++;

        s_owners[tokenId] = to;
        s_balances[to]++;
        s_TokenUri[tokenId] = _uri;

        emit Transfer(address(0), to, tokenId);
        return tokenId;
    }

    function totalSupply() public view returns (uint) {
        return s_tokenIdCounter - 1;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return s_TokenUri[tokenId];
    }

    // === Metadata ===

    // function tokenURI(uint256 tokenId) public pure returns (string memory) {
    //     require(tokenId > 0 && tokenId <= 1, "Invalid token ID");

    //     // This IPFS URL points to the METADATA JSON file (not just the image)
    //     return "ipfs://QmR2h3REHjH1y49K1nr3daVKWDP3mCdqnNREtsq1v7881Y";
    // }

    // === Helpers ===

    function _exists(uint256 tokenId) internal view returns (bool) {
        return s_owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view returns (bool) {
        address owner = s_owners[tokenId];
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        // Clear approval
        delete s_tokenApprovals[tokenId];

        s_owners[tokenId] = to;
        s_balances[from]--;
        s_balances[to]++;

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.code.length > 0) {
            // This means 'to' is a contract
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch {
                return false;
            }
        }
        return true; // if 'to' is EOA (not a contract), no need to check
    }
}
