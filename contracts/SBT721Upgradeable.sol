// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./ISBT721.sol";

abstract contract SBT721Upgradeable is Initializable, ISBT721 {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // tokenId
    CountersUpgradeable.Counter private _tokenId;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to tokenId
    mapping(address => uint256) private _tokenMap;

    // totalSupply
    CountersUpgradeable.Counter private _totalSupply;

    // _baseURI
    string _baseURI;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __SBT721_init(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        __SBT721_init_unchained(name_, symbol_);
    }

    function __SBT721_init_unchained(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        _name = name_;
        _symbol = symbol_;
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        uint256 tokenId = _tokenMap[owner];
        return tokenId == 0 ? 0 : 1;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI;
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply.current();
    }

    function tokenIdOf(address from) external view override returns (uint256) {
        require(from != address(0), "Address is empty");
        uint256 tokenId = _tokenMap[from];
        require(tokenId != 0, "The wallet has not attested and SBT");
        return tokenId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function burn() external override {
        address sender = msg.sender;

        uint256 tokenId = _tokenMap[sender];
        require(tokenId != 0, "The account does not have any SBT");

        _beforeTokenTransfer(sender, address(0), tokenId);

        delete _owners[tokenId];
        delete _tokenMap[sender];
        _totalSupply.decrement();

        emit Burn(sender, tokenId);
        emit Transfer(sender, address(0), tokenId);
    }

    function revoke(address from) external override {
        require(from != address(0), "Address is empty");

        uint256 tokenId = _tokenMap[from];
        require(tokenId != 0, "The account does not have any SBT");

        _beforeTokenTransfer(from, address(0), tokenId);

        delete _owners[tokenId];
        delete _tokenMap[from];
        _totalSupply.decrement();

        emit Revoke(from, tokenId);
        emit Transfer(from, address(0), tokenId);
    }

    function attest(address to) external override returns (uint256) {
        require(to != address(0), "Address is empty");
        require(balanceOf(to) == 0, "SBT already exists");

        _tokenId.increment();
        uint256 tokenId = _tokenId.current();

        _beforeTokenTransfer(address(0), to, tokenId);

        require(
            _checkOnERC721Received(address(0), to, tokenId, ""),
            "ERC721: transfer to non ERC721Receiver implementer"
        );

        _owners[tokenId] = to;
        _tokenMap[to] = tokenId;
        _totalSupply.increment();

        emit Attest(to, tokenId);
        emit Transfer(address(0), to, tokenId);
        return tokenId;
    }

    function _supportsInterface(bytes4 interfaceId)
        internal
        pure
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721ReceiverUpgradeable(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return
                    retval ==
                    IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}
