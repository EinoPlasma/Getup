// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVerifyNonceStorage {
    struct VNS{
        bool is_created;
        bool is_used;
        uint using_time;
        string user_simple_addr;
        address emit_contract;
    }

    function _set(uint verify_nonce,string memory _user_simple_addr,address _emit_contract) external;

    function infoOf(uint verify_nonce) external view returns (VNS memory);

    function list_verify_nonce(uint verify_nonce) external view returns (uint);
    
    function add(uint verify_nonce,string memory _user_simple_addr,address _emit_contract) external returns(bool);

    function number_of_list_verify_nonce() external view returns (uint);

    event VerifyNonceAdded(uint verify_nonce,string _user_simple_addr,address _emit_contract);

}
